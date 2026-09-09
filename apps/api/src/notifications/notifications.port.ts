import type { Executor } from '../database/index.js';
import type { NotificationRow, NotificationType } from './notification-types.js';

/** Созданная строка уведомления: ровно то, что нужно живому обновлению. */
export interface CreatedNotification {
  id: string;
  recipientId: string;
  type: NotificationType;
}

/**
 * Часть репозитория уведомлений, которая нужна созданию событий.
 *
 * Абстрактный класс, а не интерфейс: он же служит токеном внедрения. Отдельным
 * файлом — потому что метаданные конструктора вычисляются при загрузке модуля,
 * и класс-токен обязан быть объявлен раньше того, кто его просит.
 */
export abstract class NotificationsRepositoryPort {
  abstract disabledPairs(tx: Executor, userIds: string[]): Promise<Set<string>>;
  abstract insertMany(tx: Executor, rows: NotificationRow[]): Promise<CreatedNotification[]>;
  abstract subscribersOf(tx: Executor, issueId: string): Promise<string[]>;
  abstract projectAdmins(tx: Executor, projectId: string): Promise<string[]>;
  /**
   * Счётчики непрочитанных сразу для нескольких человек — одним запросом.
   *
   * Без `tx`: читается **после** фиксации транзакции, когда только что созданные
   * уведомления уже видны, а сама транзакция уже закрыта.
   */
  abstract unreadCountsOf(userIds: string[]): Promise<Map<string, number>>;
}
