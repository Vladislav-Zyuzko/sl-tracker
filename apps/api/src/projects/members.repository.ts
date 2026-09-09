import { randomUUID } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { and, eq, sql, type SQL } from 'drizzle-orm';
import { containsPattern } from '../common/index.js';
import { DB, type Database } from '../database/index.js';
import { issueHistory, issues, projectMembers, queues, users } from '../database/schema/index.js';
import type { ProjectRole } from './projects.repository.js';

export interface MemberRow {
  userId: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
  role: ProjectRole;
  joinedAt: Date;
}

/** Курсор списка участников: сначала администраторы, затем по имени (design/project.md). */
export interface MemberCursor {
  roleRank: number;
  displayName: string;
  userId: string;
}

/** Что случилось при исключении участника — счётчик задач нужен ответу и тесту (D-31). */
export interface MemberRemoval {
  removed: boolean;
  unassignedIssues: number;
}

/** Порядок вкладки «Участники»: администраторы первыми, дальше по имени. */
const roleRankSql = sql<number>`case when ${projectMembers.role} = 'admin' then 0 else 1 end`;

/**
 * Поиск по составу проекта: подстрока в имени или в email, без учёта регистра.
 *
 * Выборка и без того ограничена участниками одного проекта, поэтому email здесь
 * ищется наравне с именем: на вкладке «Участники» он и так виден каждому участнику.
 */
function searchCondition(term: string): SQL {
  const pattern = containsPattern(term);
  return sql`(${users.displayName} ilike ${pattern} escape '\\' or ${users.email} ilike ${pattern} escape '\\')`;
}

@Injectable()
export class MembersRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  async list(options: {
    projectId: string;
    limit: number;
    after?: MemberCursor;
    search?: string;
  }): Promise<MemberRow[]> {
    const conditions = [eq(projectMembers.projectId, options.projectId)];
    if (options.search) {
      conditions.push(searchCondition(options.search));
    }
    if (options.after) {
      conditions.push(
        sql`(case when project_members.role = 'admin' then 0 else 1 end, users.display_name, users.id)
            > (${options.after.roleRank}, ${options.after.displayName}, ${options.after.userId}::uuid)`,
      );
    }

    return this.db
      .select({
        userId: users.id,
        displayName: users.displayName,
        email: users.email,
        avatarUrl: users.avatarUrl,
        role: projectMembers.role,
        joinedAt: projectMembers.createdAt,
      })
      .from(projectMembers)
      .innerJoin(users, eq(users.id, projectMembers.userId))
      .where(and(...conditions))
      .orderBy(roleRankSql, users.displayName, users.id)
      .limit(options.limit);
  }

  /**
   * Сколько всего строк в списке. С поиском считаются совпадения, а не весь состав:
   * иначе счётчик под полем поиска показывал бы не то, что видно в списке.
   * Присоединение к `users` нужно только поиску — без него это счёт по одной таблице.
   */
  async count(projectId: string, search?: string): Promise<number> {
    const value = sql<number>`count(*)::int`;
    const [row] = search
      ? await this.db
          .select({ value })
          .from(projectMembers)
          .innerJoin(users, eq(users.id, projectMembers.userId))
          .where(and(eq(projectMembers.projectId, projectId), searchCondition(search)))
      : await this.db
          .select({ value })
          .from(projectMembers)
          .where(eq(projectMembers.projectId, projectId));
    return row?.value ?? 0;
  }

  /** Инвариант «в проекте всегда есть администратор» проверяется этим счётчиком. */
  async countAdmins(projectId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(projectMembers)
      .where(and(eq(projectMembers.projectId, projectId), eq(projectMembers.role, 'admin')));
    return row?.value ?? 0;
  }

  async find(projectId: string, userId: string): Promise<MemberRow | null> {
    const [row] = await this.db
      .select({
        userId: users.id,
        displayName: users.displayName,
        email: users.email,
        avatarUrl: users.avatarUrl,
        role: projectMembers.role,
        joinedAt: projectMembers.createdAt,
      })
      .from(projectMembers)
      .innerJoin(users, eq(users.id, projectMembers.userId))
      .where(and(eq(projectMembers.projectId, projectId), eq(projectMembers.userId, userId)))
      .limit(1);
    return row ?? null;
  }

  async updateRole(projectId: string, userId: string, role: ProjectRole): Promise<boolean> {
    const updated = await this.db
      .update(projectMembers)
      .set({ role })
      .where(and(eq(projectMembers.projectId, projectId), eq(projectMembers.userId, userId)))
      .returning({ id: projectMembers.id });
    return updated.length > 0;
  }

  /**
   * Исключение участника (US-16, D-31).
   *
   * Задачи не удаляются и не переназначаются: у задач исключённого очищается поле
   * «Исполнитель», и на каждую такую задачу пишется запись истории — **в той же
   * транзакции**, что и само изменение, иначе история разойдётся с данными.
   *
   * Автор записи — система (`actor_id = null`): исполнителя снял не человек, а
   * следствие исключения (комментарий к `issue_history`).
   */
  async remove(projectId: string, userId: string): Promise<MemberRemoval> {
    return this.db.transaction(async (tx) => {
      const deleted = await tx
        .delete(projectMembers)
        .where(and(eq(projectMembers.projectId, projectId), eq(projectMembers.userId, userId)))
        .returning({ id: projectMembers.id });

      if (deleted.length === 0) {
        return { removed: false, unassignedIssues: 0 };
      }

      const [profile] = await tx
        .select({ displayName: users.displayName })
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);

      const unassigned = await tx
        .update(issues)
        .set({ assigneeId: null })
        .where(
          and(
            eq(issues.assigneeId, userId),
            sql`${issues.queueId} in (select ${queues.id} from ${queues} where ${queues.projectId} = ${projectId}::uuid)`,
          ),
        )
        .returning({ id: issues.id });

      if (unassigned.length > 0) {
        // Одно действие — одна группа в истории, даже если задач было много (US-90).
        const groupId = randomUUID();
        await tx.insert(issueHistory).values(
          unassigned.map((issue) => ({
            issueId: issue.id,
            actorId: null,
            kind: 'assignee_changed' as const,
            groupId,
            oldValue: profile?.displayName ?? null,
            oldRefId: userId,
            newValue: null,
            newRefId: null,
          })),
        );
      }

      return { removed: true, unassignedIssues: unassigned.length };
    });
  }
}
