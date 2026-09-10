import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Конфигурация сквозного прогона.
 *
 * Сквозные тесты работают против **живого** API, поднятого отдельным процессом,
 * а не против приложения, собранного внутри Jest. Поэтому окружение читается тут
 * самостоятельно: `apps/api/src/config` — чужая зона и чужой ESM-граф.
 *
 * Изоляция от рабочего окружения держится на трёх вещах, и все три обязательны:
 *   - свой порт API (по умолчанию 3100, рабочий экземпляр живёт на 3000);
 *   - своя база PostgreSQL (`sl_tracker_e2e`), не рабочая и не та, что берут
 *     e2e бэкенда (`sl_tracker_test`) — иначе их `truncate` снесёт данные прогона;
 *   - своя логическая база Redis (14): 0 занят рабочим окружением, 15 — тестами бэкенда.
 */

const here = dirname(fileURLToPath(import.meta.url));
export const E2E_ROOT = resolve(here, '..');
export const REPO_ROOT = resolve(E2E_ROOT, '..');
export const API_DIR = resolve(REPO_ROOT, 'apps/api');

/** Минимальный разбор `.env`: `KEY=value`, комментарии и пустые строки пропускаются. */
function parseDotenv(file) {
  const values = {};
  if (!existsSync(file)) {
    return values;
  }
  for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (trimmed.length === 0 || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return values;
}

const dotenv = parseDotenv(resolve(REPO_ROOT, '.env'));

/** Переменная окружения процесса важнее `.env` — так же, как это делает сам API. */
function read(name, fallback) {
  return process.env[name] ?? dotenv[name] ?? fallback;
}

function required(name) {
  const value = read(name);
  if (!value) {
    throw new Error(
      `Не задана переменная ${name}. Заполни .env в корне репозитория (шаблон — .env.example).`,
    );
  }
  return value;
}

/** Адрес владельца трекера, которым наполняется список доступа при старте тестового API. */
export const OWNER_EMAIL = 'e2e-owner@sl-tracker.test';

export const config = {
  /** Порт живого API под тесты. Рабочий экземпляр на 3000 не трогаем. */
  apiPort: Number(read('E2E_API_PORT', '3100')),
  get apiUrl() {
    return read('E2E_API_URL', `http://127.0.0.1:${this.apiPort}`);
  },
  get apiBase() {
    return `${this.apiUrl}/api`;
  },
  get wsUrl() {
    return `${this.apiUrl.replace(/^http/, 'ws')}/api/ws`;
  },
  /**
   * Origin, который API считает своим: с ним сверяется заголовок `Origin`
   * у небезопасных методов при cookie-сессии (защита от CSRF, `src/auth/csrf.ts`).
   */
  appBaseUrl: read('E2E_APP_BASE_URL', 'http://localhost:8081'),
  get appOrigin() {
    return new URL(this.appBaseUrl).origin;
  },

  postgres: {
    host: read('POSTGRES_HOST', 'localhost'),
    port: Number(read('POSTGRES_PORT', '5432')),
    user: required('POSTGRES_USER'),
    password: required('POSTGRES_PASSWORD'),
    database: read('E2E_POSTGRES_DB', 'sl_tracker_e2e'),
  },

  redis: {
    host: read('REDIS_HOST', 'localhost'),
    port: Number(read('REDIS_PORT', '6379')),
    password: required('REDIS_PASSWORD'),
    db: Number(read('E2E_REDIS_DB', '14')),
  },

  minioBucket: read('E2E_MINIO_BUCKET', 'sl-tracker-e2e'),

  /**
   * Тот же секрет, которым API считает HMAC от верификатора сессии.
   * Без него харнесс не может выдать сессию в обход Яндекс ID — см. `lib/session.mjs`.
   */
  sessionSecret: required('SESSION_SECRET'),
};

/** Окружение для дочернего процесса API. */
export function apiChildEnv() {
  return {
    ...process.env,
    NODE_ENV: 'test',
    API_PORT: String(config.apiPort),
    APP_BASE_URL: config.appBaseUrl,
    POSTGRES_DB: config.postgres.database,
    // NODE_ENV=test заставляет API взять REDIS_TEST_DB вместо REDIS_DB (redis.module.ts).
    REDIS_TEST_DB: String(config.redis.db),
    MINIO_BUCKET: config.minioBucket,
    ACCESS_LIST_BOOTSTRAP_EMAILS: OWNER_EMAIL,
    SESSION_SECRET: config.sessionSecret,
  };
}
