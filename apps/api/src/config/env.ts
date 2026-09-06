import * as fs from 'node:fs';
import * as path from 'node:path';
import { config as loadDotenv } from 'dotenv';
import { type Env, envSchema } from './env.schema.js';

/**
 * Файлы `.env` ищутся от текущей рабочей директории вверх: локально API запускается
 * из `apps/api`, а `.env` лежит в корне репозитория. В контейнере переменные приходят
 * из окружения, и ни один файл не находится — это нормальный путь, а не ошибка.
 */
function loadDotenvFiles(): void {
  const candidates = [
    path.resolve(process.cwd(), '.env'),
    path.resolve(process.cwd(), '..', '..', '.env'),
  ];

  for (const file of candidates) {
    if (fs.existsSync(file)) {
      loadDotenv({ path: file, override: false, quiet: true });
    }
  }
}

let cached: Env | undefined;

/**
 * Читает и валидирует окружение. Бросает исключение со списком проблемных переменных —
 * без значений, чтобы секреты не попали в лог.
 */
export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  if (cached) {
    return cached;
  }

  loadDotenvFiles();

  const parsed = envSchema.safeParse(source);
  if (!parsed.success) {
    const problems = parsed.error.issues
      .map((issue) => `  - ${issue.path.join('.') || '(корень)'}: ${issue.message}`)
      .join('\n');
    throw new Error(
      `Некорректная конфигурация окружения. Проверь .env (шаблон — .env.example):\n${problems}`,
    );
  }

  cached = Object.freeze(parsed.data);
  return cached;
}

/** Только для тестов: сбрасывает запомненное окружение. */
export function resetEnvCache(): void {
  cached = undefined;
}

/** Строка подключения к PostgreSQL, собранная из отдельных переменных. */
export function buildDatabaseUrl(env: Env, database = env.POSTGRES_DB): string {
  const user = encodeURIComponent(env.POSTGRES_USER);
  const password = encodeURIComponent(env.POSTGRES_PASSWORD);
  return `postgresql://${user}:${password}@${env.POSTGRES_HOST}:${env.POSTGRES_PORT}/${database}`;
}
