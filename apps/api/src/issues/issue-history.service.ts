import { BadRequestException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import { IssueAccessService } from './issue-access.service.js';
import { type HistoryGroupRow, IssueHistoryRepository } from './issue-history.repository.js';

/** Длинная история подгружается порциями и не тормозит страницу задачи (US-90). */
export const HISTORY_DEFAULT_LIMIT = 25;
export const HISTORY_MAX_LIMIT = 100;

export interface HistoryPage {
  items: HistoryGroupRow[];
  nextCursor: string | null;
  /** Сколько всего действий по задаче. Минимум одно — «Задача создана». */
  total: number;
}

/**
 * История задачи (US-90 … US-92).
 *
 * Читать её может **любой участник проекта, включая читателя**: история — способ
 * разобрать спор по фактам, и закрывать её от кого-то из команды бессмысленно.
 * Записывать и удалять её не может никто, включая администратора, поэтому здесь
 * только чтение.
 */
@Injectable()
export class IssueHistoryService {
  constructor(
    private readonly repository: IssueHistoryRepository,
    private readonly access: IssueAccessService,
  ) {}

  async list(
    issueKey: string,
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<HistoryPage> {
    const context = await this.access.require(issueKey, actor);
    const limit = clampLimit(options.limit, HISTORY_DEFAULT_LIMIT, HISTORY_MAX_LIMIT);

    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const groups = await this.repository.page({
      issueId: context.detail.issue.id,
      limit: limit + 1,
      after: after ?? undefined,
    });

    const hasMore = groups.length > limit;
    const items = hasMore ? groups.slice(0, limit) : groups;
    const last = items.at(-1);

    return {
      items,
      nextCursor:
        hasMore && last ? encodeCursor([last.createdAt.toISOString(), last.groupId]) : null,
      total: await this.repository.countGroups(context.detail.issue.id),
    };
  }
}

function parseCursor(raw: string): { createdAt: Date; groupId: string } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const createdAt = new Date(parts[0]!);
  if (Number.isNaN(createdAt.getTime())) {
    return null;
  }
  return { createdAt, groupId: parts[1]! };
}
