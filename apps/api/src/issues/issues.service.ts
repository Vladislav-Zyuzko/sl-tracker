import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import { QueueAccessService, QueuesRepository } from '../queues/index.js';
import type { QueueContext } from '../queues/index.js';
// Конкретные файлы, а не бочка realtime: та тянет gateway, который сам зависит
// от домена задач, — получился бы цикл модулей.
import { issueTopic } from '../realtime/realtime.events.js';
import { RealtimePublisher } from '../realtime/realtime.publisher.js';
import { type IssueContext, IssueAccessService, issueNotFound } from './issue-access.service.js';
import {
  ISSUE_PRIORITY_DEFAULT,
  isValidPriority,
  isValidStoryPoints,
  normalizeDescription,
  normalizeTitle,
} from './issue-fields.js';
import type { IssuePatch } from './issue-history.js';
import {
  type IssueDetail,
  type IssueLinkRow,
  type IssueListRow,
  type IssueSortOrder,
  IssuesRepository,
} from './issues.repository.js';

/** Порция списка задач — 50 строк (design/queue-issues.md); потолок жёсткий. */
export const ISSUES_DEFAULT_LIMIT = 50;
export const ISSUES_MAX_LIMIT = 100;

/** Только `http` и `https`: остальные схемы отклоняются (US-47). */
const LINK_SCHEME_PATTERN = /^https?:\/\/\S/i;
export const ISSUE_LINK_URL_MAX_LENGTH = 2048;
export const ISSUE_LINK_TITLE_MAX_LENGTH = 100;

export interface IssueView {
  detail: IssueDetail;
  links: IssueLinkRow[];
  role: IssueContext['role'];
}

export interface IssuesPage {
  items: IssueListRow[];
  nextCursor: string | null;
  /** Сколько задач подходит под фильтры: счётчик «Показано N из M». */
  total: number;
  queue: QueueContext;
}

export interface CreateIssueInput {
  title: string;
  description?: string | null;
  statusId?: string;
  priority?: number;
  storyPoints?: number | null;
  authorId?: string;
  assigneeId?: string | null;
}

export type UpdateIssueInput = Partial<CreateIssueInput>;

/**
 * Задачи: создание, чтение, изменение, удаление, список очереди (US-40 … US-44, US-50 … US-53).
 *
 * Здесь живут доменные правила, которых нет ни в схеме, ни в DTO:
 *  - **переходы статусов свободные** (D-10): графа переходов нет, но статус обязан
 *    принадлежать очереди задачи — иначе задача уехала бы в чужой набор состояний;
 *  - автор и исполнитель выбираются **только из участников проекта** (US-52, US-53);
 *  - автор задачи редактируемый, создатель — нет (D-13): `createdByUserId` в патче
 *    отсутствует физически;
 *  - приоритет никогда не бывает пустым (D-15).
 */
@Injectable()
export class IssuesService {
  constructor(
    private readonly repository: IssuesRepository,
    private readonly access: IssueAccessService,
    private readonly queues: QueueAccessService,
    private readonly queueData: QueuesRepository,
    private readonly realtime: RealtimePublisher,
  ) {}

  /**
   * Создание задачи (US-40). Администратор и участник; читатель — 403.
   *
   * Умолчания: статус — первый статус очереди, приоритет — 50, сложность — не задана,
   * автор — создатель, исполнитель — не назначен.
   */
  async create(
    queueKey: string,
    input: CreateIssueInput,
    actor: AuthenticatedUser,
  ): Promise<IssueView> {
    const queue = await this.queues.require(queueKey, actor);
    if (queue.role === 'reader') {
      throw new ForbiddenException({
        code: 'issue_forbidden',
        message: 'У вас нет прав создавать задачи в этом проекте',
      });
    }

    const title = normalizeTitle(input.title);
    if (title === null) {
      throw new BadRequestException({
        code: 'invalid_issue_title',
        message: 'Название задачи обязательно и не длиннее 255 символов',
      });
    }

    const status = input.statusId
      ? await this.repository.findStatusInQueue(queue.queue.id, input.statusId)
      : await this.repository.defaultStatusOf(queue.queue.id);
    if (!status) {
      throw new BadRequestException({
        code: 'invalid_status',
        message: 'Такого статуса нет в этой очереди',
      });
    }

    const priority = input.priority ?? ISSUE_PRIORITY_DEFAULT;
    assertPriority(priority);
    const storyPoints = input.storyPoints ?? null;
    assertStoryPoints(storyPoints);

    const authorId = input.authorId ?? actor.id;
    const assigneeId = input.assigneeId ?? null;
    await this.assertProjectMembers(queue.queue.projectId, { authorId, assigneeId });

    const created = await this.repository.create({
      queueId: queue.queue.id,
      projectId: queue.queue.projectId,
      title,
      description: normalizeDescription(input.description),
      statusId: status.id,
      priority,
      storyPoints,
      authorId,
      assigneeId,
      createdByUserId: actor.id,
    });

    return this.viewOfKey(created.key, actor);
  }

