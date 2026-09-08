import type { StatusCategory } from './status-category.js';

/** Статус по умолчанию до записи в базу: очередь ещё не создана, `queueId` неизвестен. */
export interface DefaultStatus {
  key: string;
  name: string;
  category: StatusCategory;
  position: number;
}

/**
 * Пять статусов, которые получает любая новая очередь (US-60, glossary.md, раздел 5).
 *
 * Это **данные, а не enum** (ADR-0003): набор копируется в `statuses` при создании
 * очереди и дальше живёт своей жизнью у каждой очереди отдельно. Здесь только
 * начальное наполнение, поэтому редактор статусов (релиз 3) ничего тут не сломает —
 * он будет менять строки в таблице, а не этот список.
 *
 * Порядок фиксирован и одинаков во всех местах интерфейса. Первый по порядку —
 * статус новой задачи по умолчанию.
 */
export const DEFAULT_STATUSES: readonly DefaultStatus[] = [
  { key: 'open', name: 'Открыт', category: 'open', position: 1 },
  { key: 'in_progress', name: 'В работе', category: 'in_progress', position: 2 },
  { key: 'review', name: 'Ревью', category: 'in_progress', position: 3 },
  { key: 'testing', name: 'Тестирование', category: 'in_progress', position: 4 },
  { key: 'closed', name: 'Закрыт', category: 'done', position: 5 },
];
