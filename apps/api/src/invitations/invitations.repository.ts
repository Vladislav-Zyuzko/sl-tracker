import { randomBytes } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, isNull, sql } from 'drizzle-orm';
import { DB, type Database, type Transaction } from '../database/index.js';
import {
  accessEntries,
  invitations,
  projectMembers,
  projects,
  users,
} from '../database/schema/index.js';
import type { ProjectRole } from '../projects/index.js';
import { isUsable } from './invitation-state.js';

/** Роль по приглашению: администратора через ссылку выдать нельзя (D-05). */
export type InvitableRole = Exclude<ProjectRole, 'admin'>;

export interface InvitationRow {
  id: string;
  projectId: string;
  token: string;
  role: InvitableRole;
  expiresAt: Date;
  revokedAt: Date | null;
  createdAt: Date;
  createdByUserId: string;
  createdByDisplayName: string | null;
  /** Сколько человек вступило по этой ссылке (US-22). */
  acceptedCount: number;
}

/** Приглашение вместе с проектом — для экрана подтверждения (US-21). */
export interface InvitationWithProject {
  invitation: InvitationRow;
  project: { id: string; slug: string; name: string; coverObjectKey: string | null };
  /** Роль текущего пользователя в проекте, если он уже участник. */
  currentRole: ProjectRole | null;
}

export type AcceptOutcome =
  | { outcome: 'not_found' }
  | { outcome: 'unusable' }
  | { outcome: 'already_member'; slug: string; role: ProjectRole }
  | { outcome: 'joined'; slug: string; role: InvitableRole; projectId: string };

const acceptedCountSql = sql<number>`(
  select count(*)::int from project_members pm where pm.invitation_id = invitations.id
)`;

const SELECTION = {
  id: invitations.id,
  projectId: invitations.projectId,
  token: invitations.token,
  role: sql<InvitableRole>`${invitations.role}`,
  expiresAt: invitations.expiresAt,
  revokedAt: invitations.revokedAt,
  createdAt: invitations.createdAt,
  createdByUserId: invitations.createdByUserId,
  createdByDisplayName: users.displayName,
  acceptedCount: acceptedCountSql,
};

/**
 * SQL приглашений. Токен генерируется здесь же: он должен быть непредсказуемым
 * (US-20), и место его рождения не должно расползаться по коду.
 */
