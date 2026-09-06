import { sql } from 'drizzle-orm';
import { boolean, index, pgTable, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz } from './_shared.js';
import { accessEntrySourceEnum } from './enums.js';
import { users } from './users.js';

/**
 * Запись списка доступа — уровень 0 (ADR-0006, permissions.md, раздел 1.1).
 *
 * Список доступа решает «пускать ли в трекер вообще» и не даёт никаких прав внутри
 * проектов. Источник правды — эта таблица; переменная `ACCESS_LIST_BOOTSTRAP_EMAILS`
 * применяется при старте идемпотентно и только добавляет записи.
 *
 * Email хранится нормализованным к нижнему регистру, сравнение — без учёта регистра
 * (US-05, US-07). Это персональные данные: в логи не пишутся.
 */
export const accessEntries = pgTable(
  'access_entries',
  {
    id: primaryId(),
    email: varchar('email', { length: 320 }).notNull(),
    source: accessEntrySourceEnum('source').notNull(),
    /**
     * Признак владельца трекера — единственная глобальная роль в продукте (D-39).
     * Записи источника `config` получают его автоматически при начальном наполнении.
     */
    isInstanceOwner: boolean('is_instance_owner').notNull().default(false),
    /** Кто добавил запись вручную. Для `config` и `invitation` пусто. */
    addedByUserId: uuid('added_by_user_id').references(() => users.id, { onDelete: 'set null' }),
    /**
     * Пользователь, которым этот адрес оказался при первом входе.
     * Пусто — «ещё не входил»: экран управления доступом показывает только email (US-07).
     */
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    firstLoginAt: tstz('first_login_at'),
    createdAt: createdAt(),
  },
  (t) => [
    // Один адрес — одна запись, независимо от регистра (US-07: повторное добавление — 409).
    uniqueIndex('access_entries_email_lower_key').on(sql`lower(${t.email})`),
    // Список сортируется по дате добавления, сначала новые (US-07).
    index('access_entries_created_at_idx').on(t.createdAt.desc().nullsFirst()),
    // Инвариант «владелец всегда хотя бы один» проверяется подсчётом по этому индексу.
    index('access_entries_owner_idx')
      .on(t.id)
      .where(sql`${t.isInstanceOwner}`),
    index('access_entries_user_id_idx').on(t.userId),
  ],
);

export type AccessEntry = typeof accessEntries.$inferSelect;
export type NewAccessEntry = typeof accessEntries.$inferInsert;
