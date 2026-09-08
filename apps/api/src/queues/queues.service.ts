import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { IssueKeyService } from '../issues/issue-key.service.js';
import { ProjectAccessService } from '../projects/index.js';
import type { ProjectRole } from '../projects/index.js';
import { type QueueContext, QueueAccessService, queueNotFound } from './queue-access.service.js';
import {
  type QueueListRow,
  type QueueRow,
  type StatusRow,
  QueuesRepository,
} from './queues.repository.js';

export const QUEUE_NAME_MAX_LENGTH = 100;
export const QUEUE_DESCRIPTION_MAX_LENGTH = 1000;

/** Очередь в том виде, в каком её отдаёт API: с ролью запросившего и счётчиком задач. */
export interface QueueView {
  queue: QueueRow;
  projectSlug: string;
  projectName: string;
  /** Роль запросившего в проекте: по ней клиент решает, показывать ли контролы. */
  role: ProjectRole;
  openIssueCount: number;
}

/**
 * Очереди: создание, список, чтение, переименование, удаление (US-30 … US-34).
 *
 * Два инварианта живут здесь, а не в схеме:
 *  - **ключ очереди неизменяем** (D-06) — его просто нет в патче;
 *  - **удалить можно только пустую очередь** (D-24) — проверка и удаление идут
 *    в одной транзакции с блокировкой строки, иначе параллельное создание задачи
 *    проскочило бы между проверкой и удалением.
 */
@Injectable()
export class QueuesService {
  constructor(
    private readonly repository: QueuesRepository,
    private readonly access: QueueAccessService,
    private readonly projects: ProjectAccessService,
  ) {}

  /** Создание очереди (US-30). Только администратор проекта. */
  async create(
    projectSlug: string,
    input: { key: string; name: string; description?: string | null },
    actor: AuthenticatedUser,
  ): Promise<{ view: QueueView; statuses: StatusRow[] }> {
    const project = await this.projects.requireAdmin(projectSlug, actor);

    const key = IssueKeyService.normalizeQueueKey(input.key);
    if (!key) {
      throw new BadRequestException({
        code: 'invalid_queue_key',
        message: 'Ключ: 2–10 латинских заглавных букв и цифр, первый символ — буква',
      });
    }

    const name = input.name.trim();
    if (name.length === 0) {
      throw new BadRequestException({
        code: 'invalid_queue_name',
        message: 'Название очереди обязательно',
      });
    }

    const created = await this.repository.create({
      projectId: project.project.id,
      key,
      name,
      description: normalizeDescription(input.description),
      createdByUserId: actor.id,
    });

    if (created === 'taken') {
      // В каком проекте занят ключ — не сообщаем: это раскрыло бы чужой проект
      // (US-30, ADR-0004). Занятым он остаётся и после удаления очереди (D-25).
      throw new ConflictException({
        code: 'queue_key_taken',
        message: 'Такой ключ уже занят, выберите другой',
      });
    }

    return {
      view: {
        queue: created.queue,
        projectSlug: project.project.slug,
        projectName: project.project.name,
        role: project.role,
        openIssueCount: 0,
      },
      statuses: created.statuses,
    };
  }

  /**
   * Очереди проекта (US-31). Видны всем участникам проекта, включая читателя.
   * Счётчик незавершённых задач приезжает тем же запросом — иначе это N+1 на список.
   */
  async listForProject(
    projectSlug: string,
    actor: AuthenticatedUser,
  ): Promise<{
    items: QueueListRow[];
    projectSlug: string;
    projectName: string;
    role: ProjectRole;
  }> {
    const project = await this.projects.require(projectSlug, actor);
    return {
      items: await this.repository.listForProject(project.project.id),
      projectSlug: project.project.slug,
      projectName: project.project.name,
      role: project.role,
    };
  }

  /** Одна очередь по ключу. Ключ регистронезависим (ADR-0004). */
  async getByKey(key: string, actor: AuthenticatedUser): Promise<QueueView> {
    const context = await this.access.require(key, actor);
    return this.view(context);
  }

  /** Статусы очереди для выпадающего списка и фильтра (US-60). Видны любому участнику. */
  async statusesOf(key: string, actor: AuthenticatedUser): Promise<StatusRow[]> {
    const context = await this.access.require(key, actor);
    return this.repository.statusesOf(context.queue.id);
  }

  /**
   * Переименование очереди (US-33). Только администратор. Ключ при этом **не меняется**
   * и ключи существующих задач остаются прежними (D-06).
   */
  async updateDetails(
    key: string,
    patch: { name?: string; description?: string | null },
    actor: AuthenticatedUser,
  ): Promise<QueueView> {
    const context = await this.access.requireAdmin(key, actor);

    const changes: { name?: string; description?: string | null } = {};
    if (patch.name !== undefined) {
      const name = patch.name.trim();
      if (name.length === 0) {
        throw new BadRequestException({
          code: 'invalid_queue_name',
          message: 'Название очереди обязательно',
        });
      }
      changes.name = name;
    }
    if (patch.description !== undefined) {
      changes.description = normalizeDescription(patch.description);
    }

    if (Object.keys(changes).length === 0) {
      return this.view(context);
    }

    const updated = await this.repository.updateDetails(context.queue.id, changes);
    if (!updated) {
      throw queueNotFound();
    }

    return this.view({ ...context, queue: updated });
  }

  /**
   * Удаление очереди (US-34). Только администратор и только пустой: при наличии
   * хотя бы одной задачи в любом статусе — 409 (D-24). Каскадного удаления задач нет.
   */
  async remove(key: string, actor: AuthenticatedUser): Promise<void> {
    const context = await this.access.requireAdmin(key, actor);

    const result = await this.repository.delete(context.queue.id);
    if (result === 'not_empty') {
      throw new ConflictException({
        code: 'queue_not_empty',
        message: 'Сначала удалите задачи очереди',
      });
    }
    if (result === 'not_found') {
      throw new NotFoundException({ code: 'queue_not_found', message: 'Очередь не найдена' });
    }
  }

  private async view(context: QueueContext): Promise<QueueView> {
    return {
      queue: context.queue,
      projectSlug: context.projectSlug,
      projectName: context.projectName,
      role: context.role,
      openIssueCount: await this.repository.openIssueCount(context.queue.id),
    };
  }
}

function normalizeDescription(raw: string | null | undefined): string | null {
  if (raw === null || raw === undefined) {
    return null;
  }
  const value = raw.trim();
  return value.length > 0 ? value : null;
}
