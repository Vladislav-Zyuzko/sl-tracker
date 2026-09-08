import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import { IssueAccessService } from '../issues/index.js';
import type { IssueContext } from '../issues/index.js';
import type { IssueEventRef } from '../notifications/index.js';
import { COMMENT_BODY_MAX_LENGTH, normalizeCommentBody } from './comment-body.js';
import { type CommentRow, CommentsRepository } from './comments.repository.js';

/** Лента подгружается порциями; потолок жёсткий (US-70). */
export const COMMENTS_DEFAULT_LIMIT = 50;
export const COMMENTS_MAX_LIMIT = 100;

export interface CommentsPage {
  items: CommentRow[];
  /** Курсор **более ранних** комментариев: лента читается снизу вверх. */
  nextCursor: string | null;
  total: number;
  context: IssueContext;
}

export interface CommentView {
  comment: CommentRow;
  context: IssueContext;
}

/** Что запросившему разрешено с конкретным комментарием (permissions.md, раздел 2.5). */
export interface CommentPermissions {
  /** Только автор — администратор чужой текст не правит. */
  canEdit: boolean;
  /** Автор — свой, администратор проекта — любой. */
  canDelete: boolean;
}

export function commentPermissionsFor(
  comment: { author: { id: string } },
  context: { role: string; actorId: string },
): CommentPermissions {
  const isAuthor = comment.author.id === context.actorId;
  return { canEdit: isAuthor, canDelete: isAuthor || context.role === 'admin' };
}

/**
 * Комментарии к задаче (US-70 … US-73).
 *
 * Права здесь несимметричны, и это намеренно (permissions.md, раздел 2.5):
 *  - **читать** может любой участник проекта, включая читателя;
 *  - **писать** — администратор и участник; читатель получает 403 (D-29);
 *  - **править** — только автор, и никто больше: чужой текст не правит даже
 *    администратор, потому что подмена чужих слов разрушает доверие к обсуждению;
 *  - **удалять** — автор свой, администратор проекта — любой (модерация), и факт
 *    удаления попадает в историю задачи.
 */
@Injectable()
export class CommentsService {
  constructor(
    private readonly repository: CommentsRepository,
    private readonly access: IssueAccessService,
  ) {}

  /** Лента комментариев (US-70). Видна всем участникам проекта, включая читателя. */
  async list(
    issueKey: string,
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<CommentsPage> {
    const context = await this.access.require(issueKey, actor);
    const limit = clampLimit(options.limit, COMMENTS_DEFAULT_LIMIT, COMMENTS_MAX_LIMIT);

    const before = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !before) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const rows = await this.repository.page({
      issueId: context.detail.issue.id,
      limit: limit + 1,
      before: before ?? undefined,
    });

    const hasMore = rows.length > limit;
    // Выбрано с конца, а отдаётся в хронологическом порядке — сначала старые (US-70).
    const page = (hasMore ? rows.slice(0, limit) : rows).reverse();
    const oldest = page.at(0);

    return {
      items: page,
      nextCursor:
        hasMore && oldest ? encodeCursor([oldest.createdAt.toISOString(), oldest.id]) : null,
      total: await this.repository.count(context.detail.issue.id),
      context,
    };
  }

  /** Написание комментария (US-71). Администратор и участник; читатель — 403. */
  async create(issueKey: string, body: string, actor: AuthenticatedUser): Promise<CommentView> {
    const context = await this.access.require(issueKey, actor);
    assertCanWrite(context);

    const text = normalizeCommentBody(body);
    if (text === null) {
      throw invalidBody();
    }

    const comment = await this.repository.create({
      issue: issueRefOf(context),
      authorId: actor.id,
      body: text,
    });

    return { comment, context };
  }

  /**
   * Правка комментария (US-72). Только автор — администратор чужой текст не правит,
   * и это 403, а не 404: комментарий он видит, просто не может его менять.
   */
  async update(
    issueKey: string,
    commentId: string,
    body: string,
    actor: AuthenticatedUser,
  ): Promise<CommentView> {
    const context = await this.access.require(issueKey, actor);
    const existing = await this.requireComment(context, commentId);

    if (existing.authorId !== actor.id) {
      throw new ForbiddenException({
        code: 'comment_forbidden',
        message: 'Редактировать можно только свой комментарий',
      });
    }
    // Читатель своих комментариев не имеет, но роль могли понизить уже после того,
    // как он их написал: писать он больше не должен ничего.
    assertCanWrite(context);

    const text = normalizeCommentBody(body);
    if (text === null) {
      throw invalidBody();
    }

    const comment = await this.repository.update({
      commentId,
      issue: issueRefOf(context),
      actorId: actor.id,
      body: text,
    });

    if (!comment) {
      throw commentNotFound();
    }

    return { comment, context };
  }

  /** Удаление (US-73). Свой — автор, чужой — только администратор проекта. */
  async remove(issueKey: string, commentId: string, actor: AuthenticatedUser): Promise<void> {
    const context = await this.access.require(issueKey, actor);
    const existing = await this.requireComment(context, commentId);

    if (existing.authorId !== actor.id && context.role !== 'admin') {
      throw new ForbiddenException({
        code: 'comment_forbidden',
        message: 'Удалить чужой комментарий может только администратор проекта',
      });
    }

    const deleted = await this.repository.delete({
      commentId,
      issueId: context.detail.issue.id,
      actorId: actor.id,
    });

    if (!deleted) {
      throw commentNotFound();
    }
  }

  private async requireComment(
    context: IssueContext,
    commentId: string,
  ): Promise<{ id: string; authorId: string }> {
    const existing = await this.repository.findById(context.detail.issue.id, commentId);
    if (!existing) {
      throw commentNotFound();
    }
    return existing;
  }
}

/** Читатель не создаёт текстов — ни комментариев, ни упоминаний (D-29). */
function assertCanWrite(context: IssueContext): void {
  if (context.role === 'reader') {
    throw new ForbiddenException({
      code: 'comment_forbidden',
      message: 'У вас нет прав комментировать задачи этого проекта',
    });
  }
}

function issueRefOf(context: IssueContext): IssueEventRef {
  return {
    id: context.detail.issue.id,
    key: context.detail.issue.key,
    title: context.detail.issue.title,
    projectId: context.detail.projectId,
  };
}

function commentNotFound(): NotFoundException {
  return new NotFoundException({ code: 'comment_not_found', message: 'Комментарий не найден' });
}

function invalidBody(): BadRequestException {
  return new BadRequestException({
    code: 'invalid_comment_body',
    message: `Комментарий не может быть пустым и длиннее ${COMMENT_BODY_MAX_LENGTH} символов`,
  });
}

/** Курсор ленты: время и идентификатор самого раннего показанного комментария. */
function parseCursor(raw: string): { createdAt: Date; id: string } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const createdAt = new Date(parts[0]!);
  return Number.isNaN(createdAt.getTime()) ? null : { createdAt, id: parts[1]! };
}
