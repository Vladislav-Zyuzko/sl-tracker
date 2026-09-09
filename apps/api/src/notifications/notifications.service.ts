import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
// Конкретные файлы, а не бочка realtime: см. комментарий в notification-events.service.
import { userTopic } from '../realtime/realtime.events.js';
import { RealtimePublisher } from '../realtime/realtime.publisher.js';
import {
  NOTIFICATION_TYPES,
  type NotificationChannel,
  type NotificationType,
} from './notification-types.js';
import {
  type NotificationListRow,
  type NotificationSettingRow,
  NotificationsRepository,
} from './notifications.repository.js';

/** Лента подгружается порциями по 30 (design/screens/notifications.md). */
export const NOTIFICATIONS_DEFAULT_LIMIT = 30;
export const NOTIFICATIONS_MAX_LIMIT = 100;

export interface NotificationsPage {
  items: NotificationListRow[];
  nextCursor: string | null;
  total: number;
  unreadCount: number;
}

/**
 * Центр уведомлений (US-103).
 *
 * Прав здесь ровно одно правило, зато железное: **пользователь видит и меняет только
 * свои уведомления** (permissions.md, раздел 2.6). Идентификатор получателя берётся
 * из сессии и подставляется в каждый запрос — чужого уведомления не существует
 * ни для чтения, ни для пометки прочитанным.
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly repository: NotificationsRepository,
    private readonly realtime: RealtimePublisher,
  ) {}

  async list(
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<NotificationsPage> {
    const limit = clampLimit(options.limit, NOTIFICATIONS_DEFAULT_LIMIT, NOTIFICATIONS_MAX_LIMIT);

    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const rows = await this.repository.page({
      recipientId: actor.id,
      limit: limit + 1,
      after: after ?? undefined,
    });

    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items,
      nextCursor: hasMore && last ? encodeCursor([last.createdAt.toISOString(), last.id]) : null,
      total: await this.repository.count(actor.id),
      unreadCount: await this.repository.unreadCount(actor.id),
    };
  }

  unreadCount(actor: AuthenticatedUser): Promise<number> {
    return this.repository.unreadCount(actor.id);
  }

  /**
   * Пометка прочитанным. Чужое уведомление — 404, а не 403: сообщать, что оно
   * существует, незачем (permissions.md, раздел 5).
   */
  async markRead(actor: AuthenticatedUser, id: string): Promise<Date> {
    const readAt = await this.repository.markRead(actor.id, id);
    if (!readAt) {
      throw new NotFoundException({
        code: 'notification_not_found',
        message: 'Уведомление не найдено',
      });
    }
    await this.announceCount(actor.id);
    return readAt;
  }

  async markAllRead(actor: AuthenticatedUser): Promise<number> {
    const updated = await this.repository.markAllRead(actor.id);
    if (updated > 0) {
      await this.announceCount(actor.id);
    }
    return updated;
  }

  /**
   * Счётчик изменился — сказать об этом остальным вкладкам и устройствам того же
   * человека: прочитанное на телефоне не должно продолжать светиться в браузере.
   *
   * Транзакции здесь нет — запись уже зафиксирована, откладывать нечего.
   */
  private async announceCount(userId: string): Promise<void> {
    await this.realtime.publish([
      {
        topic: userTopic(userId),
        event: 'notification.read',
        projectId: null,
        actorId: userId,
        data: { unreadCount: await this.repository.unreadCount(userId) },
      },
    ]);
  }

  /**
   * Настройки подписки. Отдаются **все типы**, а не только сохранённые: отсутствие
   * строки означает «включено», и переключателю в профиле незачем это знать (US-103).
   */
  async settings(actor: AuthenticatedUser): Promise<NotificationSettingRow[]> {
    const saved = new Map(
      (await this.repository.settingsOf(actor.id)).map((row) => [
        `${row.type}:${row.channel}`,
        row,
      ]),
    );

    return NOTIFICATION_TYPES.map(
      (type) => saved.get(`${type}:in_app`) ?? { type, channel: 'in_app', enabled: true },
    );
  }

  async saveSettings(
    actor: AuthenticatedUser,
    items: { type: NotificationType; channel?: NotificationChannel; enabled: boolean }[],
  ): Promise<NotificationSettingRow[]> {
    await this.repository.saveSettings(
      actor.id,
      items.map((item) => ({
        type: item.type,
        channel: item.channel ?? 'in_app',
        enabled: item.enabled,
      })),
    );

    return this.settings(actor);
  }
}

function parseCursor(raw: string): { createdAt: Date; id: string } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const createdAt = new Date(parts[0]!);
  return Number.isNaN(createdAt.getTime()) ? null : { createdAt, id: parts[1]! };
}
