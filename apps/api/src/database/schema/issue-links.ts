import { sql } from 'drizzle-orm';
import { check, index, pgTable, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId } from './_shared.js';
import { issues } from './issues.js';
import { users } from './users.js';

/**
 * Внешняя ссылка, приложенная к задаче: макет, документ, страница (US-47).
 *
 * Это **не** связь между задачами трекера — связей в MVP нет (glossary, раздел 3).
 */
export const issueLinks = pgTable(
  'issue_links',
  {
    id: primaryId(),
    issueId: uuid('issue_id')
      .notNull()
      .references(() => issues.id, { onDelete: 'cascade' }),
    /** Только схемы http и https (US-47). */
    url: varchar('url', { length: 2048 }).notNull(),
    /** Подпись, до 100 символов. Пусто — показывается сам адрес. */
    title: varchar('title', { length: 100 }),
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
  },
  (t) => [
    index('issue_links_issue_id_created_at_idx').on(t.issueId, t.createdAt),
    check('issue_links_scheme_check', sql`${t.url} ~ '^https?://'`),
  ],
);

export type IssueLink = typeof issueLinks.$inferSelect;
export type NewIssueLink = typeof issueLinks.$inferInsert;
