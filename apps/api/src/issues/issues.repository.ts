import { randomUUID } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { and, asc, desc, eq, inArray, isNull, sql } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { DB, UnitOfWork, type Database, type Executor } from '../database/index.js';
import {
  issueHistory,
  issueLinks,
  issues,
  projectMembers,
  projects,
  queues,
  statuses,
  users,
} from '../database/schema/index.js';
import { MentionsRepository } from '../mentions/index.js';
import {
  NotificationEventsService,
  type IssueEventRef,
  type NotificationDraft,
} from '../notifications/index.js';
import type { ProjectRole } from '../projects/index.js';
import type { StatusCategory } from '../queues/status-category.js';
import { IssueKeyService } from './issue-key.service.js';
import {
  type IssuePatch,
  type IssueSnapshot,
  changedApiFields,
  diffIssue,
  effectiveChanges,
  labelLookups,
} from './issue-history.js';

export interface IssueRow {
  id: string;
  queueId: string;
  number: number;
  key: string;
  title: string;
  description: string | null;
  statusId: string;
  priority: number;
  storyPoints: number | null;
  authorId: string;
  createdByUserId: string;
  assigneeId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserRef {
  id: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface IssueStatusRef {
  id: string;
  key: string;
  name: string;
  category: StatusCategory;
  position: number;
}

/** Задача со всем, что нужно её странице: статус, люди, очередь, проект. */
export interface IssueDetail {
  issue: IssueRow;
  status: IssueStatusRef;
  author: UserRef;
  assignee: UserRef | null;
  queueKey: string;
  queueName: string;
  projectId: string;
  projectSlug: string;
  projectName: string;
}

export interface IssueLookup {
  detail: IssueDetail;
  /** `null` — пользователь не состоит в проекте, значит задачи для него не существует. */
  role: ProjectRole | null;
}

/** Ровно те поля, что нужны строке списка задач очереди (design/queue-issues.md). */
export interface IssueListRow {
  key: string;
  number: number;
  title: string;
  priority: number;
  storyPoints: number | null;
  statusId: string;
  statusKey: string;
  statusName: string;
  statusCategory: StatusCategory;
  assigneeId: string | null;
  assigneeDisplayName: string | null;
  assigneeAvatarUrl: string | null;
}

export type IssueSortOrder = 'priority' | 'newest';

export interface IssueListFilters {
  queueId: string;
  /** Идентификаторы статусов очереди. Пусто — фильтра по статусу нет. */
  statusIds?: string[];
  /**
   * Идентификатор исполнителя либо строка `none` — только задачи без исполнителя.
   * Тип намеренно просто `string`: сужение до `string | 'none'` ничего не проверяет,
   * потому что `'none'` и так входит в `string`.
   */
  assignee?: string;
  authorId?: string;
  priorityMin?: number;
  priorityMax?: number;
}

export interface IssueListOptions extends IssueListFilters {
  limit: number;
  sort: IssueSortOrder;
  after?: { priority: number; number: number };
}

/** Результат изменения задачи: сама задача, объём истории и имена изменившихся полей. */
export interface IssueUpdateResult {
  issue: IssueRow;
  /** Сколько записей истории породило изменение (US-90). */
  changed: number;
  /** Имена полей так, как их зовёт API: их получает живое обновление (D-26). */
  changedFields: string[];
}

export interface IssueLinkRow {
  id: string;
  issueId: string;
  url: string;
  title: string | null;
  createdAt: Date;
  createdBy: UserRef;
}

const ISSUE_COLUMNS = {
  id: issues.id,
  queueId: issues.queueId,
  number: issues.number,
  key: issues.key,
  title: issues.title,
  description: issues.description,
  statusId: issues.statusId,
  priority: issues.priority,
  storyPoints: issues.storyPoints,
  authorId: issues.authorId,
  createdByUserId: issues.createdByUserId,
  assigneeId: issues.assigneeId,
  createdAt: issues.createdAt,
  updatedAt: issues.updatedAt,
};

/** Автор и исполнитель — оба из `users`, поэтому таблице нужны два псевдонима. */
const authorUsers = alias(users, 'author_users');
const assigneeUsers = alias(users, 'assignee_users');
const linkAuthors = alias(users, 'link_authors');

/**
 * SQL задач. Проверок прав здесь нет: репозиторий отдаёт роль пользователя в проекте,
 * а решение «404 или 403» принимает сервис.
 *
 * Главное правило домена, за которое отвечает именно этот файл: **изменение задачи
 * и запись в историю происходят в одной транзакции**. Историю задним числом
 * не восстановить, и расходится она ровно тогда, когда нужнее всего.
 */
@Injectable()
export class IssuesRepository {
  constructor(
    @Inject(DB) private readonly db: Database,
    private readonly uow: UnitOfWork,
    private readonly keys: IssueKeyService,
    private readonly mentions: MentionsRepository,
    private readonly events: NotificationEventsService,
  ) {}

  /**
   * Создание задачи (US-40).
   *
   * Номер выдаётся инкрементом счётчика очереди **в той же транзакции**, что и вставка
   * (ADR-0004): при откате номер возвращается, при параллельных вызовах — строчная
   * блокировка выстраивает их в очередь. `SELECT max(number) + 1` запрещён.
   *
   * Первая запись истории — `issue_created` с реальным создателем: она неизменяема
   * и остаётся правдой, даже если поле «Автор» потом поменяют (D-13).
   */
  async create(input: {
    queueId: string;
    projectId: string;
    title: string;
    description: string | null;
    statusId: string;
    priority: number;
    storyPoints: number | null;
    authorId: string;
    assigneeId: string | null;
    createdByUserId: string;
  }): Promise<IssueRow> {
    return this.uow.transaction(async (tx) => {
      const allocated = await this.keys.allocate(tx, input.queueId);

      const [created] = await tx
        .insert(issues)
        .values({
          queueId: input.queueId,
          number: allocated.number,
          key: allocated.key,
          title: input.title,
          description: input.description,
          statusId: input.statusId,
          priority: input.priority,
          storyPoints: input.storyPoints,
          authorId: input.authorId,
          createdByUserId: input.createdByUserId,
          assigneeId: input.assigneeId,
        })
        .returning(ISSUE_COLUMNS);

      await tx.insert(issueHistory).values({
        issueId: created!.id,
        actorId: input.createdByUserId,
        kind: 'issue_created',
        groupId: randomUUID(),
        oldValue: null,
        newValue: null,
        oldRefId: null,
        newRefId: null,
      });

      const issue: IssueEventRef = {
        id: created!.id,
        key: created!.key,
        title: created!.title,
        projectId: input.projectId,
      };

      // Упоминания в описании — такие же, как в комментарии, только `comment_id` пуст
      // (US-74). Посторонние отсеиваются в самом репозитории упоминаний (D-41).
      const mentioned = input.description
        ? await this.mentions.sync(
            tx,
            { issueId: created!.id, commentId: null },
            input.description,
            {
              projectId: input.projectId,
              actorId: input.createdByUserId,
            },
          )
        : [];

      // Порядок заготовок — приоритет: назначение важнее упоминания, и один человек
      // получает по одному действию не больше одного уведомления (US-101).
      await this.events.emit(tx, { actorId: input.createdByUserId, projectId: input.projectId }, [
        ...(input.assigneeId ? [this.events.assigned(issue, input.assigneeId)] : []),
        ...(input.authorId !== input.createdByUserId
          ? [this.events.authorAssigned(issue, input.authorId)]
          : []),
        this.events.mentioned(
          issue,
          mentioned.filter((row) => row.isNew).map((row) => row.id),
          { commentId: null, body: input.description ?? '' },
        ),
      ]);

      return created!;
    });
  }

  /**
   * Задача по ключу вместе с ролью пользователя в проекте — одним запросом.
   * Статус, автор и исполнитель приезжают join'ами: четыре отдельных запроса
   * на открытие задачи были бы N+1 в чистом виде.
   */
  async findByKeyForUser(key: string, userId: string): Promise<IssueLookup | null> {
    const [row] = await this.db
      .select({
        ...ISSUE_COLUMNS,
        statusKey: statuses.key,
        statusName: statuses.name,
        statusCategory: statuses.category,
        statusPosition: statuses.position,
        queueKey: queues.key,
        queueName: queues.name,
        projectId: projects.id,
        projectSlug: projects.slug,
        projectName: projects.name,
        authorDisplayName: authorUsers.displayName,
        authorAvatarUrl: authorUsers.avatarUrl,
        assigneeDisplayName: assigneeUsers.displayName,
        assigneeAvatarUrl: assigneeUsers.avatarUrl,
        role: projectMembers.role,
      })
      .from(issues)
      .innerJoin(statuses, eq(statuses.id, issues.statusId))
      .innerJoin(queues, eq(queues.id, issues.queueId))
      .innerJoin(projects, eq(projects.id, queues.projectId))
      .innerJoin(authorUsers, eq(authorUsers.id, issues.authorId))
      .leftJoin(assigneeUsers, eq(assigneeUsers.id, issues.assigneeId))
      .leftJoin(
        projectMembers,
        and(eq(projectMembers.projectId, queues.projectId), eq(projectMembers.userId, userId)),
      )
      .where(eq(issues.key, key))
      .limit(1);

    if (!row) {
      return null;
    }

    const {
      statusKey,
      statusName,
      statusCategory,
      statusPosition,
      queueKey,
      queueName,
      projectId,
      projectSlug,
      projectName,
      authorDisplayName,
      authorAvatarUrl,
      assigneeDisplayName,
      assigneeAvatarUrl,
      role,
      ...issue
    } = row;

    return {
      role,
      detail: {
        issue,
        status: {
          id: issue.statusId,
          key: statusKey,
          name: statusName,
          category: statusCategory,
          position: statusPosition,
        },
        author: {
          id: issue.authorId,
          displayName: authorDisplayName,
          avatarUrl: authorAvatarUrl,
        },
        assignee: issue.assigneeId
          ? {
              id: issue.assigneeId,
              displayName: assigneeDisplayName ?? '',
              avatarUrl: assigneeAvatarUrl,
            }
          : null,
        queueKey,
        queueName,
        projectId,
        projectSlug,
        projectName,
      },
    };
  }

  /**
   * Изменение полей задачи вместе с записью истории — в одной транзакции (US-90).
   *
   * Порядок внутри транзакции:
   *  1. строка задачи блокируется `FOR UPDATE` — иначе два параллельных изменения
   *     посчитали бы diff от одного и того же «до» и история соврала бы;
   *  2. отбрасываются поля, значение которых не меняется (US-91: «выбрал тот же
   *     статус» историю не порождает);
   *  3. одним запросом достаются читаемые названия статусов и имена людей;
   *  4. задача обновляется;
   *  5. записи истории вставляются с **общим `groupId`** — одно действие пользователя
   *     показывается одной группой, даже если полей изменилось несколько (US-90).
   *
   * `null` — задачи уже нет. Пустой `changes` — менять было нечего.
   */
  async update(
    issueId: string,
    patch: IssuePatch,
    actorId: string,
    projectId: string,
  ): Promise<IssueUpdateResult | null> {
    return this.uow.transaction(async (tx) => {
      const [before] = await tx
        .select(ISSUE_COLUMNS)
        .from(issues)
        .where(eq(issues.id, issueId))
        .for('update')
        .limit(1);

      if (!before) {
        return null;
      }

      const snapshot: IssueSnapshot = {
        title: before.title,
        description: before.description,
        statusId: before.statusId,
        priority: before.priority,
        storyPoints: before.storyPoints,
        authorId: before.authorId,
        assigneeId: before.assigneeId,
      };

      const changes = effectiveChanges(snapshot, patch);
      if (Object.keys(changes).length === 0) {
        return { issue: before, changed: 0, changedFields: [] };
      }

      const labels = await this.readLabels(tx, snapshot, changes);
      const entries = diffIssue(snapshot, changes, labels);

      const [updated] = await tx
        .update(issues)
        .set(changes)
        .where(eq(issues.id, issueId))
        .returning(ISSUE_COLUMNS);

      if (entries.length > 0) {
        const groupId = randomUUID();
        await tx
          .insert(issueHistory)
          .values(entries.map((entry) => ({ ...entry, issueId, actorId, groupId })));
      }

      await this.notifyOfChanges(tx, {
        issue: {
          id: issueId,
          key: updated!.key,
          title: updated!.title,
          projectId,
        },
        actorId,
        before: snapshot,
        changes,
        statusNames: labels.statusNames,
      });

      return { issue: updated!, changed: entries.length, changedFields: changedApiFields(changes) };
    });
  }

  /** Удаление задачи (US-44). Комментарии, вложения, ссылки и история уходят каскадом. */
  async delete(issueId: string): Promise<boolean> {
    const deleted = await this.db
      .delete(issues)
      .where(eq(issues.id, issueId))
      .returning({ id: issues.id });
    return deleted.length > 0;
  }

  /**
   * Список задач очереди (US-32, D-28).
   *
   * Статус и исполнитель приезжают join'ами в том же запросе: строке списка они нужны
   * всегда, а отдельный поход за каждым — это N+1 на 1000 строк.
   *
   * Пагинация курсорная, по ключу сортировки, а не по OFFSET: список пополняется
   * параллельно, и OFFSET пропускал бы и дублировал строки.
   */
  async listForQueue(options: IssueListOptions): Promise<IssueListRow[]> {
    const conditions = buildFilters(options);

    if (options.after) {
      conditions.push(
        options.sort === 'priority'
          ? sql`(${issues.priority}, ${issues.number}) < (${options.after.priority}, ${options.after.number})`
          : sql`${issues.number} < ${options.after.number}`,
      );
    }

    const order =
      options.sort === 'priority'
        ? [desc(issues.priority), desc(issues.number)]
        : [desc(issues.number)];

    return this.db
      .select({
        key: issues.key,
        number: issues.number,
        title: issues.title,
        priority: issues.priority,
        storyPoints: issues.storyPoints,
        statusId: statuses.id,
        statusKey: statuses.key,
        statusName: statuses.name,
        statusCategory: statuses.category,
        assigneeId: issues.assigneeId,
        assigneeDisplayName: assigneeUsers.displayName,
        assigneeAvatarUrl: assigneeUsers.avatarUrl,
      })
      .from(issues)
      .innerJoin(statuses, eq(statuses.id, issues.statusId))
      .leftJoin(assigneeUsers, eq(assigneeUsers.id, issues.assigneeId))
      .where(and(...conditions))
      .orderBy(...order)
      .limit(options.limit);
  }

  /** Счётчик «Показано N из M» в панели фильтров. Считается с теми же фильтрами. */
  async countForQueue(filters: IssueListFilters): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(issues)
      .where(and(...buildFilters(filters)));
    return row?.value ?? 0;
  }

  /** Статус очереди по идентификатору: смена статуса на чужой статус недопустима. */
  async findStatusInQueue(queueId: string, statusId: string): Promise<IssueStatusRef | null> {
    const [row] = await this.db
      .select({
        id: statuses.id,
        key: statuses.key,
        name: statuses.name,
        category: statuses.category,
        position: statuses.position,
      })
      .from(statuses)
      .where(and(eq(statuses.queueId, queueId), eq(statuses.id, statusId)))
      .limit(1);
    return row ?? null;
  }

  /** Первый по порядку статус очереди — статус новой задачи по умолчанию (US-60). */
  async defaultStatusOf(queueId: string): Promise<IssueStatusRef | null> {
    const [row] = await this.db
      .select({
        id: statuses.id,
        key: statuses.key,
        name: statuses.name,
        category: statuses.category,
        position: statuses.position,
      })
      .from(statuses)
      .where(eq(statuses.queueId, queueId))
      .orderBy(asc(statuses.position))
      .limit(1);
    return row ?? null;
  }

  /**
   * Кто из переданных людей состоит в проекте. Одним запросом на весь набор:
   * автор и исполнитель проверяются вместе, а не двумя походами в базу.
   */
  async projectMembersAmong(projectId: string, userIds: string[]): Promise<Set<string>> {
    if (userIds.length === 0) {
      return new Set();
    }
    const rows = await this.db
      .select({ userId: projectMembers.userId })
      .from(projectMembers)
      .where(and(eq(projectMembers.projectId, projectId), inArray(projectMembers.userId, userIds)));
    return new Set(rows.map((row) => row.userId));
  }

  /** Внешние ссылки задачи (US-47). Автор ссылки приезжает join'ом, а не вторым запросом. */
  async linksOf(issueId: string): Promise<IssueLinkRow[]> {
    const rows = await this.db
      .select({
        id: issueLinks.id,
        issueId: issueLinks.issueId,
        url: issueLinks.url,
        title: issueLinks.title,
        createdAt: issueLinks.createdAt,
        createdById: linkAuthors.id,
        createdByDisplayName: linkAuthors.displayName,
        createdByAvatarUrl: linkAuthors.avatarUrl,
      })
      .from(issueLinks)
      .innerJoin(linkAuthors, eq(linkAuthors.id, issueLinks.createdByUserId))
      .where(eq(issueLinks.issueId, issueId))
      .orderBy(asc(issueLinks.createdAt), asc(issueLinks.id));

    return rows.map(({ createdById, createdByDisplayName, createdByAvatarUrl, ...link }) => ({
      ...link,
      createdBy: {
        id: createdById,
        displayName: createdByDisplayName,
        avatarUrl: createdByAvatarUrl,
      },
    }));
  }

  /** Добавление ссылки вместе с записью истории — в одной транзакции (US-47, US-91). */
  async addLink(input: {
    issueId: string;
    url: string;
    title: string | null;
    actorId: string;
  }): Promise<IssueLinkRow> {
    return this.uow.transaction(async (tx) => {
      const [created] = await tx
        .insert(issueLinks)
        .values({
          issueId: input.issueId,
          url: input.url,
          title: input.title,
          createdByUserId: input.actorId,
        })
        .returning({
          id: issueLinks.id,
          issueId: issueLinks.issueId,
          url: issueLinks.url,
          title: issueLinks.title,
          createdAt: issueLinks.createdAt,
        });

      await tx.insert(issueHistory).values({
        issueId: input.issueId,
        actorId: input.actorId,
        kind: 'link_added',
        groupId: randomUUID(),
        // В истории фиксируется адрес ссылки, а не её внутренний идентификатор (US-91).
        oldValue: null,
        newValue: input.title ?? input.url,
        oldRefId: null,
        newRefId: null,
      });

      const [author] = await tx
        .select({ id: users.id, displayName: users.displayName, avatarUrl: users.avatarUrl })
        .from(users)
        .where(eq(users.id, input.actorId))
        .limit(1);

      return { ...created!, createdBy: author! };
    });
  }

  /** Удаление ссылки вместе с записью истории — в одной транзакции. */
  async removeLink(issueId: string, linkId: string, actorId: string): Promise<boolean> {
    return this.uow.transaction(async (tx) => {
      const deleted = await tx
        .delete(issueLinks)
        .where(and(eq(issueLinks.id, linkId), eq(issueLinks.issueId, issueId)))
        .returning({ url: issueLinks.url, title: issueLinks.title });

      if (deleted.length === 0) {
        return false;
      }

      await tx.insert(issueHistory).values({
        issueId,
        actorId,
        kind: 'link_removed',
        groupId: randomUUID(),
        oldValue: deleted[0]!.title ?? deleted[0]!.url,
        newValue: null,
        oldRefId: null,
        newRefId: null,
      });

      return true;
    });
  }

  /**
   * Уведомления об изменении задачи (US-100, US-101, US-104) — в той же транзакции,
   * что и само изменение.
   *
   * Заготовки идут по убыванию личной адресованности: «назначили на меня» важнее
   * «упомянули», а «упомянули» важнее «сменился статус». Человек, попавший в более
   * раннюю заготовку, из последующих выпадает: одно действие пользователя даёт ему
   * **не больше одного** уведомления (US-101).
   *
   * Чего здесь нет намеренно: снятие исполнителя уведомления не создаёт (US-100),
   * как и изменение приоритета, сложности, названия, описания, вложений и ссылок —
   * они видны в истории (US-101).
   */
  private async notifyOfChanges(
    tx: Executor,
    input: {
      issue: IssueEventRef;
      actorId: string;
      before: IssueSnapshot;
      changes: IssuePatch;
      statusNames: ReadonlyMap<string, string>;
    },
  ): Promise<void> {
    const drafts: NotificationDraft[] = [];

    if (input.changes.assigneeId) {
      drafts.push(this.events.assigned(input.issue, input.changes.assigneeId));
    }
    if (input.changes.authorId) {
      drafts.push(this.events.authorAssigned(input.issue, input.changes.authorId));
    }

    if (input.changes.description !== undefined && input.changes.description) {
      const mentioned = await this.mentions.sync(
        tx,
        { issueId: input.issue.id, commentId: null },
        input.changes.description,
        { projectId: input.issue.projectId, actorId: input.actorId },
      );
      drafts.push(
        this.events.mentioned(
          input.issue,
          mentioned.filter((row) => row.isNew).map((row) => row.id),
          { commentId: null, body: input.changes.description },
        ),
      );
    }

    if (input.changes.statusId) {
      drafts.push(
        this.events.statusChanged(
          input.issue,
          await this.events.subscribersOf(tx, input.issue.id),
          {
            from: input.statusNames.get(input.before.statusId) ?? null,
            to: input.statusNames.get(input.changes.statusId) ?? null,
          },
        ),
      );
    }

    await this.events.emit(
      tx,
      { actorId: input.actorId, projectId: input.issue.projectId },
      drafts,
    );
  }

  /**
   * Читаемые названия статусов и имена людей на момент изменения — двумя запросами
   * максимум, и только если соответствующие поля вообще менялись.
   */
  private async readLabels(
    tx: Executor,
    before: IssueSnapshot,
    changes: IssuePatch,
  ): Promise<{ statusNames: Map<string, string>; userNames: Map<string, string> }> {
    const { statusIds, userIds } = labelLookups(before, changes);
    const statusNames = new Map<string, string>();
    const userNames = new Map<string, string>();

    if (statusIds.length > 0) {
      const rows = await tx
        .select({ id: statuses.id, name: statuses.name })
        .from(statuses)
        .where(inArray(statuses.id, statusIds));
      for (const row of rows) {
        statusNames.set(row.id, row.name);
      }
    }

    if (userIds.length > 0) {
      const rows = await tx
        .select({ id: users.id, displayName: users.displayName })
        .from(users)
        .where(inArray(users.id, userIds));
      for (const row of rows) {
        userNames.set(row.id, row.displayName);
      }
    }

    return { statusNames, userNames };
  }
}

/**
 * Условия фильтрации списка задач. Собираются в одном месте, чтобы страница
 * и счётчик считались по одному и тому же набору, а не разъезжались.
 */
function buildFilters(filters: IssueListFilters) {
  const conditions = [eq(issues.queueId, filters.queueId)];

  if (filters.statusIds && filters.statusIds.length > 0) {
    conditions.push(inArray(issues.statusId, filters.statusIds));
  }
  if (filters.assignee === 'none') {
    conditions.push(isNull(issues.assigneeId));
  } else if (filters.assignee) {
    conditions.push(eq(issues.assigneeId, filters.assignee));
  }
  if (filters.authorId) {
    conditions.push(eq(issues.authorId, filters.authorId));
  }
  if (filters.priorityMin !== undefined) {
    conditions.push(sql`${issues.priority} >= ${filters.priorityMin}`);
  }
  if (filters.priorityMax !== undefined) {
    conditions.push(sql`${issues.priority} <= ${filters.priorityMax}`);
  }

  return conditions;
}
