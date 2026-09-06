import { timestamp, uuid } from 'drizzle-orm/pg-core';

/**
 * Первичный ключ. UUID, а не последовательность: идентификаторы не должны быть
 * угадываемыми и не должны раскрывать порядок и количество записей.
 * Публичные читаемые идентификаторы у нас отдельные — `queue.key`, `issue.key`,
 * `project.slug` (ADR-0004, ADR-0005).
 */
export const primaryId = () => uuid('id').primaryKey().defaultRandom();

/** Момент времени всегда с таймзоной: сервер и клиенты в разных поясах. */
export const tstz = (name: string) => timestamp(name, { withTimezone: true, mode: 'date' });

export const createdAt = () => tstz('created_at').notNull().defaultNow();

export const updatedAt = () =>
  tstz('updated_at')
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date());
