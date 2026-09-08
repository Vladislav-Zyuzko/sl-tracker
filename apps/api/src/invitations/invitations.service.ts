import {
  BadRequestException,
  GoneException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor, normalizeEmail } from '../common/index.js';
import { ENV, type Env } from '../config/index.js';
import { ProjectAccessService, type ProjectRole } from '../projects/index.js';
import { ObjectStorageService } from '../storage/index.js';
import {
  type InvitationLifetimeDays,
  type InvitationState,
  expiryFrom,
  invitationState,
} from './invitation-state.js';
import {
  type InvitableRole,
  type InvitationRow,
  InvitationsRepository,
} from './invitations.repository.js';

export const INVITATIONS_MAX_LIMIT = 100;
export const INVITATIONS_DEFAULT_LIMIT = 50;

export interface InvitationView {
  row: InvitationRow;
  state: InvitationState;
  /** Полная ссылка — только у действующего приглашения (US-22). */
  url: string | null;
}

export interface InvitationsPage {
  items: InvitationView[];
  nextCursor: string | null;
  total: number;
}

/** Что показывает экран подтверждения: ни задач, ни участников (US-21). */
export interface InvitationPreview {
  projectName: string;
  projectSlug: string;
  coverUrl: string | null;
  role: ProjectRole;
  alreadyMember: boolean;
}

export interface AcceptResult {
  projectSlug: string;
  role: ProjectRole;
  alreadyMember: boolean;
}

/**
 * Приглашения в проект (US-20 … US-22) — единственный способ добавить человека
 * в проект (D-03).
 *
 * Создание, просмотр и отзыв доступны только администратору проекта; приём —
 * любому вошедшему, **в том числе тому, кого нет в списке доступа**: ссылка работает
 * в обход списка и при приёме его пополняет (ADR-0006, п. 3).
 */
@Injectable()
export class InvitationsService {
  private readonly logger = new Logger(InvitationsService.name);
  private readonly appBaseUrl: string;

  constructor(
    private readonly repository: InvitationsRepository,
    private readonly access: ProjectAccessService,
    private readonly storage: ObjectStorageService,
    @Inject(ENV) env: Env,
  ) {
    this.appBaseUrl = env.APP_BASE_URL.replace(/\/$/, '');
  }

  async create(
    slug: string,
    input: { role: InvitableRole; expiresInDays: InvitationLifetimeDays },
    actor: AuthenticatedUser,
  ): Promise<InvitationView> {
    const context = await this.access.requireAdmin(slug, actor);

    const created = await this.repository.create({
      projectId: context.project.id,
      role: input.role,
      expiresAt: expiryFrom(input.expiresInDays),
      createdByUserId: actor.id,
    });

    // В лог — факт и проект, но не токен: он даёт членство в проекте.
    this.logger.log(`Создано приглашение в проект ${context.project.id}, роль ${input.role}`);
    return this.view(created);
  }

  /** Список приглашений проекта, только администратору (US-22). */
  async list(
    slug: string,
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<InvitationsPage> {
    const context = await this.access.requireAdmin(slug, actor);
    const limit = clampLimit(options.limit, INVITATIONS_DEFAULT_LIMIT, INVITATIONS_MAX_LIMIT);
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
      items: items.map((row) => this.view(row)),
      nextCursor: hasMore && last ? encodeCursor([last.createdAt.toISOString(), last.id]) : null,
      total: await this.repository.count(context.project.id),
    };
  }

  /**
   * Отзыв (US-22). Отозвать может любой администратор проекта, в том числе не тот,
   * кто создавал ссылку. Уже вступившие остаются участниками.
   */
  async revoke(slug: string, id: string, actor: AuthenticatedUser): Promise<InvitationView> {
    const context = await this.access.requireAdmin(slug, actor);

    const revoked = await this.repository.revoke(context.project.id, id, actor.id);
    if (!revoked) {
      throw new NotFoundException({
        code: 'invitation_not_found',
        message: 'Приглашение не найдено',
      });
    }

    return this.view(revoked);
  }

  /**
   * Экран подтверждения (US-21). Показывает только название, обложку и роль —
   * ни задач, ни участников, ни имени пригласившего.
   *
   * Неизвестный токен — 404, истёкший или отозванный — 410. По сообщению нельзя
   * понять, существует ли такой проект.
   */
  async preview(token: string, actor: AuthenticatedUser): Promise<InvitationPreview> {
    const found = await this.repository.findByToken(token, actor.id);
    if (!found) {
      throw new NotFoundException({
        code: 'invitation_not_found',
        message: 'Приглашение не найдено',
      });
    }

    const alreadyMember = found.currentRole !== null;
    if (!alreadyMember && invitationState(found.invitation) !== 'active') {
      throw new GoneException({
        code: 'invitation_inactive',
        message: 'Приглашение больше не действует',
      });
    }

    return {
      projectName: found.project.name,
      projectSlug: found.project.slug,
      coverUrl: found.project.coverObjectKey
        ? await this.storage.signedUrl(found.project.coverObjectKey)
        : null,
      role: found.currentRole ?? found.invitation.role,
      alreadyMember,
    };
  }

  /**
   * Вступление в проект (US-21).
   *
   * Пользователь, уже состоящий в проекте, просто попадает в проект: его роль
   * не меняется и не понижается. Вместе с членством появляется запись списка доступа
   * с источником `invitation` — со следующего входа ссылка ему уже не нужна.
   */
  async accept(token: string, actor: AuthenticatedUser): Promise<AcceptResult> {
    const result = await this.repository.accept({
      token,
      userId: actor.id,
      email: normalizeEmail(actor.email),
    });

    switch (result.outcome) {
      case 'not_found':
        throw new NotFoundException({
          code: 'invitation_not_found',
          message: 'Приглашение не найдено',
        });
      case 'unusable':
        throw new GoneException({
          code: 'invitation_inactive',
          message: 'Приглашение больше не действует',
        });
      case 'already_member':
        return { projectSlug: result.slug, role: result.role, alreadyMember: true };
      case 'joined':
        this.logger.log(`Пользователь ${actor.id} вступил в проект ${result.projectId}`);
        return { projectSlug: result.slug, role: result.role, alreadyMember: false };
    }
  }

  private view(row: InvitationRow): InvitationView {
    const state = invitationState(row);
    return {
      row,
      state,
      // Ссылку отдаём только у действующего приглашения: истёкшее и отозванное
      // повторно активировать нельзя, и кнопки «Скопировать» у них нет (US-22).
      url: state === 'active' ? `${this.appBaseUrl}/invite/${row.token}` : null,
    };
  }
}

function parseCursor(raw: string): { createdAt: Date; id: string } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const createdAt = new Date(parts[0]!);
  return Number.isNaN(createdAt.getTime()) ? null : { createdAt, id: parts[1]! };
}
