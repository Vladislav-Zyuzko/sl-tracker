import { sql } from 'drizzle-orm';
import { index, pgTable, text, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz, updatedAt } from './_shared.js';

/**
 * Пользователь трекера.
 *
 * Здесь намеренно нет ни одного поля, называющего провайдера входа (ADR-0002):
 * связь с Яндекс ID и любым будущим провайдером живёт только в `identities`.
 *
 * Имя, email и аватар — снимок данных провайдера, обновляемый при каждом входе
 * (stories/auth.md, US-01). Email здесь **не является** идентификатором для склейки
 * аккаунтов и поэтому не уникален.
 */
export const users = pgTable(
  'users',
  {
    id: primaryId(),
    /** Отображаемое имя из профиля провайдера. */
    displayName: varchar('display_name', { length: 255 }).notNull(),
    /** Email из профиля провайдера. Хранится как пришёл, сравнивается без учёта регистра. */
    email: varchar('email', { length: 320 }).notNull(),
    /** Адрес аватара у провайдера. Своих аватаров трекер не хранит (US-04). */
    avatarUrl: text('avatar_url'),
    lastLoginAt: tstz('last_login_at'),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    // Поиск по email нужен списку доступа и связыванию записи доступа с пользователем.
    index('users_email_lower_idx').on(sql`lower(${t.email})`),
  ],
);

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