  /** Задача по ключу (US-41). Ключ регистронезависим; не-участник получает 404. */
  async getByKey(key: string, actor: AuthenticatedUser): Promise<IssueView> {
    const context = await this.access.require(key, actor);
    return {
      detail: context.detail,
      links: await this.repository.linksOf(context.detail.issue.id),
      role: context.role,
    };
  }

  /**
   * Изменение полей задачи (US-42, US-43, US-50 … US-53, US-61).
   *
   * Меняет администратор и участник, в том числе у чужой задачи (D-11); читатель — 403.
   * Поля, которых нет в теле запроса, не трогаются; поля, значение которых не меняется,
   * не попадают в историю (US-91).
   */
  async update(key: string, input: UpdateIssueInput, actor: AuthenticatedUser): Promise<IssueView> {
    const context = await this.access.requireEditable(key, actor);
    const issue = context.detail.issue;
    const patch: IssuePatch = {};

    if (input.title !== undefined) {
      const title = normalizeTitle(input.title);
      if (title === null) {
        throw new BadRequestException({
          code: 'invalid_issue_title',
          message: 'Название задачи обязательно и не длиннее 255 символов',
        });
      }
      patch.title = title;
    }

    if (input.description !== undefined) {
      patch.description = normalizeDescription(input.description);
    }

    if (input.statusId !== undefined) {
      // Переход свободный (D-10), но только внутри набора статусов своей очереди.
      const status = await this.repository.findStatusInQueue(issue.queueId, input.statusId);
      if (!status) {
        throw new BadRequestException({
          code: 'invalid_status',
          message: 'Такого статуса нет в этой очереди',
        });
      }
      patch.statusId = status.id;
    }

    if (input.priority !== undefined) {
      assertPriority(input.priority);
      patch.priority = input.priority;
    }

    if (input.storyPoints !== undefined) {
      assertStoryPoints(input.storyPoints);
      patch.storyPoints = input.storyPoints;
    }

    if (input.authorId !== undefined) {
      patch.authorId = input.authorId;
    }
    if (input.assigneeId !== undefined) {
      patch.assigneeId = input.assigneeId;
    }

    if (patch.authorId !== undefined || patch.assigneeId !== undefined) {
      await this.assertProjectMembers(context.detail.projectId, {
        authorId: patch.authorId,
        assigneeId: patch.assigneeId ?? null,
      });
    }

    const updated = await this.repository.update(
      issue.id,
      patch,
      actor.id,
      context.detail.projectId,
    );
    if (!updated) {
      throw issueNotFound();
    }

    if (updated.changedFields.length > 0) {
      await this.announce(context, actor.id, 'issue.updated', {
        changedFields: updated.changedFields,
      });
    }

    return this.viewOfKey(updated.issue.key, actor);
  }

  /** Удаление задачи (US-44). Только администратор проекта; номер не переиспользуется. */
  async remove(key: string, actor: AuthenticatedUser): Promise<void> {
    const context = await this.access.requireDeletable(key, actor);
    const deleted = await this.repository.delete(context.detail.issue.id);
    if (!deleted) {
      throw issueNotFound();
    }

    await this.announce(context, actor.id, 'issue.deleted');
  }

