import { defineConfig } from 'drizzle-kit';
import { buildDatabaseUrl, loadEnv } from './src/config/env.js';

const env = loadEnv();

/**
 * Схема живёт в коде, изменения применяются файлами миграций.
 * `drizzle-kit push` на боевой базе не используется никогда — только `generate` + `migrate`.
 */
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/database/schema/index.ts',
  out: './src/database/migrations',
  casing: 'snake_case',
  dbCredentials: {
    url: buildDatabaseUrl(env, process.env.POSTGRES_DB_OVERRIDE ?? env.POSTGRES_DB),
  },
  verbose: true,
  strict: true,
});
