import { sql } from 'drizzle-orm';
import { index, pgTable, uniqueIndex, uuid } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, updatedAt } from './_shared.js';
import { projectRoleEnum } from './enums.js';
import { invitations } from './invitations.js';
import { projects } from './projects.js';
import { users } from './users.js';

/**
 * Участник проекта. Ровно одна запись на пару (проект, пользователь) и ровно одна роль:
 * роли не суммируются (permissions.md, раздел 1, правило 2).
 */
export const projectMembers = pgTable(
  'project_members',
  {
    id: primaryId(),
    projectId: uuid('project_id')
      .notNull()
      .references(() => projects.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    role: projectRoleEnum('role').notNull(),
    /** По какому приглашению человек вступил. Создатель проекта пришёл не по ссылке — пусто. */
    invitationId: uuid('invitation_id').references(() => invitations.id, { onDelete: 'set null' }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('project_members_project_user_key').on(t.projectId, t.userId),
    // «Мои проекты» — самый частый запрос приложения.
    index('project_members_user_id_idx').on(t.userId),
    // Инвариант «в проекте всегда есть администратор» проверяется подсчётом по этому индексу.
    index('project_members_admins_idx')
      .on(t.projectId)
      .where(sql`${t.role} = 'admin'`),
    // Сколько человек вступило по конкретному приглашению (US-22).
    index('project_members_invitation_id_idx').on(t.invitationId),
  ],
);

export type ProjectMember = typeof projectMembers.$inferSelect;
export type NewProjectMember = typeof projectMembers.$inferInsert;
