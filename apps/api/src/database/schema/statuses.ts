import { index, pgTable, smallint, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, updatedAt } from './_shared.js';
import { statusCategoryEnum } from './enums.js';
import { queues } from './queues.js';

/**
 * Статус задачи. Данные, а не enum в коде (ADR-0003).
 *
 * Статусы принадлежат конкретной очереди: изменение набора у одной очереди не затрагивает
 * другие (US-60). При создании очереди заводятся пять статусов по умолчанию — см.
 * `glossary.md`, раздел 5. Редактора статусов в MVP нет, но модель его допускает.
 *
 * «Активность» задачи определяется по `category`, а не по названию или позиции:
 * появление у команды статуса «Отменено» в категории `done` ничего не сломает.
 */
export const statuses = pgTable(
  'statuses',
  {
    id: primaryId(),
    queueId: uuid('queue_id')
      .notNull()
      .references(() => queues.id, { onDelete: 'cascade' }),
    /** Машинное имя: `open`, `in_progress`, `review`, `testing`, `closed`. */
    key: varchar('key', { length: 32 }).notNull(),
    /** Название для интерфейса. */
    name: varchar('name', { length: 50 }).notNull(),
    category: statusCategoryEnum('category').notNull(),
    /** Порядок отображения. Первый по порядку — статус новой задачи по умолчанию (US-60). */
    position: smallint('position').notNull(),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('statuses_queue_id_key_key').on(t.queueId, t.key),
    uniqueIndex('statuses_queue_id_position_key').on(t.queueId, t.position),
    // Выборка статусов очереди в фиксированном порядке — на каждом экране задачи.
    index('statuses_queue_id_position_idx').on(t.queueId, t.position),
    // Активные задачи пользователя фильтруются по категории (см. issues).
    index('statuses_category_idx').on(t.category),
  ],
);

export type Status = typeof statuses.$inferSelect;
export type NewStatus = typeof statuses.$inferInsert;
