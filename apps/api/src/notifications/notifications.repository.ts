import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, inArray, isNull, sql } from 'drizzle-orm';
import { DB, type Database, type Executor } from '../database/index.js';
import {
  comments,
  issues,
  mentions,
  notificationSettings,
  notifications,
  projectMembers,
  projects,
  queues,
  users,
} from '../database/schema/index.js';
import type { UserRef } from '../issues/index.js';
import {
  type NotificationChannel,
  type NotificationRow,
  type NotificationType,
} from './notification-types.js';
import type { CreatedNotification } from './notifications.port.js';

/** Строка ленты уведомлений вместе с инициатором события. */
export interface NotificationListRow {
  id: string;
  type: NotificationType;
  channel: NotificationChannel;
  /** `null` — системное событие: в ленте вместо аватара иконка (design/notifications.md). */
  actor: UserRef | null;
  issueKey: string | null;
  projectSlug: string | null;
  commentId: string | null;
  payload: Record<string, unknown>;
  readAt: Date | null;
  createdAt: Date;
}

export interface NotificationSettingRow {
  type: NotificationType;
  channel: NotificationChannel;
  enabled: boolean;
}

/**
 * SQL уведомлений: и запись событий (в транзакции того, что их породило), и чтение
 * центра уведомлений.
 *
 * Прав здесь нет: центр уведомлений всегда работает с `recipient_id = текущий
 * пользователь`, и условие подставляет сервис. Чужих уведомлений не существует
 * в принципе (permissions.md, раздел 2.6).
 */
