import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { type ProjectRole, type ProjectRow, ProjectsRepository } from './projects.repository.js';

/** Проект вместе с ролью того, кто его запросил. Роль здесь уже точно есть. */
export interface ProjectContext {
  project: ProjectRow;
  role: ProjectRole;
  memberCount: number;
  /** `false` — запрос пришёл по прежнему короткому имени (US-18). */
  slugIsCurrent: boolean;
}

/**
 * Проверка доступа к проекту на уровне ресурса, а не по глобальной роли
 * (permissions.md, п. 1 и п. 6). Каждый эндпоинт проекта начинается отсюда.
 *
 * Чужой проект и несуществующий проект отвечают **одинаково** — 404: не-участник
 * не должен узнать даже о существовании проекта (permissions.md, п. 5). 403 остаётся
 * для случая, когда объект человеку виден, но действие ему не разрешено ролью.
 *
 * Владелец трекера здесь не привилегирован: глобальная роль не даёт прав внутри
 * проектов (permissions.md, п. 1.2).
 */
@Injectable()
export class ProjectAccessService {
  constructor(private readonly projects: ProjectsRepository) {}

  async require(slug: string, user: AuthenticatedUser): Promise<ProjectContext> {
    const found = await this.projects.findBySlugForUser(slug, user.id);
    if (!found || found.role === null) {
      throw new NotFoundException({ code: 'project_not_found', message: 'Проект не найден' });
    }

    return {
      project: found.project,
      role: found.role,
      memberCount: found.memberCount,
      slugIsCurrent: found.slugIsCurrent,
    };
  }

  /** Настройки проекта, участники, приглашения, удаление — только администратору. */
  async requireAdmin(slug: string, user: AuthenticatedUser): Promise<ProjectContext> {
    const context = await this.require(slug, user);
    if (context.role !== 'admin') {
      throw new ForbiddenException({
        code: 'project_forbidden',
        message: 'Действие доступно только администратору проекта',
      });
    }
    return context;
  }
}
