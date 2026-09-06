import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type * as schema from './schema/index.js';

/** Drizzle, привязанный к схеме трекера. */
export type Database = NodePgDatabase<typeof schema>;

/**
 * Транзакция. Репозитории принимают либо `Database`, либо транзакцию — чтобы
 * запись в основную таблицу, история изменений и событие уведомления попадали
 * в одну транзакцию, а не в три разные.
 */
export type Transaction = Parameters<Parameters<Database['transaction']>[0]>[0];

/** Исполнитель запроса: соединение или транзакция. */
export type Executor = Database | Transaction;
