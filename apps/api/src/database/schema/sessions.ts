import { sql } from 'drizzle-orm';
import { char, index, pgTable, uniqueIndex, uuid } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz } from './_shared.js';
import { sessionKindEnum } from './enums.js';
import { users } from './users.js';

/**
 * Серверная сессия.
 *
 * Быстрый путь проверки — Redis (см. `src/redis/session-keys.ts`); эта таблица —
 * долговременная запись, переживающая перезапуск и очистку кэша, и единственное место,
 * где можно перечислить сессии пользователя, если Redis потерял данные.
 *
 * Ключевое требование ADR-0006: отзыв доступа обязан немедленно погасить **все** сессии
 * человека. Поэтому сессии всегда находятся по `user_id` — и в Redis (множество
 * `sl:sessions:by-user:<userId>`), и здесь (индекс по `user_id`).
 *
 * Самого токена сессии тут нет: хранится только SHA-256 от него. Утечка дампа БД
 * не даёт возможности предъявить чужую сессию.
 */
export const sessions = pgTable(
  'sessions',
  {
    id: primaryId(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    /** cookie для веба, bearer для будущей мобилки. Доменный код разницы не видит. */
    kind: sessionKindEnum('kind').notNull(),
    /** SHA-256 от секрета сессии в hex. Сам секрет не хранится нигде. */
    tokenHash: char('token_hash', { length: 64 }).notNull(),
    /** Сессия живёт не меньше 30 дней при периодическом использовании (US-02). */
    expiresAt: tstz('expires_at').notNull(),
    lastSeenAt: tstz('last_seen_at').notNull().defaultNow(),
    /** Проставляется при выходе и при отзыве доступа (US-03, US-09). */
    revokedAt: tstz('revoked_at'),
    createdAt: createdAt(),
  },
  (t) => [
    uniqueIndex('sessions_token_hash_key').on(t.tokenHash),
    // Отзыв доступа: погасить все сессии пользователя одним запросом (ADR-0006).
    index('sessions_user_id_idx').on(t.userId),
    // Фоновая уборка протухших сессий.
    index('sessions_active_expires_at_idx')
      .on(t.expiresAt)
      .where(sql`${t.revokedAt} is null`),
  ],
);

export type Session = typeof sessions.$inferSelect;
export type NewSession = typeof sessions.$inferInsert;
