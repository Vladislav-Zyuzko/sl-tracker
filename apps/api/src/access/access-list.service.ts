import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { normalizeEmail, toStorableEmail } from '../common/index.js';
import { SessionService } from '../sessions/index.js';
import type { AuthenticatedUser } from '../auth/auth.types.js';
import { type AccessEntryRow, AccessListRepository } from './access-list.repository.js';

/** Жёсткий максимум страницы: список административный, тысяч записей в нём не бывает. */
export const ACCESS_LIST_MAX_LIMIT = 100;
export const ACCESS_LIST_DEFAULT_LIMIT = 50;

export interface AccessListPage {
  items: AccessEntryRow[];
  /** Курсор следующей страницы или `null`, если записей больше нет. */
  nextCursor: string | null;
  total: number;
}

/**
 * Список доступа — уровень 0 (ADR-0006, permissions.md, п. 1.1).
 *
 * Здесь живут инварианты, и они серверные: скрытый пункт меню на клиенте защитой
 * не является (permissions.md, п. 1.6).
 *
 *   - адрес нормализуется к нижнему регистру, повторное добавление — 409;
 *   - свою запись удалить нельзя;
 *   - снять признак с последнего владельца или удалить его запись нельзя;
 *   - удаление записи **гасит все сессии** этого человека (US-09) — иначе отзыв
 *     доступа работает только до истечения куки.
 *
 * Email — персональные данные: в логи он не пишется (ADR-0006, «Последствия»).
 */
@Injectable()
export class AccessListService {
  private readonly logger = new Logger(AccessListService.name);

  constructor(
    private readonly repository: AccessListRepository,
    private readonly sessions: SessionService,
  ) {}

  /** Пускать ли этот адрес в трекер. Приглашение проверяется отдельно и в обход списка. */
  async isEmailAllowed(email: string): Promise<boolean> {
    return this.repository.existsByEmail(normalizeEmail(email));
  }

  async list(options: {
    limit?: number;
    cursor?: string;
    query?: string;
  }): Promise<AccessListPage> {
    const limit = clampLimit(options.limit);
    const after = options.cursor ? decodeCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const query = options.query?.trim() ? options.query.trim() : undefined;
    // Запрашиваем на одну запись больше страницы: так видно, есть ли следующая,
    // без отдельного запроса.
    const rows = await this.repository.list({ limit: limit + 1, after: after ?? undefined, query });
    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items,
      nextCursor: hasMore && last ? encodeCursor(last.createdAt, last.id) : null,
      total: await this.repository.count(query),
    };
  }

  /** Добавление вручную (US-07): источник `manual`, признак владельца не выдаётся. */
  async add(rawEmail: string, actor: AuthenticatedUser): Promise<AccessEntryRow> {
    const email = toStorableEmail(rawEmail);
    if (!email) {
      throw new BadRequestException({ code: 'invalid_email', message: 'Некорректный адрес' });
    }

    const created = await this.repository.insertManual(email, actor.id);
    if (!created) {
      throw new ConflictException({
        code: 'access_entry_exists',
        message: 'Этот адрес уже в списке',
      });
    }

    return created;
  }

  /**
   * Отзыв доступа (US-09). Возвращает число погашенных сессий — это и есть
   * проверяемая часть требования «человека выбрасывает немедленно».
   */
  async remove(id: string, actor: AuthenticatedUser): Promise<{ revokedSessions: number }> {
    const entry = await this.requireEntry(id);

    if (isOwnEntry(entry, actor)) {
      throw new ConflictException({
        code: 'cannot_revoke_self',
        message: 'Нельзя удалить собственный доступ',
      });
    }

    if (entry.isInstanceOwner && (await this.repository.countOwners()) <= 1) {
      throw new ConflictException({
        code: 'last_instance_owner',
        message: 'В трекере должен остаться хотя бы один владелец',
      });
    }

    const userIds = await this.repository.findUserIdsForEntry(entry);
    const deleted = await this.repository.delete(id);
    if (!deleted) {
      throw new NotFoundException({
        code: 'access_entry_not_found',
        message: 'Запись не найдена',
      });
    }

    let revokedSessions = 0;
    for (const userId of userIds) {
      revokedSessions += await this.sessions.destroyAllForUser(userId);
    }

    // В лог — только счётчики: email из списка доступа в логи не попадает.
    this.logger.log(`Доступ отозван: погашено сессий ${revokedSessions}`);
    return { revokedSessions };
  }

  /** Выдача и снятие признака владельца трекера (US-07). */
  async setInstanceOwner(id: string, value: boolean): Promise<AccessEntryRow> {
    const entry = await this.requireEntry(id);

    if (entry.isInstanceOwner === value) {
      return entry;
    }

    // Снять признак с себя можно — но только если владелец в трекере не один.
    if (!value && (await this.repository.countOwners()) <= 1) {
      throw new ConflictException({
        code: 'last_instance_owner',
        message: 'В трекере должен остаться хотя бы один владелец',
      });
    }

    const updated = await this.repository.setInstanceOwner(id, value);
    if (!updated) {
      throw new NotFoundException({
        code: 'access_entry_not_found',
        message: 'Запись не найдена',
      });
    }

    return updated;
  }

  private async requireEntry(id: string): Promise<AccessEntryRow> {
    const entry = await this.repository.findById(id);
    if (!entry) {
      throw new NotFoundException({
        code: 'access_entry_not_found',
        message: 'Запись не найдена',
      });
    }
    return entry;
  }
}

/** Своя запись текущего пользователя: у неё фронт скрывает «Удалить» (US-07). */
export function isOwnEntry(entry: AccessEntryRow, actor: AuthenticatedUser): boolean {
  return entry.userId === actor.id || entry.email.toLowerCase() === normalizeEmail(actor.email);
}

function clampLimit(raw: number | undefined): number {
  if (raw === undefined || !Number.isFinite(raw)) {
    return ACCESS_LIST_DEFAULT_LIMIT;
  }
  return Math.min(Math.max(Math.trunc(raw), 1), ACCESS_LIST_MAX_LIMIT);
}

export function encodeCursor(createdAt: Date, id: string): string {
  return Buffer.from(`${createdAt.toISOString()}|${id}`, 'utf8').toString('base64url');
}

export function decodeCursor(raw: string): { createdAt: Date; id: string } | null {
  try {
    const decoded = Buffer.from(raw, 'base64url').toString('utf8');
    const separator = decoded.indexOf('|');
    if (separator < 0) {
      return null;
    }
    const createdAt = new Date(decoded.slice(0, separator));
    const id = decoded.slice(separator + 1);
    if (Number.isNaN(createdAt.getTime()) || id.length === 0) {
      return null;
    }
    return { createdAt, id };
  } catch {
    return null;
  }
}
