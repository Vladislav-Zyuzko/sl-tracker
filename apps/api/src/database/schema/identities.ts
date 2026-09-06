import { index, pgTable, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId, updatedAt } from './_shared.js';
import { users } from './users.js';

/**
 * Идентичность пользователя у внешнего провайдера (ADR-0002).
 *
 * `provider` — обычная строка, а не enum: добавление второго провайдера или локального
 * входа по паролю должно быть новой строкой в данных, а не миграцией схемы.
 * Для Яндекс ID `externalId` — поле `id` из ответа `https://login.yandex.ru/info`.
 */
export const identities = pgTable(
  'identities',
  {
    id: primaryId(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    provider: varchar('provider', { length: 32 }).notNull(),
    externalId: varchar('external_id', { length: 255 }).notNull(),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    // Ровно одна учётная запись трекера на пару (провайдер, идентификатор у провайдера).
    uniqueIndex('identities_provider_external_id_key').on(t.provider, t.externalId),
    index('identities_user_id_idx').on(t.userId),
  ],
);

export type Identity = typeof identities.$inferSelect;
export type NewIdentity = typeof identities.$inferInsert;
