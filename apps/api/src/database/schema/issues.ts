import { sql } from 'drizzle-orm';
import {
  check,
  index,
  integer,
  pgTable,
  smallint,
  uniqueIndex,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';
import { createdAt, primaryId, updatedAt } from './_shared.js';
import { queues } from './queues.js';
import { statuses } from './statuses.js';
import { users } from './users.js';

/**
 * Задача.
 *
 * `key` (`DEV-42`) — публичный идентификатор: он в адресной строке, в мессенджерах,
 * в названиях веток. Он неизменяем, хранится в верхнем регистре и уникален глобально,
 * поэтому проекта в адресе задачи нет (ADR-0004, ADR-0005).
 *
 * Проект здесь не денормализован: он берётся через очередь. Очередь у задачи не меняется
 * (переноса между очередями в MVP нет, D-14), так что соблазн скопировать `project_id`
 * сюда велик — но это второй источник правды ради одного join'а по индексу.
 */
export const issues = pgTable(
  'issues',
  {
    id: primaryId(),
    queueId: uuid('queue_id')
      .notNull()
      .references(() => queues.id, { onDelete: 'cascade' }),
    /** Номер внутри очереди, начиная с 1. Не переиспользуется, пропуски допустимы. */
    number: integer('number').notNull(),
    /** `<КЛЮЧ_ОЧЕРЕДИ>-<НОМЕР>`, до 10 + 1 + 10 символов. */
    key: varchar('key', { length: 21 }).notNull(),
    /** 1–255 символов, обязательно (US-40). */
    title: varchar('title', { length: 255 }).notNull(),
    /** Markdown, до 100 000 символов (US-43). */
    description: varchar('description', { length: 100000 }),
    statusId: uuid('status_id')
      .notNull()
      .references(() => statuses.id, { onDelete: 'restrict' }),
    /** 0–100 с шагом 10, по умолчанию 50. Пустым не бывает (US-50). */
    priority: smallint('priority').notNull().default(50),
    /** Шкала Фибоначчи 1, 2, 3, 5, 8, 13 либо «не оценено» (US-51). */
    storyPoints: smallint('story_points'),
    /** Автор задачи: назначается вручную, по умолчанию — создатель (glossary, раздел 3). */
    authorId: uuid('author_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    /** Кто фактически создал задачу. Устанавливается системой и не меняется. */
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    /** Ровно один исполнитель или никто. Обнуляется при исключении участника из проекта. */
    assigneeId: uuid('assignee_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    // Ключ уникален на весь трекер: по нему открывается задача из адресной строки.
    uniqueIndex('issues_key_key').on(t.key),
    // Страховка от гонки при выдаче номера: даже при ошибке в коде дубль не запишется.
    uniqueIndex('issues_queue_id_number_key').on(t.queueId, t.number),
    // Фильтр списка задач очереди по статусу (US-32).
    index('issues_queue_id_status_id_idx').on(t.queueId, t.statusId),
    // Сортировка списка очереди по умолчанию: приоритет ↓, затем номер ↓ (D-28).
    // NULLS FIRST — порядок, который PostgreSQL подставляет для `ORDER BY ... DESC`
    // по умолчанию. С NULLS LAST (умолчание drizzle) планировщик кладёт поверх
    // индексного сканирования лишний Sort — проверено через EXPLAIN.
    index('issues_queue_id_priority_number_idx').on(
      t.queueId,
      t.priority.desc().nullsFirst(),
      t.number.desc().nullsFirst(),
    ),
    // Активные задачи пользователя: исполнитель + категория статуса (сайдбар).
    // Категория лежит в statuses, поэтому здесь индекс до join'а: (исполнитель, статус).
    index('issues_assignee_status_idx')
      .on(t.assigneeId, t.statusId)
      .where(sql`${t.assigneeId} is not null`),
    // Полнотекстовый поиск по названию (поиск по активным задачам в сайдбаре).
    index('issues_title_fts_idx').using('gin', sql`to_tsvector('russian', ${t.title})`),
    check('issues_number_check', sql`${t.number} > 0`),
    check('issues_priority_check', sql`${t.priority} between 0 and 100 and ${t.priority} % 10 = 0`),
    check(
      'issues_story_points_check',
      sql`${t.storyPoints} is null or ${t.storyPoints} in (1, 2, 3, 5, 8, 13)`,
    ),
  ],
);

export type Issue = typeof issues.$inferSelect;
export type NewIssue = typeof issues.$inferInsert;
