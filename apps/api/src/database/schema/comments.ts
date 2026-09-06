import { index, pgTable, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz, updatedAt } from './_shared.js';
import { issues } from './issues.js';
import { users } from './users.js';

/**
 * Комментарий к задаче. Плоская лента, сначала старые (US-70).
 *
 * Удаление — физическое: продукт требует, чтобы текст удалённого комментария
 * не сохранялся нигде, включая историю (US-91). Факт удаления фиксируется записью
 * истории задачи, а уведомления, которые на него ссылались, теряют ссылку
 * (`notifications.comment_id` → NULL), но остаются в центре уведомлений (US-102).
 */
export const comments = pgTable(
  'comments',
  {
    id: primaryId(),
    issueId: uuid('issue_id')
      .notNull()
      .references(() => issues.id, { onDelete: 'cascade' }),
    authorId: uuid('author_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    /** До 10 000 символов, Markdown (US-71). */
    body: varchar('body', { length: 10000 }).notNull(),
    /** Проставляется при правке автором; по нему рисуется пометка «изменён» (US-72). */
    editedAt: tstz('edited_at'),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [index('comments_issue_id_created_at_idx').on(t.issueId, t.createdAt)],
);

export type Comment = typeof comments.$inferSelect;
export type NewComment = typeof comments.$inferInsert;
