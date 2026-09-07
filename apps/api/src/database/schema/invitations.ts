import { check, index, pgTable, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { createdAt, primaryId, tstz } from './_shared.js';
import { projectRoleEnum } from './enums.js';
import { projects } from './projects.js';
import { users } from './users.js';

/**
 * Ссылка-приглашение в проект — единственный способ добавить человека в проект (D-03).
 *
 * Состояние («действует / истекло / отозвано») не хранится: оно вычисляется из
 * `expiresAt` и `revokedAt`. Хранить его отдельно значило бы завести фоновую задачу,
 * которая переводит приглашения в «истекло», и жить с расхождением между полем и часами.
 *
 * Токен хранится в открытом виде намеренно: US-22 требует уметь показать администратору
 * полный текст действующей ссылки повторно. Это осознанный компромисс — токен даёт
 * ровно одно право (вступить в конкретный проект в заранее заданной роли), живёт
 * не дольше 30 дней и отзывается одним действием.
 */
export const invitations = pgTable(
  'invitations',
  {
    id: primaryId(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => projects.id, { onDelete: 'cascade' }),
    /** Непредсказуемый токен из криптографического генератора (US-20). */
    token: varchar('token', { length: 64 }).notNull(),
    /**
     * Роль, которую получит вступивший. Роль администратора через приглашение
     * выдать нельзя (D-05) — ограничение проверяется приложением и здесь, в CHECK.
     */
    role: projectRoleEnum('role').notNull(),
    /** 1, 7 или 30 дней от момента создания. Бессрочных приглашений нет (US-20). */
    expiresAt: tstz('expires_at').notNull(),
    revokedAt: tstz('revoked_at'),
    revokedByUserId: uuid('revoked_by_user_id').references(() => users.id, {
      onDelete: 'set null',
    }),
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
  },
  (t) => [
    uniqueIndex('invitations_token_key').on(t.token),
    index('invitations_project_id_created_at_idx').on(t.projectId, t.createdAt.desc().nullsFirst()),
    // Через приглашение нельзя выдать роль администратора (D-05).
    check('invitations_role_check', sql`${t.role} in ('member', 'reader')`),
  ],
);

export type Invitation = typeof invitations.$inferSelect;
export type NewInvitation = typeof invitations.$inferInsert;
