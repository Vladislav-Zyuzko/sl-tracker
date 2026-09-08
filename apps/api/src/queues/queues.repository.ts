import { Inject, Injectable } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import {
  issues,
  projectMembers,
  projects,
  queueKeys,
  queues,
  statuses,
} from '../database/schema/index.js';
import type { ProjectRole } from '../projects/index.js';
import { DEFAULT_STATUSES } from './default-statuses.js';
import type { StatusCategory } from './status-category.js';

export interface QueueRow {
  id: string;
  projectId: string;
  key: string;
  name: string;
  description: string | null;
  createdByUserId: string;
  createdAt: Date;
  updatedAt: Date;
}

/** Строка списка очередей проекта: плюс счётчик незавершённых задач (US-31). */
export interface QueueListRow extends QueueRow {
  openIssueCount: number;
}

export interface StatusRow {
  id: string;
  queueId: string;
  key: string;
  name: string;
  category: StatusCategory;
  position: number;
}

/** Что нашлось по ключу очереди: сама очередь, проект и роль запросившего в нём. */
export interface QueueLookup {
  queue: QueueRow;
  projectSlug: string;
  projectName: string;
  /** `null` — пользователь не состоит в проекте, значит очереди для него не существует. */
  role: ProjectRole | null;
}

const QUEUE_COLUMNS = {
  id: queues.id,
  projectId: queues.projectId,
  key: queues.key,
  name: queues.name,
  description: queues.description,
  createdByUserId: queues.createdByUserId,
  createdAt: queues.createdAt,
  updatedAt: queues.updatedAt,
};

/**
 * Незавершённые задачи очереди — те, чей статус **не** в категории `done` (US-31).
 * Условие по категории, а не по названию или позиции статуса: появление у команды
 * статуса «Отменено» в категории `done` не должно ломать счётчик (ADR-0003).
 */
const openIssueCountSql = sql<number>`(
  select count(*)::int
  from issues i
  join statuses s on s.id = i.status_id
  where i.queue_id = queues.id and s.category <> 'done'
)`;

/**
 * SQL очередей и их статусов. Проверок прав здесь нет: репозиторий отдаёт роль
 * пользователя в проекте, а решение «404 или 403» принимает сервис.
 */
