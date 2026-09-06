import { sql } from 'drizzle-orm';
import { index, pgTable, uniqueIndex, uuid } from 'drizzle-orm/pg-core';
import { createdAt, primaryId } from './_shared.js';
import { comments } from './comments.js';
import { issues } from './issues.js';
import { users } from './users.js';

/**
 * Упоминание участника в тексте комментария или описания задачи.
 *
 * Связь создаётся **только** для участника проекта, которому принадлежит задача (US-08):
 * упоминание постороннего сохраняется как обычный текст, строки здесь не появляется
 * и уведомление не создаётся.
 *
 * `commentId = NULL` означает упоминание в описании задачи.
 */
export const mentions = pgTable(
  'mentions',
  {
    id: primaryId(),
    issueId: uuid('issue_id')
      .notNull()
      .references(() => issues.id, { onDelete: 'cascade' }),
    commentId: uuid('comment_id').references(() => comments.id, { onDelete: 'cascade' }),
    mentionedUserId: uuid('mentioned_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
  },
  (t) => [
    // Один человек упомянут в одном комментарии один раз, сколько бы раз ни встретился в тексте.
    uniqueIndex('mentions_comment_user_key')
      .on(t.commentId, t.mentionedUserId)
      .where(sql`${t.commentId} is not null`),
    // То же для описания задачи.
    uniqueIndex('mentions_issue_description_user_key')
      .on(t.issueId, t.mentionedUserId)
      .where(sql`${t.commentId} is null`),
    index('mentions_mentioned_user_id_idx').on(t.mentionedUserId),
    index('mentions_issue_id_idx').on(t.issueId),
  ],
);

export type Mention = typeof mentions.$inferSelect;
export type NewMention = typeof mentions.$inferInsert;
