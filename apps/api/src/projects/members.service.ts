import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
// Конкретные файлы, а не бочка realtime: та тянет gateway, который сам зависит
// от домена проектов, — получился бы цикл модулей.
import { projectTopic } from '../realtime/realtime.events.js';
import { RealtimePublisher } from '../realtime/realtime.publisher.js';
import { type MemberRow, MembersRepository } from './members.repository.js';
import { ProjectAccessService } from './project-access.service.js';
import type { ProjectRole } from './projects.repository.js';

/** Участников в проекте 3–15 (US-14), но потолок страницы всё равно жёсткий. */
export const MEMBERS_MAX_LIMIT = 100;
export const MEMBERS_DEFAULT_LIMIT = 50;

export interface MembersPage {
  items: MemberRow[];
  nextCursor: string | null;
  total: number;
}

/**
 * Участники проекта и их роли (US-14 … US-16).
 *
 * Главный инвариант: **в проекте всегда есть хотя бы один администратор**
 * (permissions.md, п. 7). Последнего администратора нельзя ни разжаловать,
 * ни исключить, ни выпустить по собственному желанию — все три пути проверяются
 * здесь, а не в трёх местах контроллера.
 */
@Injectable()
export class MembersService {
  constructor(
    private readonly repository: MembersRepository,
    private readonly access: ProjectAccessService,
    private readonly realtime: RealtimePublisher,
  ) {}

  /** Список участников виден всем участникам проекта, включая читателя (US-14). */
  async list(
    slug: string,
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<MembersPage> {
    const context = await this.access.require(slug, actor);
    const limit = clampLimit(options.limit, MEMBERS_DEFAULT_LIMIT, MEMBERS_MAX_LIMIT);
    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const rows = await this.repository.list({
      projectId: context.project.id,
      limit: limit + 1,
      after: after ?? undefined,
    });
    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items,
      nextCursor:
        hasMore && last
          ? encodeCursor([String(last.role === 'admin' ? 0 : 1), last.userId, last.displayName])
          : null,
      total: await this.repository.count(context.project.id),
    };
  }

  /**
   * Смена роли участника (US-15). Только администратор; себя понизить можно,
   * если администратор в проекте не один.
   */
  async changeRole(
    slug: string,
    userId: string,
    role: ProjectRole,
    actor: AuthenticatedUser,
  ): Promise<MemberRow> {
    const context = await this.access.requireAdmin(slug, actor);
    const member = await this.requireMember(context.project.id, userId);

    if (member.role === role) {
      return member;
    }

    if (member.role === 'admin' && (await this.repository.countAdmins(context.project.id)) <= 1) {
      throw new ConflictException({
        code: 'last_project_admin',
        message: 'В проекте должен остаться хотя бы один администратор',
      });
    }

    const updated = await this.repository.updateRole(context.project.id, userId, role);
    if (!updated) {
      throw new NotFoundException({ code: 'member_not_found', message: 'Участник не найден' });
    }

    await this.announce(context.project.id, 'project.member_updated', actor.id, { userId, role });
    return { ...member, role };
  }

  /**
   * Исключение участника администратором и самостоятельный выход (US-16) — одно
   * действие: разница только в том, кого удаляют.
   *
   * Выйти сам может любой участник; исключить другого — только администратор.
   * Последний администратор не уходит ни тем, ни другим путём.
   */
  async remove(
    slug: string,
    userId: string,
    actor: AuthenticatedUser,
  ): Promise<{ unassignedIssues: number }> {
    const isSelf = userId === actor.id;
    const context = isSelf
      ? await this.access.require(slug, actor)
      : await this.access.requireAdmin(slug, actor);

    const member = await this.requireMember(context.project.id, userId);

    if (member.role === 'admin' && (await this.repository.countAdmins(context.project.id)) <= 1) {
      throw new ConflictException({
        code: 'last_project_admin',
        message: 'В проекте должен остаться хотя бы один администратор',
      });
    }

    const result = await this.repository.remove(context.project.id, userId);
    if (!result.removed) {
      throw new NotFoundException({ code: 'member_not_found', message: 'Участник не найден' });
    }

    await this.announce(context.project.id, 'project.member_removed', actor.id, { userId });
    return { unassignedIssues: result.unassignedIssues };
  }

  /**
   * Живое обновление списка участников (US-15, US-16).
   *
   * Публикуется после того, как репозиторий вернул управление, — то есть после
   * фиксации транзакции. Имена полей те же, что в `ProjectMemberDto`: `userId`, `role`.
   *
   * Самому исключённому это событие не придёт, и не должно: право проверяется ещё раз
   * при рассылке, а он уже не участник. О том, что его исключили, он узнаёт обычным
   * запросом — тот вернёт 404 на проект.
   */
  private async announce(
    projectId: string,
    event: 'project.member_updated' | 'project.member_removed',
    actorId: string,
    data: Record<string, unknown>,
  ): Promise<void> {
    await this.realtime.publish([
      { topic: projectTopic(projectId), event, projectId, actorId, data },
    ]);
  }

  private async requireMember(projectId: string, userId: string): Promise<MemberRow> {
    const member = await this.repository.find(projectId, userId);
    if (!member) {
      // Человека нет в проекте — для действующего участника это обычный 404 по ресурсу
      // внутри видимого ему проекта, а не сокрытие самого проекта.
      throw new NotFoundException({ code: 'member_not_found', message: 'Участник не найден' });
    }
    return member;
  }
}

/** Свободный текст (имя) в курсоре идёт последним — см. `decodeCursor`. */
function parseCursor(
  raw: string,
): { roleRank: number; userId: string; displayName: string } | null {
  const parts = decodeCursor(raw, 3);
  if (!parts) {
    return null;
  }
  const roleRank = Number(parts[0]);
  if (!Number.isInteger(roleRank)) {
    return null;
  }
  return { roleRank, userId: parts[1]!, displayName: parts[2]! };
}
