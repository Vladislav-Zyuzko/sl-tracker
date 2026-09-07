/**
 * Имя cookie сессии. Фронт и API живут на одном домене (ADR-0001), поэтому cookie
 * first-party: SameSite=Lax работает и никакой сторонней куки не требуется.
 */
export const SESSION_COOKIE_NAME = 'sl_session';

/** Значение `identities.provider` для Яндекс ID. Строка, а не enum (ADR-0002). */
export const YANDEX_PROVIDER = 'yandex';

/** Маршруты фронтенда, на которые бэкенд возвращает пользователя после колбэка. */
export const LOGIN_PATH = '/login';
export const ACCESS_DENIED_PATH = '/access-denied';
export const DEFAULT_AFTER_LOGIN_PATH = '/projects';

/**
 * Машиночитаемые коды ошибок входа. Уходят в адрес `/login?error=<код>`;
 * тексты для человека подбирает фронтенд (design/screens/login.md).
 */
export const AUTH_ERROR_CODES = [
  /** Пользователь отказал в доступе на стороне Яндекса. */
  'access_denied',
  /** Приложение не прошло модерацию в Яндексе — штатное состояние на старте проекта. */
  'unauthorized_client',
  /** `state` отсутствует, не совпал или уже использован. */
  'invalid_state',
  /** Яндекс недоступен, ответил ошибкой или не тем, чего мы ждали. */
  'provider_unavailable',
  /** Вход через Яндекс ID не настроен на этом инстансе (нет client_id/secret). */
  'oauth_not_configured',
  /** Всё остальное. Подробности — в логе сервера, наружу не уходят. */
  'server_error',
] as const;

export type AuthErrorCode = (typeof AUTH_ERROR_CODES)[number];
