import { z } from 'zod';

/**
 * Схема переменных окружения.
 *
 * Всё, что помечено обязательным, проверяется при старте приложения: если значения нет
 * или оно не проходит проверку, процесс падает с понятным сообщением и не поднимается
 * в полурабочем состоянии.
 *
 * Значения по умолчанию заданы только там, где безопасное умолчание существует
 * (адрес локального сервиса, порт). Ни один секрет умолчания не имеет.
 */
export const envSchema = z.object({
  // --- Приложение -------------------------------------------------------------
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  API_PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  /** Базовый адрес приложения: на него бэкенд редиректит после входа. */
  APP_BASE_URL: z.url(),
  /** Секрет подписи сессионных cookie. Короткий секрет не принимается. */
  SESSION_SECRET: z.string().min(32, 'SESSION_SECRET должен быть не короче 32 символов'),

  // --- PostgreSQL -------------------------------------------------------------
  POSTGRES_HOST: z.string().min(1).default('localhost'),
  POSTGRES_PORT: z.coerce.number().int().min(1).max(65535).default(5432),
  POSTGRES_USER: z.string().min(1),
  POSTGRES_PASSWORD: z.string().min(1),
  POSTGRES_DB: z.string().min(1),

  // --- Redis ------------------------------------------------------------------
  REDIS_HOST: z.string().min(1).default('localhost'),
  REDIS_PORT: z.coerce.number().int().min(1).max(65535).default(6379),
  REDIS_PASSWORD: z.string().min(1),

  // --- MinIO (S3) -------------------------------------------------------------
  MINIO_HOST: z.string().min(1).default('localhost'),
  MINIO_PORT: z.coerce.number().int().min(1).max(65535).default(9000),
  MINIO_ROOT_USER: z.string().min(1),
  MINIO_ROOT_PASSWORD: z.string().min(1),
  MINIO_BUCKET: z.string().min(1),

  // --- Яндекс ID --------------------------------------------------------------
  // Пока поток авторизации не реализован, переменные необязательны: пустой .env
  // не должен мешать поднять API. Как только появится модуль auth, они станут
  // обязательными — проверка перенесётся сюда, а не останется на совести вызова.
  YANDEX_CLIENT_ID: z.string().optional(),
  YANDEX_CLIENT_SECRET: z.string().optional(),
  YANDEX_REDIRECT_URI: z.url().optional(),

  // --- Список доступа ---------------------------------------------------------
  /** Начальное наполнение списка доступа: адреса через запятую (ADR-0006). */
  ACCESS_LIST_BOOTSTRAP_EMAILS: z.string().optional(),
});

export type Env = Readonly<z.infer<typeof envSchema>>;
