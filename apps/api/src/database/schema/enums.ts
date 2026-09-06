import { pgEnum } from 'drizzle-orm/pg-core';

/**
 * Здесь перечислены только закрытые словари, которые пользователь не редактирует
 * и которые нормативно зафиксированы в `docs/product/`.
 *
 * Статусов задач среди них нет и быть не может: они хранятся данными в таблице
 * `statuses` (ADR-0003). Провайдера идентичности здесь тоже нет: добавление второго
 * провайдера не должно требовать миграции (ADR-0002).
 */

/** Откуда взялась запись списка доступа (ADR-0006, permissions.md, раздел 1.1). */
export const accessEntrySourceEnum = pgEnum('access_entry_source', [
  'config',
  'manual',
  'invitation',
]);

/** Роль участника в конкретном проекте. Глобальных ролей, кроме владельца трекера, нет. */
export const projectRoleEnum = pgEnum('project_role', ['admin', 'member', 'reader']);

/**
 * Категория статуса. Определяет, считается ли задача завершённой.
 * Продукт опирается на категорию, а не на конкретный статус (ADR-0003).
 */
export const statusCategoryEnum = pgEnum('status_category', ['open', 'in_progress', 'done']);

/** Способ предъявления сессии: cookie для веба, bearer для будущей мобилки (ADR-0002). */
export const sessionKindEnum = pgEnum('session_kind', ['cookie', 'bearer']);

/** Что именно зафиксировано записью истории (stories/history.md, US-91). */
export const issueHistoryKindEnum = pgEnum('issue_history_kind', [
  'issue_created',
  'title_changed',
  'description_changed',
  'status_changed',
  'priority_changed',
  'story_points_changed',
  'author_changed',
  'assignee_changed',
  'attachment_added',
  'attachment_removed',
  'link_added',
  'link_removed',
  'comment_deleted',
]);

/** Типы уведомлений. Каждый отключается отдельно (stories/notifications.md, US-103). */
export const notificationTypeEnum = pgEnum('notification_type', [
  'issue_assigned',
  'issue_author_assigned',
  'issue_status_changed',
  'issue_commented',
  'issue_mentioned',
  'project_member_joined',
]);

/**
 * Канал доставки. В MVP канал один — in-app (D-18). Отдельное поле, а не флаг,
 * чтобы появление email не потребовало от пользователя перенастройки (US-103).
 */
export const notificationChannelEnum = pgEnum('notification_channel', ['in_app']);
