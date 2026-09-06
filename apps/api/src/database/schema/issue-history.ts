import { index, pgTable, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId } from './_shared.js';
import { issueHistoryKindEnum } from './enums.js';
import { issues } from './issues.js';
import { users } from './users.js';

/**
 * Запись истории изменений задачи (stories/history.md).
 *
 * Пишется **в той же транзакции**, что и само изменение: иначе история расходится
 * с данными ровно тогда, когда она нужнее всего. Задним числом её не восстановить,
 * поэтому таблица заводится с первого дня, ещё до появления экрана истории.
 *
 * История не редактируется и не удаляется никем, включая администратора (US-90).
 *
 * Значения хранятся дважды:
 *  - `oldValue` / `newValue` — читаемый снимок на момент изменения (имя пользователя,
 *    название статуса). Нужен потому, что статус может быть переименован, а история
 *    обязана показывать то, что было;
 *  - `oldRefId` / `newRefId` — идентификаторы, чтобы отрисовать аватар и ссылку
 *    на актуальный профиль (US-92).
 *
 * `actorId = NULL` означает системное изменение (например, обнуление исполнителя
 * при исключении участника из проекта) — оно не приписывается случайному пользователю.
 */
export const issueHistory = pgTable(
  'issue_history',
  {
    id: primaryId(),
    issueId: uuid('issue_id')
      .notNull()
      .references(() => issues.id, { onDelete: 'cascade' }),
    actorId: uuid('actor_id').references(() => users.id, { onDelete: 'set null' }),
    kind: issueHistoryKindEnum('kind').notNull(),
    /**
     * Одно действие пользователя, изменившее несколько полей, показывается одной группой
     * с общим временем и автором (US-90). Группа задаётся вызывающим кодом на запрос.
     */
    groupId: uuid('group_id').notNull(),
    oldValue: varchar('old_value', { length: 512 }),
    newValue: varchar('new_value', { length: 512 }),
    oldRefId: uuid('old_ref_id'),
    newRefId: uuid('new_ref_id'),
    createdAt: createdAt(),
  },
  (t) => [
    // Лента истории задачи, порциями, сначала новые.
    index('issue_history_issue_id_created_at_idx').on(
      t.issueId,
      t.createdAt.desc().nullsFirst(),
      t.id.desc().nullsFirst(),
    ),
  ],
);

export type IssueHistoryEntry = typeof issueHistory.$inferSelect;
export type NewIssueHistoryEntry = typeof issueHistory.$inferInsert;
