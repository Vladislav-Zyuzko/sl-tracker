import { sql } from 'drizzle-orm';
import {
  type AnyPgColumn,
  check,
  index,
  integer,
  pgTable,
  uniqueIndex,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';
import { createdAt, primaryId, updatedAt } from './_shared.js';
import { projects } from './projects.js';
import { users } from './users.js';

/**
 * Очередь — пространство задач одного рода внутри проекта. Владеет ключом,
 * набором статусов и счётчиком номеров задач.
 */
export const queues = pgTable(
  'queues',
  {
    id: primaryId(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => projects.id, { onDelete: 'cascade' }),
    /**
     * `^[A-Z][A-Z0-9]{1,9}$`, глобально уникален на весь трекер, неизменяем (ADR-0004).
     * Ссылается на бронь в `queue_keys`: очередь не может существовать с незабронированным
     * ключом. Порядок создания в транзакции — сначала бронь, потом очередь.
     */
    key: varchar('key', { length: 10 })
      .notNull()
      .references((): AnyPgColumn => queueKeys.key, { onDelete: 'restrict', onUpdate: 'cascade' }),
    /** 1–100 символов (US-30). */
    name: varchar('name', { length: 100 }).notNull(),
    /** До 1000 символов, Markdown (US-30). */
    description: varchar('description', { length: 1000 }),
    /**
     * Счётчик выданных номеров задач. Только растёт и никогда не уменьшается:
     * номер удалённой задачи не переиспользуется (ADR-0004).
     *
     * Номер выдаётся `UPDATE queues SET last_issue_number = last_issue_number + 1 RETURNING`
     * в той же транзакции, что и вставка задачи. Это даёт строчную блокировку и
     * исключает гонку. `SELECT max(number) + 1` запрещён.
     */
    lastIssueNumber: integer('last_issue_number').notNull().default(0),
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('queues_key_key').on(t.key),
    // Очереди проекта сортируются по названию (US-31).
    index('queues_project_id_name_idx').on(t.projectId, t.name),
    check('queues_key_format_check', sql`${t.key} ~ '^[A-Z][A-Z0-9]{1,9}$'`),
    check('queues_last_issue_number_check', sql`${t.lastIssueNumber} >= 0`),
  ],
);

/**
 * Бронь ключа очереди на весь трекер.
 *
 * Ключи удалённых очередей и очередей удалённого проекта не выдаются повторно (D-25):
 * иначе старая ссылка `DEV-42` уведёт человека в чужой проект, страница откроется,
 * и он не поймёт, что смотрит не то (ADR-0004).
 *
 * Поэтому уникальность ключа держится здесь, а не только в `queues`: при удалении
 * очереди строка остаётся, а `queue_id` обнуляется.
 */
export const queueKeys = pgTable(
  'queue_keys',
  {
    key: varchar('key', { length: 10 }).primaryKey(),
    queueId: uuid('queue_id').references((): AnyPgColumn => queues.id, { onDelete: 'set null' }),
    reservedAt: createdAt(),
  },
  (t) => [
    uniqueIndex('queue_keys_queue_id_key').on(t.queueId),
    check('queue_keys_format_check', sql`${t.key} ~ '^[A-Z][A-Z0-9]{1,9}$'`),
  ],
);

export type Queue = typeof queues.$inferSelect;
export type NewQueue = typeof queues.$inferInsert;
export type QueueKey = typeof queueKeys.$inferSelect;
