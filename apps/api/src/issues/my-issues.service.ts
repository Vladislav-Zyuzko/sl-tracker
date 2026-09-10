import { BadRequestException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import { type MyIssueRow, MyIssuesRepository } from './my-issues.repository.js';

/** Сайдбар обязан оставаться отзывчивым при 200+ задачах (US-81): страницами. */
export const MY_ISSUES_MAX_LIMIT = 100;
export const MY_ISSUES_DEFAULT_LIMIT = 50;

export interface MyIssuesPage {
  items: MyIssueRow[];
  nextCursor: string | null;
  /** Всего активных задач, подходящих под тот же поиск: это счётчик у заголовка списка. */
  total: number;
}

/**
 * Список активных задач пользователя и поиск по нему (US-81, US-82).
 *
 * Поиск серверный. Фильтровать этот список на клиенте запрещено (D-20): страница
 * отдаётся частями, и клиентский фильтр показал бы совпадения только из первой.
 */
@Injectable()
export class MyIssuesService {
  constructor(private readonly repository: MyIssuesRepository) {}

  async list(
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string; query?: string },
  ): Promise<MyIssuesPage> {
    const limit = clampLimit(options.limit, MY_ISSUES_DEFAULT_LIMIT, MY_ISSUES_MAX_LIMIT);
    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const query = options.query?.trim() ? options.query.trim() : undefined;
    const rows = await this.repository.list({
      userId: actor.id,
      limit: limit + 1,
      query,
      after: after ?? undefined,
    });

    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items,
      nextCursor:
        hasMore && last
          ? encodeCursor([String(last.priority), last.updatedAt.toISOString(), last.id])
          : null,
      total: await this.repository.count(actor.id, query),
    };
  }
}

function parseCursor(raw: string): { priority: number; updatedAt: Date; id: string } | null {
  const parts = decodeCursor(raw, 3);
  if (!parts) {
    return null;
  }
  const priority = Number(parts[0]);
  const updatedAt = new Date(parts[1]!);
  if (!Number.isInteger(priority) || Number.isNaN(updatedAt.getTime())) {
    return null;
  }
  return { priority, updatedAt, id: parts[2]! };
}
