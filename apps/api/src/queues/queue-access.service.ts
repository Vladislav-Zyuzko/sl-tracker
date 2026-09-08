import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { IssueKeyService } from '../issues/issue-key.service.js';
import type { ProjectRole } from '../projects/index.js';
import { type QueueRow, QueuesRepository } from './queues.repository.js';

/** Очередь вместе с ролью того, кто её запросил. Роль здесь уже точно есть. */
export interface QueueContext {
  queue: QueueRow;
  projectSlug: string;
  projectName: string;
  role: ProjectRole;
}

/** Ошибка «очередь не найдена» — одна на весь домен, чтобы текст не разъезжался. */
export function queueNotFound(): NotFoundException {
  return new NotFoundException({ code: 'queue_not_found', message: 'Очередь не найдена' });
}

/**
 * Проверка доступа к очереди на уровне ресурса (permissions.md, разделы 2.3 и 5).
 *
 * Права на очередь наследуются от роли в проекте: прав уровня очереди в MVP нет
 * (permissions.md, п. 3). Не-участник получает **404**, а не 403: он не должен
 * узнать даже о существовании очереди и, через неё, чужого проекта (п. 5).
 * 403 остаётся для случая, когда очередь человеку видна, но действие не разрешено
 * его ролью.
 */
@Injectable()
export class QueueAccessService {
  constructor(private readonly queues: QueuesRepository) {}

  /** Любая роль в проекте, включая читателя: открыть очередь и её задачи (US-31, US-32). */
  async require(rawKey: string, user: AuthenticatedUser): Promise<QueueContext> {
    // Ключ в адресе регистронезависим, как и ключ задачи (ADR-0004).
    const key = IssueKeyService.normalizeQueueKey(rawKey);
    if (!key) {
      // Несуществующий и заведомо неправильный ключ снаружи неотличимы.
      throw queueNotFound();
    }

    const found = await this.queues.findByKeyForUser(key, user.id);
    if (!found || found.role === null) {
      throw queueNotFound();
    }

    return {
      queue: found.queue,
      projectSlug: found.projectSlug,
      projectName: found.projectName,
      role: found.role,
    };
  }

  /** Переименование и удаление очереди — только администратору проекта (US-33, US-34). */
  async requireAdmin(rawKey: string, user: AuthenticatedUser): Promise<QueueContext> {
    const context = await this.require(rawKey, user);
    if (context.role !== 'admin') {
      throw new ForbiddenException({
        code: 'project_forbidden',
        message: 'Действие доступно только администратору проекта',
      });
    }
    return context;
  }
}
