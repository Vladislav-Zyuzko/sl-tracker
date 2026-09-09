/**
 * Применитель миграций для боевого развёртывания.
 *
 * Запускается **отдельным одноразовым контейнером перед стартом API** из того же
 * образа: `node dist/database/migrate.js`.
 *
 * Почему не `drizzle-kit migrate`: `drizzle-kit` — dev-зависимость, а в финальный образ
 * зависимости ставятся с `--omit=dev`; сверх того его конфигурация — файл на TypeScript,
 * исполнять который в рантайме нечем. Здесь используется только `drizzle-orm`, который
 * и так лежит в боевых зависимостях, а SQL-файлы миграций кладутся рядом со сборкой
 * (`nest-cli.json`, раздел `assets`) — путь считается от этого модуля и одинаково
 * работает и из `src/`, и из `dist/`.
 *
 * Свойства, ради которых это написано руками, а не одной строчкой `migrate(...)`:
 *  - **идемпотентность.** Уже применённые миграции пропускаются: их отметки лежат
 *    в `drizzle.__drizzle_migrations`;
 *  - **ненулевой код возврата при любой ошибке.** Иначе развёртывание поедет дальше
 *    и поднимет API на сломанной базе;
 *  - **в лог попадает список того, что применено.** «Готово» без перечня не даёт
 *    понять, накатилось ли ожидаемое;
 *  - **взаимное исключение.** Два одновременных развёртывания не полезут в базу
 *    вдвоём: перед работой берётся консультативная блокировка PostgreSQL.
 */
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Logger } from '@nestjs/common';
import { drizzle } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import pg from 'pg';
import { envSchema, loadDotenvFiles } from '../config/index.js';

const { Pool } = pg;
const LOGGER = 'Migrate';

/** Папка миграций лежит рядом с этим модулем: в `src/` — исходники, в `dist/` — копия. */
const MIGRATIONS_FOLDER = resolve(dirname(fileURLToPath(import.meta.url)), 'migrations');

/**
 * Ключ консультативной блокировки. Произвольное, но зафиксированное число: важно лишь,
 * чтобы его брали все копии применителя и не брал никто другой.
 */
const LOCK_KEY = 776_1240;
const LOCK_ATTEMPTS = 60;
const LOCK_RETRY_MS = 1_000;

/**
 * Применителю нужен только доступ к PostgreSQL. Остальные переменные приложения
 * (Redis, MinIO, Яндекс ID) он не читает и падать из-за них не должен: контейнер
 * миграций поднимается раньше и живёт секунды. Форма берётся из общей схемы, чтобы
 * правила проверки не разъехались с приложением.
 */
const migrationEnvSchema = envSchema.pick({
  POSTGRES_HOST: true,
  POSTGRES_PORT: true,
  POSTGRES_USER: true,
  POSTGRES_PASSWORD: true,
  POSTGRES_DB: true,
});

interface JournalEntry {
  tag: string;
  when: number;
}

/** Порядок и имена миграций знает журнал: он же источник правды для `drizzle-orm`. */
function readJournal(): JournalEntry[] {
  const raw = readFileSync(resolve(MIGRATIONS_FOLDER, 'meta', '_journal.json'), 'utf8');
  const parsed: unknown = JSON.parse(raw);
  const entries = (parsed as { entries?: unknown }).entries;
  if (!Array.isArray(entries)) {
    throw new Error(`Журнал миграций повреждён: ${MIGRATIONS_FOLDER}/meta/_journal.json`);
  }

  return entries
    .map((entry) => entry as JournalEntry)
    .sort((left, right) => left.when - right.when);
}

/**
 * Отметка последней применённой миграции. `null` — таблицы учёта ещё нет, то есть база
 * чистая. Отсутствие таблицы отличается от ошибки соединения и ошибкой не считается.
 */