  /**
   * Список задач очереди (US-32, D-28).
   *
   * Порядок по умолчанию — приоритет ↓, при равенстве номер ↓; второй вариант —
   * «сначала новые» (номер ↓). Фильтр по статусу задаётся **ключами статусов**
   * (`open`, `in_progress`, …), а не их идентификаторами: так ссылка на
   * отфильтрованный список читаема и переживает пересоздание очереди.
   */
  async listForQueue(
    queueKey: string,
    options: {
      limit?: number;
      cursor?: string;
      sort?: IssueSortOrder;
      statusKeys?: string[];
      assignee?: string;
      authorId?: string;
      priorityMin?: number;
      priorityMax?: number;
    },
    actor: AuthenticatedUser,
  ): Promise<IssuesPage> {
    const queue = await this.queues.require(queueKey, actor);
    const limit = clampLimit(options.limit, ISSUES_DEFAULT_LIMIT, ISSUES_MAX_LIMIT);
    const sort = options.sort ?? 'priority';

    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    let statusIds: string[] | undefined;
    if (options.statusKeys && options.statusKeys.length > 0) {
      const all = await this.queueData.statusesOf(queue.queue.id);
      const wanted = new Set(options.statusKeys);
      statusIds = all.filter((status) => wanted.has(status.key)).map((status) => status.id);
      if (statusIds.length === 0) {
        // Ни один запрошенный статус в этой очереди не существует: пустая страница,
        // а не ошибка — так ссылка с фильтром от другой очереди не ломает экран.
        return { items: [], nextCursor: null, total: 0, queue };
      }
    }

    if (options.priorityMin !== undefined) {
      assertPriority(options.priorityMin);
    }
    if (options.priorityMax !== undefined) {
      assertPriority(options.priorityMax);
    }

    const filters = {
      queueId: queue.queue.id,
      statusIds,
      assignee: options.assignee,
      authorId: options.authorId,
      priorityMin: options.priorityMin,
      priorityMax: options.priorityMax,
    };

    const rows = await this.repository.listForQueue({
      ...filters,
      limit: limit + 1,
      sort,
      after: after ?? undefined,
    });

    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items,
      nextCursor:
        hasMore && last ? encodeCursor([String(last.priority), String(last.number)]) : null,
      total: await this.repository.countForQueue(filters),
      queue,
    };
  }

  /** Добавление внешней ссылки (US-47). Администратор и участник; читатель — 403. */
  async addLink(
    key: string,
    input: { url: string; title?: string | null },
    actor: AuthenticatedUser,
  ): Promise<IssueView> {
    const context = await this.access.requireEditable(key, actor);
    const url = input.url.trim();

    if (!LINK_SCHEME_PATTERN.test(url) || url.length > ISSUE_LINK_URL_MAX_LENGTH) {
      throw new BadRequestException({
        code: 'invalid_link_url',
        message: 'Адрес должен начинаться с http:// или https://',
      });
    }

    const title = input.title?.trim();
    await this.repository.addLink({
      issueId: context.detail.issue.id,
      url,
      title: title && title.length > 0 ? title : null,
      actorId: actor.id,
    });

    await this.announce(context, actor.id, 'issue.updated', { changedFields: ['links'] });
    return this.viewOfKey(context.detail.issue.key, actor);
  }

  /** Удаление ссылки (US-47). Может администратор или любой участник проекта. */
  async removeLink(key: string, linkId: string, actor: AuthenticatedUser): Promise<IssueView> {
    const context = await this.access.requireEditable(key, actor);
    const removed = await this.repository.removeLink(context.detail.issue.id, linkId, actor.id);
    if (!removed) {
      throw new BadRequestException({ code: 'link_not_found', message: 'Ссылка не найдена' });
    }

    await this.announce(context, actor.id, 'issue.updated', { changedFields: ['links'] });
    return this.viewOfKey(context.detail.issue.key, actor);
  }

  /**
   * Живое обновление экрана задачи (D-26).
   *
   * Публикуется **после** того, как репозиторий вернул управление, то есть после
   * фиксации транзакции: иначе клиент придёт за данными, которых ещё нет.
   *
   * Уходит сигнал, а не состояние задачи: `changedFields` названы так же, как поля
   * ответа `GET /api/issues/{key}`, и клиент перечитывает то, что изменилось.
   * Отдавать здесь готовый `IssueDto` нельзя — он собирается под конкретного
   * запросившего (его роль и права), а у подписчиков они разные.
   */
  private async announce(
    context: IssueContext,
    actorId: string,
    event: 'issue.updated' | 'issue.deleted',
    data: Record<string, unknown> = {},
  ): Promise<void> {
    await this.realtime.publish([
      {
        topic: issueTopic(context.detail.issue.id),
        event,
        projectId: context.detail.projectId,
        actorId,
        data: { key: context.detail.issue.key, ...data },
      },
    ]);
  }

  /**
   * Автор и исполнитель выбираются только из участников проекта (US-52, US-53).
   * Оба проверяются одним запросом: два похода в базу ради двух идентификаторов —
   * лишний round-trip на каждое сохранение поля.
   */
  private async assertProjectMembers(
    projectId: string,
    people: { authorId?: string; assigneeId?: string | null },
  ): Promise<void> {
    const wanted = [people.authorId, people.assigneeId].filter(
      (id): id is string => typeof id === 'string',
    );
    if (wanted.length === 0) {
      return;
    }

    const members = await this.repository.projectMembersAmong(projectId, wanted);

    if (people.authorId && !members.has(people.authorId)) {
      throw new BadRequestException({
        code: 'author_not_member',
        message: 'Автором можно назначить только участника проекта',
      });
    }
    if (people.assigneeId && !members.has(people.assigneeId)) {
      throw new BadRequestException({
        code: 'assignee_not_member',
        message: 'Исполнителем можно назначить только участника проекта',
      });
    }
  }

  /** Полный ответ после изменения: клиенту нужно актуальное состояние, а не эхо запроса. */
  private async viewOfKey(key: string, actor: AuthenticatedUser): Promise<IssueView> {
    const found = await this.repository.findByKeyForUser(key, actor.id);
    if (!found || found.role === null) {
      throw issueNotFound();
    }
    return {
      detail: found.detail,
      links: await this.repository.linksOf(found.detail.issue.id),
      role: found.role,
    };
  }
}

function assertPriority(value: number): void {
  if (!isValidPriority(value)) {
    throw new BadRequestException({
      code: 'invalid_priority',
      message: 'Приоритет — целое число от 0 до 100 с шагом 10',
    });
  }
}

function assertStoryPoints(value: number | null): void {
  if (!isValidStoryPoints(value)) {
    throw new BadRequestException({
      code: 'invalid_story_points',
      message: 'Сложность — одно из значений 1, 2, 3, 5, 8, 13 либо «не оценено»',
    });
  }
}

/** Курсор списка задач: приоритет и номер последней отданной строки. */
function parseCursor(raw: string): { priority: number; number: number } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const priority = Number(parts[0]);
  const number = Number(parts[1]);
  if (!Number.isInteger(priority) || !Number.isInteger(number)) {
    return null;
  }
  return { priority, number };
}
