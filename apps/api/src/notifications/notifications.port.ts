import type { Executor } from '../database/index.js';
import type { NotificationRow } from './notification-types.js';

/**
 * Часть репозитория уведомлений, которая нужна созданию событий.
 *
 * Абстрактный класс, а не интерфейс: он же служит токеном внедрения. Отдельным
 * файлом — потому что метаданные конструктора вычисляются при загрузке модуля,
 * и класс-токен обязан быть объявлен раньше того, кто его просит.
 */
export abstract class NotificationsRepositoryPort {
  abstract disabledPairs(tx: Executor, userIds: string[]): Promise<Set<string>>;
  abstract insertMany(tx: Executor, rows: NotificationRow[]): Promise<void>;
  abstract subscribersOf(tx: Executor, issueId: string): Promise<string[]>;
  abstract projectAdmins(tx: Executor, projectId: string): Promise<string[]>;
}