async function lastAppliedAt(pool: pg.Pool): Promise<number | null> {
  const exists = await pool.query<{ table: string | null }>(
    `select to_regclass('drizzle.__drizzle_migrations')::text as "table"`,
  );
  if (!exists.rows[0]?.table) {
    return null;
  }

  const applied = await pool.query<{ created_at: string | null }>(
    'select created_at from drizzle.__drizzle_migrations order by created_at desc limit 1',
  );
  const value = applied.rows[0]?.created_at;
  return value === undefined || value === null ? null : Number(value);
}

/**
 * `drizzle-orm` применяет миграцию, если её отметка времени больше последней записанной.
 * Здесь тот же критерий — иначе в логе оказалось бы не то, что произошло на самом деле.
 */
function pendingMigrations(journal: JournalEntry[], appliedAt: number | null): JournalEntry[] {
  return appliedAt === null ? journal : journal.filter((entry) => entry.when > appliedAt);
}

/**
 * Консультативная блокировка на отдельном соединении: миграции идут по другому
 * соединению того же пула, и это нормально — блокировка разводит между собой процессы,
 * а не запросы. Ждём ограниченное время и падаем, а не висим бесконечно.
 */
async function withLock<T>(pool: pg.Pool, action: () => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    for (let attempt = 1; ; attempt += 1) {
      const result = await client.query<{ locked: boolean }>(
        'select pg_try_advisory_lock($1) as locked',
        [LOCK_KEY],
      );
      if (result.rows[0]?.locked) {
        break;
      }
      if (attempt >= LOCK_ATTEMPTS) {
        throw new Error(
          'Миграции уже применяет другой процесс: блокировка не освободилась за отведённое время',
        );
      }
      Logger.warn(`Миграции применяет другой процесс, ждём (попытка ${attempt})`, LOGGER);
      await new Promise((done) => setTimeout(done, LOCK_RETRY_MS));
    }

    try {
      return await action();
    } finally {
      await client.query('select pg_advisory_unlock($1)', [LOCK_KEY]);
    }
  } finally {
    client.release();
  }
}

async function main(): Promise<void> {
  loadDotenvFiles();

  const parsed = migrationEnvSchema.safeParse(process.env);
  if (!parsed.success) {
    // Как и в приложении: перечисляем проблемные переменные, но не их значения.
    const problems = parsed.error.issues
      .map((issue) => `  - ${issue.path.join('.') || '(корень)'}: ${issue.message}`)
      .join('\n');
    throw new Error(`Некорректная конфигурация окружения:\n${problems}`);
  }

  const env = parsed.data;
  const pool = new Pool({
    host: env.POSTGRES_HOST,
    port: env.POSTGRES_PORT,
    user: env.POSTGRES_USER,
    password: env.POSTGRES_PASSWORD,
    database: env.POSTGRES_DB,
    max: 2,
    connectionTimeoutMillis: 10_000,
  });

  try {
    Logger.log(
      `База ${env.POSTGRES_DB} на ${env.POSTGRES_HOST}:${env.POSTGRES_PORT}, миграции из ${MIGRATIONS_FOLDER}`,
      LOGGER,
    );

    await withLock(pool, async () => {
      const journal = readJournal();
      const pending = pendingMigrations(journal, await lastAppliedAt(pool));

      if (pending.length === 0) {
        Logger.log(`Применять нечего: все ${journal.length} миграций уже в базе`, LOGGER);
        return;
      }

      Logger.log(`К применению ${pending.length} из ${journal.length}`, LOGGER);
      const startedAt = Date.now();
      await migrate(drizzle(pool), { migrationsFolder: MIGRATIONS_FOLDER });

      for (const entry of pending) {
        Logger.log(`  применена ${entry.tag}`, LOGGER);
      }
      Logger.log(`Готово за ${Date.now() - startedAt} мс`, LOGGER);
    });
  } finally {
    await pool.end();
  }
}

await main().catch((error: unknown) => {
  // Молча упавшая миграция страшнее упавшего развёртывания: код возврата обязан быть
  // ненулевым, иначе следом поднимется API на базе не той версии.
  Logger.error(
    error instanceof Error ? error.message : String(error),
    error instanceof Error ? error.stack : undefined,
    LOGGER,
  );
  process.exit(1);
});