@Injectable()
export class QueuesRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Создаёт очередь вместе с бронью ключа и пятью статусами по умолчанию —
   * в одной транзакции (US-30, US-60).
   *
   * Уникальность ключа держится вставкой в `queue_keys`, а не предварительным
   * `select`: два одновременных создания с одним ключом иначе оба прошли бы проверку.
   * `taken` возвращается и когда ключ занят живой очередью, и когда он остался
   * от удалённой — ключи повторно не выдаются (D-25, ADR-0004).
   */
  async create(input: {
    projectId: string;
    key: string;
    name: string;
    description: string | null;
    createdByUserId: string;
  }): Promise<{ queue: QueueRow; statuses: StatusRow[] } | 'taken'> {
    return this.db.transaction(async (tx) => {
      const reserved = await tx
        .insert(queueKeys)
        .values({ key: input.key, queueId: null })
        .onConflictDoNothing()
        .returning({ key: queueKeys.key });

      if (reserved.length === 0) {
        return 'taken' as const;
      }

      const [queue] = await tx
        .insert(queues)
        .values({
          projectId: input.projectId,
          key: input.key,
          name: input.name,
          description: input.description,
          createdByUserId: input.createdByUserId,
        })
        .returning(QUEUE_COLUMNS);

      await tx.update(queueKeys).set({ queueId: queue!.id }).where(eq(queueKeys.key, input.key));

      const created = await tx
        .insert(statuses)
        .values(DEFAULT_STATUSES.map((status) => ({ ...status, queueId: queue!.id })))
        .returning({
          id: statuses.id,
          queueId: statuses.queueId,
          key: statuses.key,
          name: statuses.name,
          category: statuses.category,
          position: statuses.position,
        });

      return {
        queue: queue!,
        statuses: created.sort((left, right) => left.position - right.position),
      };
    });
  }

  /** Очереди проекта по названию по возрастанию (US-31). Их единицы — страницы не нужны. */
  async listForProject(projectId: string): Promise<QueueListRow[]> {
    return this.db
      .select({ ...QUEUE_COLUMNS, openIssueCount: openIssueCountSql })
      .from(queues)
      .where(eq(queues.projectId, projectId))
      .orderBy(asc(queues.name), asc(queues.id));
  }

  /**
   * Очередь по ключу вместе с ролью пользователя в проекте — одним запросом.
   * Отдельный поход за членством означал бы второй запрос на каждое открытие очереди.
   */
  async findByKeyForUser(key: string, userId: string): Promise<QueueLookup | null> {
    const [row] = await this.db
      .select({
        ...QUEUE_COLUMNS,
        projectSlug: projects.slug,
        projectName: projects.name,
        role: projectMembers.role,
      })
      .from(queues)
      .innerJoin(projects, eq(projects.id, queues.projectId))
      .leftJoin(
        projectMembers,
        and(eq(projectMembers.projectId, queues.projectId), eq(projectMembers.userId, userId)),
      )
      .where(eq(queues.key, key))
      .limit(1);

    if (!row) {
      return null;
    }

    const { projectSlug, projectName, role, ...queue } = row;
    return { queue, projectSlug, projectName, role };
  }

  async openIssueCount(queueId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(issues)
      .innerJoin(statuses, eq(statuses.id, issues.statusId))
      .where(and(eq(issues.queueId, queueId), sql`${statuses.category} <> 'done'`));
    return row?.value ?? 0;
  }

  /** Статусы очереди в фиксированном порядке (US-60): выпадающий список и фильтр. */
  async statusesOf(queueId: string): Promise<StatusRow[]> {
    return this.db
      .select({
        id: statuses.id,
        queueId: statuses.queueId,
        key: statuses.key,
        name: statuses.name,
        category: statuses.category,
        position: statuses.position,
      })
      .from(statuses)
      .where(eq(statuses.queueId, queueId))
      .orderBy(asc(statuses.position));
  }

  /** Название и описание. Ключ не меняется никогда и в патч не попадает (D-06). */
  async updateDetails(
    queueId: string,
    patch: { name?: string; description?: string | null },
  ): Promise<QueueRow | null> {
    const [row] = await this.db
      .update(queues)
      .set(patch)
      .where(eq(queues.id, queueId))
      .returning(QUEUE_COLUMNS);
    return row ?? null;
  }

  /**
   * Удаление пустой очереди (US-34, D-24).
   *
   * Проверка «задач нет» и само удаление — в одной транзакции, начинающейся
   * с блокировки строки очереди. Выдача номера задачи (`IssueKeyService.allocate`)
   * берёт ту же строчную блокировку, поэтому создание задачи и удаление очереди
   * выстраиваются в очередь и «пустая очередь с задачей внутри» невозможна.
   *
   * `not_empty` — в очереди есть задачи в любом статусе.
   *
   * Бронь ключа в `queue_keys` остаётся: `queue_keys.queue_id` обнуляется внешним
   * ключом, а строка живёт дальше — ключ удалённой очереди повторно не выдаётся
   * (D-25, ADR-0004).
   */
  async delete(queueId: string): Promise<'deleted' | 'not_empty' | 'not_found'> {
    return this.db.transaction(async (tx) => {
      const locked = await tx
        .select({ id: queues.id })
        .from(queues)
        .where(eq(queues.id, queueId))
        .for('update')
        .limit(1);

      if (locked.length === 0) {
        return 'not_found' as const;
      }

      const [counted] = await tx
        .select({ value: sql<number>`count(*)::int` })
        .from(issues)
        .where(eq(issues.queueId, queueId));

      if ((counted?.value ?? 0) > 0) {
        return 'not_empty' as const;
      }

      await tx.delete(queues).where(eq(queues.id, queueId));
      return 'deleted' as const;
    });
  }
}
