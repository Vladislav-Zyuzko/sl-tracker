import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, ilike, or, sql } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import { DB, type Database } from '../database/index.js';
import { accessEntries, users } from '../database/schema/index.js';

export type AccessEntrySource = 'config' | 'manual' | 'invitation';

/** Строка списка доступа вместе с тем, кем оказался адрес и кто его добавил. */
export interface AccessEntryRow {
  id: string;
  email: string;
  source: AccessEntrySource;
  isInstanceOwner: boolean;
  createdAt: Date;
  firstLoginAt: Date | null;
  userId: string | null;
  userDisplayName: string | null;
  userAvatarUrl: string | null;
  addedByUserId: string | null;
  addedByDisplayName: string | null;
}

export interface ListOptions {
  limit: number;
  /** Курсор предыдущей страницы: `(created_at, id)` последней отданной записи. */
  after?: { createdAt: Date; id: string };
  /** Подстрока для поиска по email и имени вошедшего (US-07). */
  query?: string;
}

const owner = alias(users, 'owner_user');
const addedBy = alias(users, 'added_by_user');

const SELECTION = {
  id: accessEntries.id,
  email: accessEntries.email,
  source: accessEntries.source,
  isInstanceOwner: accessEntries.isInstanceOwner,
  createdAt: accessEntries.createdAt,
  firstLoginAt: accessEntries.firstLoginAt,
  userId: owner.id,
  userDisplayName: owner.displayName,
  userAvatarUrl: owner.avatarUrl,
  addedByUserId: addedBy.id,
  addedByDisplayName: addedBy.displayName,
};

/**
 * SQL списка доступа. Ни одной проверки прав и ни одного инварианта здесь нет —
 * они в сервисе; репозиторий только читает и пишет.
 */
@Injectable()
export class AccessListRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Страница списка: сначала новые (US-07), курсорная пагинация по паре
   * `(created_at, id)` — она устойчива к добавлению записей во время листания,
   * в отличие от OFFSET.
   */
  async list(options: ListOptions): Promise<AccessEntryRow[]> {
    const conditions = [];
    if (options.after) {
      // Колонки названы буквально: в сыром `sql` Drizzle рендерит их без имени
      // таблицы, а в запросе есть присоединённые `users` со своими `id` и
      // `created_at` — вышла бы неоднозначная ссылка на колонку.
      conditions.push(
        sql`(access_entries.created_at, access_entries.id) < (${options.after.createdAt}, ${options.after.id}::uuid)`,
      );
    }
    if (options.query) {
      const pattern = `%${escapeLike(options.query)}%`;
      conditions.push(or(ilike(accessEntries.email, pattern), ilike(owner.displayName, pattern)));
    }

    return this.db
      .select(SELECTION)
      .from(accessEntries)
      .leftJoin(owner, eq(owner.id, accessEntries.userId))
      .leftJoin(addedBy, eq(addedBy.id, accessEntries.addedByUserId))
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(accessEntries.createdAt), desc(accessEntries.id))
      .limit(options.limit);
  }

  async count(query?: string): Promise<number> {
    const pattern = query ? `%${escapeLike(query)}%` : null;
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(accessEntries)
      .leftJoin(owner, eq(owner.id, accessEntries.userId))
      .where(
        pattern
          ? or(ilike(accessEntries.email, pattern), ilike(owner.displayName, pattern))
          : undefined,
      );
    return row?.value ?? 0;
  }

  async findById(id: string): Promise<AccessEntryRow | null> {
    const [row] = await this.db
      .select(SELECTION)
      .from(accessEntries)
      .leftJoin(owner, eq(owner.id, accessEntries.userId))
      .leftJoin(addedBy, eq(addedBy.id, accessEntries.addedByUserId))
      .where(eq(accessEntries.id, id))
      .limit(1);
    return row ?? null;
  }

  /** Поиск по адресу без учёта регистра — используется проверкой входа. */
  async existsByEmail(email: string): Promise<boolean> {
    const [row] = await this.db
      .select({ id: accessEntries.id })
      .from(accessEntries)
      .where(sql`lower(access_entries.email) = ${email}`)
      .limit(1);
    return row !== undefined;
  }

  /** `null` — такой адрес уже есть (сработал уникальный индекс по `lower(email)`). */
  async insertManual(email: string, addedByUserId: string): Promise<AccessEntryRow | null> {
    const [inserted] = await this.db
      .insert(accessEntries)
      .values({ email, source: 'manual', isInstanceOwner: false, addedByUserId })
      .onConflictDoNothing()
      .returning({ id: accessEntries.id });

    return inserted ? await this.findById(inserted.id) : null;
  }

  /**
   * Начальное наполнение из конфигурации (ADR-0006, п. 2). Идемпотентно: повторный
   * запуск не создаёт дубликатов и **не трогает** уже существующие записи — иначе
   * перезапуск возвращал бы отозванный признак владельца.
   */
  async insertBootstrap(emails: string[]): Promise<number> {
    if (emails.length === 0) {
      return 0;
    }

    const inserted = await this.db
      .insert(accessEntries)
      .values(emails.map((email) => ({ email, source: 'config' as const, isInstanceOwner: true })))
      .onConflictDoNothing()
      .returning({ id: accessEntries.id });

    return inserted.length;
  }

  async delete(id: string): Promise<boolean> {
    const deleted = await this.db
      .delete(accessEntries)
      .where(eq(accessEntries.id, id))
      .returning({ id: accessEntries.id });
    return deleted.length > 0;
  }

  async setInstanceOwner(id: string, value: boolean): Promise<AccessEntryRow | null> {
    const updated = await this.db
      .update(accessEntries)
      .set({ isInstanceOwner: value })
      .where(eq(accessEntries.id, id))
      .returning({ id: accessEntries.id });
    return updated.length > 0 ? await this.findById(id) : null;
  }

  async countOwners(): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(accessEntries)
      .where(eq(accessEntries.isInstanceOwner, true));
    return row?.value ?? 0;
  }

  /**
   * Кого гасить при отзыве доступа. Ищем и по связке `user_id`, и по адресу:
   * связка проставляется при входе, а человек мог войти по приглашению, когда записи
   * ещё не было.
   */
  async findUserIdsForEntry(entry: AccessEntryRow): Promise<string[]> {
    const rows = await this.db
      .select({ id: users.id })
      .from(users)
      .where(sql`lower(users.email) = ${entry.email.toLowerCase()}`);

    const ids = new Set(rows.map((row) => row.id));
    if (entry.userId) {
      ids.add(entry.userId);
    }
    return [...ids];
  }
}

/** `%` и `_` в пользовательском вводе не должны становиться шаблоном LIKE. */
function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, (match) => `\\${match}`);
}
