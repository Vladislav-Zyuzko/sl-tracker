import { sql } from 'drizzle-orm';
import { boolean, index, jsonb, pgTable, uniqueIndex, uuid } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz, updatedAt } from './_shared.js';
import { comments } from './comments.js';
import { issues } from './issues.js';
import { notificationChannelEnum, notificationTypeEnum } from './enums.js';
import { projects } from './projects.js';
import { users } from './users.js';

/**
 * Доставленное in-app уведомление (stories/notifications.md).
 *
 * Событие уведомления создаётся в той же транзакции, что и изменение, которое его
 * породило: иначе «уведомление ушло, а изменение откатилось» — и наоборот.
 * Тяжёлая доставка (рассылка по WebSocket, будущий email) выносится в BullMQ
 * и читает уже записанную строку.
 *
 * `payload` хранит снимок текста на момент события: ключ и название задачи, названия
 * статусов, первые ~100 символов комментария. Без него старое уведомление пришлось бы
 * пересобирать из текущих данных, и текст менялся бы задним числом.
 */
export const notifications = pgTable(
  'notifications',
  {
    id: primaryId(),
    recipientId: uuid('recipient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: notificationTypeEnum('type').notNull(),
    channel: notificationChannelEnum('channel').notNull().default('in_app'),
    /** Кто инициировал событие. Пусто — системное событие. */
    actorId: uuid('actor_id').references(() => users.id, { onDelete: 'set null' }),
    projectId: uuid('project_id').references(() => projects.id, { onDelete: 'cascade' }),
    issueId: uuid('issue_id').references(() => issues.id, { onDelete: 'cascade' }),
    /** Обнуляется при удалении комментария: уведомление остаётся, ссылка исчезает (US-102). */
    commentId: uuid('comment_id').references(() => comments.id, { onDelete: 'set null' }),
    payload: jsonb('payload').notNull().default({}),
    readAt: tstz('read_at'),
    createdAt: createdAt(),
  },
  (t) => [
    // Лента уведомлений пользователя, порциями, сначала новые.
    index('notifications_recipient_created_at_idx').on(
      t.recipientId,
      t.createdAt.desc().nullsFirst(),
    ),
    // Счётчик непрочитанных в шапке — только по этому индексу, без полного скана.
    index('notifications_unread_idx')
      .on(t.recipientId)
      .where(sql`${t.readAt} is null`),
    index('notifications_issue_id_idx').on(t.issueId),
  ],
);

/**
 * Настройка подписки: пользователь × тип уведомления × канал (US-103).
 *
 * Отдельная строка на канал, а не флаг «включено» — чтобы появление email не потребовало
 * от пользователя перенастраивать всё заново (D-18).
 *
 * Отсутствие строки означает «включено»: по умолчанию включены все типы, и заводить
 * шесть строк каждому новому пользователю ради значения по умолчанию не нужно.
 */
export const notificationSettings = pgTable(
  'notification_settings',
  {
    id: primaryId(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: notificationTypeEnum('type').notNull(),
    channel: notificationChannelEnum('channel').notNull().default('in_app'),
    enabled: boolean('enabled').notNull().default(true),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('notification_settings_user_type_channel_key').on(t.userId, t.type, t.channel),
  ],
);

export type Notification = typeof notifications.$inferSelect;
export type NewNotification = typeof notifications.$inferInsert;
export type NotificationSetting = typeof notificationSettings.$inferSelect;
export type NewNotificationSetting = typeof notificationSettings.$inferInsert;