@Injectable()
export class NotificationsRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Подписчики задачи (D-17): создатель, текущий автор, текущий исполнитель, все, кто
   * оставил хотя бы один комментарий, и все, кого в задаче упомянули.
   *
   * Отдельного «списка наблюдателей» в MVP нет, и заводить его незачем: подписка
   * выводится из уже существующих связей одним запросом.
   *
   * Результат **пересечён с участниками проекта**: исключённый из проекта перестаёт
   * получать уведомления по его задачам (US-103), а упомянутый, который к моменту
   * события уже не участник, уведомления не получает (US-104).
   */
  async subscribersOf(tx: Executor, issueId: string): Promise<string[]> {
    const rows = await tx
      .select({ userId: projectMembers.userId })
      .from(projectMembers)
      // Задача и её очередь подставляются условием соединения: так проект задачи
      // и членство в нём проверяются тем же запросом, что и сама подписка.
      .innerJoin(issues, eq(issues.id, issueId))
      .innerJoin(
        queues,
        and(eq(queues.id, issues.queueId), eq(queues.projectId, projectMembers.projectId)),
      )
      .where(
        sql`(
          ${projectMembers.userId} in (${issues.authorId}, ${issues.createdByUserId}, ${issues.assigneeId})
          or exists (
            select 1 from ${comments}
             where ${comments.issueId} = ${issues.id}
               and ${comments.authorId} = ${projectMembers.userId}
          )
          or exists (
            select 1 from ${mentions}
             where ${mentions.issueId} = ${issues.id}
               and ${mentions.mentionedUserId} = ${projectMembers.userId}
          )
        )`,
      );

    return rows.map((row) => row.userId);
  }

  /** Администраторы проекта — получатели уведомления о новом участнике (US-23). */
  async projectAdmins(tx: Executor, projectId: string): Promise<string[]> {
    const rows = await tx
      .select({ userId: projectMembers.userId })
      .from(projectMembers)
      .where(and(eq(projectMembers.projectId, projectId), eq(projectMembers.role, 'admin')));
    return rows.map((row) => row.userId);
  }

  /**
   * Кому какие типы отключены. Одним запросом на всё событие: отсутствие строки
   * означает «включено», поэтому спрашиваем только про выключенные (US-103).
   */
  async disabledPairs(
    tx: Executor,
    userIds: string[],
    channel: NotificationChannel = 'in_app',
  ): Promise<Set<string>> {
    if (userIds.length === 0) {
      return new Set();
    }

    const rows = await tx
      .select({ userId: notificationSettings.userId, type: notificationSettings.type })
      .from(notificationSettings)
      .where(
        and(
          inArray(notificationSettings.userId, userIds),
          eq(notificationSettings.channel, channel),
          eq(notificationSettings.enabled, false),
        ),
      );

    return new Set(rows.map((row) => `${row.userId}:${row.type}`));
  }

  /** Запись событий. Всегда в транзакции того изменения, которое их породило. */
  async insertMany(tx: Executor, rows: NotificationRow[]): Promise<CreatedNotification[]> {
    if (rows.length === 0) {
      return [];
    }
    // Идентификаторы возвращаются не «на всякий случай»: по ним живое обновление
    // называет клиенту конкретное уведомление, а не просто «что-то пришло».
    return tx
      .insert(notifications)
      .values(rows)
      .returning({
        id: notifications.id,
        recipientId: notifications.recipientId,
        type: sql<NotificationType>`${notifications.type}`,
      });
  }

  /**
   * Счётчики непрочитанных сразу для нескольких получателей — одним запросом
   * по тому же частичному индексу, что и одиночный счётчик.
   *
   * Нужен рассылке: одно действие создаёт уведомления нескольким людям, и звать
   * `unreadCount` в цикле означало бы запрос на каждого.
   */
  async unreadCountsOf(userIds: string[]): Promise<Map<string, number>> {
    if (userIds.length === 0) {
      return new Map();
    }

    const rows = await this.db
      .select({
        recipientId: notifications.recipientId,
        value: sql<number>`count(*)::int`,
      })
      .from(notifications)
      .where(and(inArray(notifications.recipientId, userIds), isNull(notifications.readAt)))
      .groupBy(notifications.recipientId);

    const counts = new Map<string, number>(userIds.map((userId) => [userId, 0]));
    for (const row of rows) {
      counts.set(row.recipientId, row.value);
    }
    return counts;
  }

  /**
   * Лента уведомлений, сначала новые (US-103).
   *
   * Инициатор, ключ задачи и короткое имя проекта приезжают join'ами: строке ленты
   * они нужны всегда, а отдельный запрос на каждую — N+1 на 30 строк порции.
   */
  async page(options: {
    recipientId: string;
    limit: number;
    after?: { createdAt: Date; id: string };
  }): Promise<NotificationListRow[]> {
    const conditions = [eq(notifications.recipientId, options.recipientId)];
    if (options.after) {
      conditions.push(
        sql`(${notifications.createdAt}, ${notifications.id}) < (${options.after.createdAt}, ${options.after.id}::uuid)`,
      );
    }

    const rows = await this.db
      .select({
        id: notifications.id,
        type: notifications.type,
        channel: notifications.channel,
        actorId: users.id,
        actorDisplayName: users.displayName,
        actorAvatarUrl: users.avatarUrl,
        issueKey: issues.key,
        projectSlug: projects.slug,
        commentId: notifications.commentId,
        payload: notifications.payload,
        readAt: notifications.readAt,
        createdAt: notifications.createdAt,
      })
      .from(notifications)
      .leftJoin(users, eq(users.id, notifications.actorId))
      .leftJoin(issues, eq(issues.id, notifications.issueId))
      .leftJoin(projects, eq(projects.id, notifications.projectId))
      .where(and(...conditions))
      .orderBy(desc(notifications.createdAt), desc(notifications.id))
      .limit(options.limit);

    return rows.map((row) => ({
      id: row.id,
      type: row.type,
      channel: row.channel,
      actor: row.actorId
        ? {
            id: row.actorId,
            displayName: row.actorDisplayName ?? '',
            avatarUrl: row.actorAvatarUrl,
          }
        : null,
      issueKey: row.issueKey,
      projectSlug: row.projectSlug,
      commentId: row.commentId,
      payload: (row.payload ?? {}) as Record<string, unknown>,
      readAt: row.readAt,
      createdAt: row.createdAt,
    }));
  }

  async count(recipientId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(notifications)
      .where(eq(notifications.recipientId, recipientId));
    return row?.value ?? 0;
  }

  /** Счётчик в шапке. Считается по частичному индексу, без полного скана. */
  async unreadCount(recipientId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(notifications)
      .where(and(eq(notifications.recipientId, recipientId), isNull(notifications.readAt)));
    return row?.value ?? 0;
  }

  /** Пометка прочитанным идемпотентна: повторный вызов не меняет время прочтения. */
  async markRead(recipientId: string, id: string): Promise<Date | undefined> {
    const [row] = await this.db
      .update(notifications)
      .set({ readAt: sql`coalesce(${notifications.readAt}, now())` })
      .where(and(eq(notifications.id, id), eq(notifications.recipientId, recipientId)))
      .returning({ readAt: notifications.readAt });
    return row?.readAt ?? undefined;
  }

  async markAllRead(recipientId: string): Promise<number> {
    const rows = await this.db
      .update(notifications)
      .set({ readAt: new Date() })
      .where(and(eq(notifications.recipientId, recipientId), isNull(notifications.readAt)))
      .returning({ id: notifications.id });
    return rows.length;
  }

  /** Явно сохранённые настройки. Чего здесь нет — то включено (US-103). */
  async settingsOf(userId: string): Promise<NotificationSettingRow[]> {
    return this.db
      .select({
        type: notificationSettings.type,
        channel: notificationSettings.channel,
        enabled: notificationSettings.enabled,
      })
      .from(notificationSettings)
      .where(eq(notificationSettings.userId, userId));
  }

  /** Сохранение настроек: одна строка на «пользователь × тип × канал» (D-18). */
  async saveSettings(
    userId: string,
    items: { type: NotificationType; channel: NotificationChannel; enabled: boolean }[],
  ): Promise<void> {
    if (items.length === 0) {
      return;
    }

    await this.db
      .insert(notificationSettings)
      .values(items.map((item) => ({ userId, ...item })))
      .onConflictDoUpdate({
        target: [
          notificationSettings.userId,
          notificationSettings.type,
          notificationSettings.channel,
        ],
        set: { enabled: sql`excluded.enabled`, updatedAt: new Date() },
      });
  }
}
