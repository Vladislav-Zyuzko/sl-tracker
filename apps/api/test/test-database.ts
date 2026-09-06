import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { loadEnv } from '../src/config/env.js';
import * as schema from '../src/database/schema/index.js';

const { Pool } = pg;
const here = dirname(fileURLToPath(import.meta.url));

export const MIGRATIONS_FOLDER = resolve(here, '../src/database/migrations');

/**
 * Тесты работают на отдельной базе, чтобы прогон не затирал данные разработки.
 * Имя берётся из `POSTGRES_TEST_DB`, по умолчанию — `<POSTGRES_DB>_test`.
 */
export function testDatabaseName(): string {
  const env = loadEnv();
  return process.env.POSTGRES_TEST_DB ?? `${env.POSTGRES_DB}_test`;
}

export function createTestPool(max = 60): pg.Pool {
  const env = loadEnv();
  return new Pool({
    host: env.POSTGRES_HOST,
    port: env.POSTGRES_PORT,
    user: env.POSTGRES_USER,
    password: env.POSTGRES_PASSWORD,
    database: testDatabaseName(),
    max,
  });
}

export function createTestDb(pool: pg.Pool): NodePgDatabase<typeof schema> {
  return drizzle(pool, { schema, casing: 'snake_case' });
}

/** Создаёт тестовую базу, если её нет, и накатывает на неё все миграции. */
export async function prepareTestDatabase(): Promise<void> {
  const env = loadEnv();
  const name = testDatabaseName();

  const admin = new Pool({
    host: env.POSTGRES_HOST,
    port: env.POSTGRES_PORT,
    user: env.POSTGRES_USER,
    password: env.POSTGRES_PASSWORD,
    database: 'postgres',
  });

  try {
    const existing = await admin.query('select 1 from pg_database where datname = $1', [name]);
    if (existing.rowCount === 0) {
      // Имя базы нельзя передать параметром: подставляем через идентификатор с экранированием.
      await admin.query(`create database "${name.replace(/"/g, '""')}"`);
    }
  } finally {
    await admin.end();
  }

  const pool = createTestPool(2);
  try {
    await migrate(createTestDb(pool), { migrationsFolder: MIGRATIONS_FOLDER });
  } finally {
    await pool.end();
  }
}