@Injectable()
export class InvitationsRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  async create(input: {
    projectId: string;
    role: InvitableRole;
    expiresAt: Date;
    createdByUserId: string;
  }): Promise<InvitationRow> {
    // 32 случайных байта: подобрать такую ссылку перебором нельзя, а по адресу
    // проекта или его названию её не вывести (US-20).
    const token = randomBytes(32).toString('base64url');

    const [created] = await this.db
      .insert(invitations)
      .values({
        projectId: input.projectId,
        token,
        role: input.role,
        expiresAt: input.expiresAt,
        createdByUserId: input.createdByUserId,
      })
      .returning({ id: invitations.id });

    const row = await this.findById(input.projectId, created!.id);
    return row!;
  }

  /** Список приглашений проекта: и действующие, и истёкшие, и отозванные (US-22). */
  async list(options: {
    projectId: string;
    limit: number;
    after?: { createdAt: Date; id: string };
  }): Promise<InvitationRow[]> {
    const conditions = [eq(invitations.projectId, options.projectId)];
    if (options.after) {
      conditions.push(
        sql`(invitations.created_at, invitations.id) < (${options.after.createdAt}, ${options.after.id}::uuid)`,
      );
    }

    return this.db
      .select(SELECTION)
      .from(invitations)
      .leftJoin(users, eq(users.id, invitations.createdByUserId))
      .where(and(...conditions))
      .orderBy(desc(invitations.createdAt), desc(invitations.id))
      .limit(options.limit);
  }

  async count(projectId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(invitations)
      .where(eq(invitations.projectId, projectId));
    return row?.value ?? 0;
  }

  async findById(projectId: string, id: string): Promise<InvitationRow | null> {
    const [row] = await this.db
      .select(SELECTION)
      .from(invitations)
      .leftJoin(users, eq(users.id, invitations.createdByUserId))
      .where(and(eq(invitations.id, id), eq(invitations.projectId, projectId)))
      .limit(1);
    return row ?? null;
  }

  /**
   * Приглашение по токену вместе с проектом и текущей ролью пользователя.
   * Одним запросом: экран подтверждения открывается по ссылке из чата, и лишний
   * поход в БД здесь ничем не оправдан.
   */
  async findByToken(token: string, userId: string): Promise<InvitationWithProject | null> {
    const [row] = await this.db
      .select({
        ...SELECTION,
        projectSlug: projects.slug,
        projectName: projects.name,
        projectCoverObjectKey: projects.coverObjectKey,
        currentRole: projectMembers.role,
      })
      .from(invitations)
      .innerJoin(projects, eq(projects.id, invitations.projectId))
      .leftJoin(users, eq(users.id, invitations.createdByUserId))
      .leftJoin(
        projectMembers,
        and(eq(projectMembers.projectId, projects.id), eq(projectMembers.userId, userId)),
      )
      .where(eq(invitations.token, token))
      .limit(1);

    if (!row) {
      return null;
    }

    const { projectSlug, projectName, projectCoverObjectKey, currentRole, ...invitation } = row;
    return {
      invitation,
      project: {
        id: invitation.projectId,
        slug: projectSlug,
        name: projectName,
        coverObjectKey: projectCoverObjectKey,
      },
      currentRole,
    };
  }

  /** Отзыв приглашения (US-22): строка остаётся в списке, но перестаёт действовать. */
  async revoke(projectId: string, id: string, actorId: string): Promise<InvitationRow | null> {
    // Повторный отзыв уже отозванного ничего не меняет и ошибкой не является:
    // условие `revoked_at is null` оставляет первоначальные отметку и автора.
    await this.db
      .update(invitations)
      .set({ revokedAt: new Date(), revokedByUserId: actorId })
      .where(
        and(
          eq(invitations.id, id),
          eq(invitations.projectId, projectId),
          isNull(invitations.revokedAt),
        ),
      );

    return this.findById(projectId, id);
  }

  /**
   * Приём приглашения (US-21) — целиком в одной транзакции.
   *
   * Состояние приглашения перечитывается здесь под `for update`, а не берётся
   * из предыдущего запроса: между открытием экрана и нажатием «Присоединиться»
   * приглашение могли отозвать.
   *
   * Вместе с членством появляется запись списка доступа с источником `invitation`
   * (ADR-0006, п. 3): приглашение работает в обход списка и обязано его пополнить,
   * иначе при следующем входе человека не пустят.
   */
  async accept(input: { token: string; userId: string; email: string }): Promise<AcceptOutcome> {
    return this.db.transaction(async (tx) => {
      const [row] = await tx
        .select({
          id: invitations.id,
          projectId: invitations.projectId,
          role: sql<InvitableRole>`${invitations.role}`,
          expiresAt: invitations.expiresAt,
          revokedAt: invitations.revokedAt,
          slug: projects.slug,
        })
        .from(invitations)
        .innerJoin(projects, eq(projects.id, invitations.projectId))
        .where(eq(invitations.token, input.token))
        .for('update', { of: invitations })
        .limit(1);

      if (!row) {
        return { outcome: 'not_found' as const };
      }

      const [existing] = await tx
        .select({ role: projectMembers.role })
        .from(projectMembers)
        .where(
          and(eq(projectMembers.projectId, row.projectId), eq(projectMembers.userId, input.userId)),
        )
        .limit(1);

      if (existing) {
        // Уже участник: роль не меняется и не понижается (US-21). Запись доступа
        // всё равно проверяем — человек мог попасть в трекер в обход списка.
        await this.grantAccess(tx, input.email);
        return { outcome: 'already_member' as const, slug: row.slug, role: existing.role };
      }

      if (!isUsable(row)) {
        return { outcome: 'unusable' as const };
      }

      await tx.insert(projectMembers).values({
        projectId: row.projectId,
        userId: input.userId,
        role: row.role,
        invitationId: row.id,
      });

      await this.grantAccess(tx, input.email);

      return {
        outcome: 'joined' as const,
        slug: row.slug,
        role: row.role,
        projectId: row.projectId,
      };
    });
  }

  /** Запись списка доступа с источником `invitation`; повторный приём ничего не ломает. */
  private async grantAccess(tx: Transaction, email: string): Promise<void> {
    await tx.insert(accessEntries).values({ email, source: 'invitation' }).onConflictDoNothing();
  }
}
