import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import type { ProjectRole } from '../projects/index.js';
import { IssueKeyService } from './issue-key.service.js';
import { type IssueDetail, IssuesRepository } from './issues.repository.js';

/** Задача вместе с ролью того, кто её запросил. Роль здесь уже точно есть. */
export interface IssueContext {
  detail: IssueDetail;
  role: ProjectRole;
}

/** Права на задачу выводятся из роли в проекте (permissions.md, раздел 2.4). */
export interface IssuePermissions {
  /** Менять поля, описание, ссылки: администратор и участник, в том числе у чужой задачи (D-11). */
  canEdit: boolean;
  /** Удалять задачу: только администратор проекта (D-12). */
  canDelete: boolean;
}

export function issueNotFound(): NotFoundException {
  return new NotFoundException({ code: 'issue_not_found', message: 'Задача не найдена' });
}

export function permissionsFor(role: ProjectRole): IssuePermissions {
  return { canEdit: role !== 'reader', canDelete: role === 'admin' };
}

/**
 * Проверка доступа к задаче на уровне ресурса (permissions.md, разделы 2.4 и 5).
 *
 * Три отдельных исхода, и их нельзя смешивать:
 *  - задачи нет **или** пользователь не в проекте → 404, без единого поля задачи.
 *    Несуществующий ключ `DEV-9999` и чужая задача снаружи неотличимы (US-41);
 *  - задача видна, но роль не позволяет действие → 403 (читатель на изменении);
 *  - иначе действие разрешено.
 *
 * Права определяются ролью в проекте, а не авторством: участник меняет **любую**
 * задачу проекта (D-11). Исключение одно — удаление, оно только у администратора (D-12).
 */
@Injectable()
export class IssueAccessService {
  constructor(private readonly issues: IssuesRepository) {}

  /** Открыть задачу может любой участник проекта, включая читателя (US-41). */
  async require(rawKey: string, user: AuthenticatedUser): Promise<IssueContext> {
    const parsed = IssueKeyService.parse(rawKey);
    if (!parsed) {
      // Заведомо неправильный ключ снаружи неотличим от несуществующей задачи.
      throw issueNotFound();
    }

    const found = await this.issues.findByKeyForUser(parsed.key, user.id);
    if (!found || found.role === null) {
      throw issueNotFound();
    }

    return { detail: found.detail, role: found.role };
  }

  /** Изменение любого поля задачи: администратор и участник, читатель — 403. */
  async requireEditable(rawKey: string, user: AuthenticatedUser): Promise<IssueContext> {
    const context = await this.require(rawKey, user);
    if (!permissionsFor(context.role).canEdit) {
      throw new ForbiddenException({
        code: 'issue_forbidden',
        message: 'У вас нет прав изменять задачи этого проекта',
      });
    }
    return context;
  }

  /** Удаление задачи — только администратор проекта (D-12). */
  async requireDeletable(rawKey: string, user: AuthenticatedUser): Promise<IssueContext> {
    const context = await this.require(rawKey, user);
    if (!permissionsFor(context.role).canDelete) {
      throw new ForbiddenException({
        code: 'issue_forbidden',
        message: 'Удалить задачу может только администратор проекта',
      });
    }
    return context;
  }
}
