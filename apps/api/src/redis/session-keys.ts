/**
 * Раскладка ключей Redis для сессий.
 *
 * Требование ADR-0006: отзыв доступа обязан гасить **все** сессии человека немедленно.
 * Поэтому сессии обязаны находиться по пользователю, а не только по идентификатору
 * сессии. Переделывать раскладку ключей потом дорого — она фиксируется сейчас,
 * до появления самого модуля авторизации.
 *
 *   sl:session:<sessionId>            — данные сессии (hash), TTL = сроку жизни сессии
 *   sl:sessions:by-user:<userId>      — множество (set) идентификаторов сессий пользователя
 *   sl:oauth:state:<state>            — состояние OAuth, TTL 10 минут (ADR-0002)
 *   sl:auth:denied:<ticket>           — одноразовый тикет экрана отказа, TTL 60 секунд
 *
 * Инвариант: идентификатор сессии добавляется в множество пользователя в той же
 * операции, что и создание сессии. Отзыв доступа читает множество, удаляет каждую
 * сессию и само множество.
 *
 * Множество TTL не имеет, поэтому в нём копятся идентификаторы протухших сессий:
 * при чтении множества отсутствующие ключи сессий вычищаются из него (ленивая уборка).
 */
export const REDIS_KEY_PREFIX = 'sl';

export const sessionKey = (sessionId: string): string => `${REDIS_KEY_PREFIX}:session:${sessionId}`;

export const userSessionsKey = (userId: string): string =>
  `${REDIS_KEY_PREFIX}:sessions:by-user:${userId}`;

export const oauthStateKey = (state: string): string => `${REDIS_KEY_PREFIX}:oauth:state:${state}`;

/**
 * Тикет экрана «Доступ к трекеру закрыт».
 *
 * Экран показывает адрес, под которым человек вошёл (design/screens/access-denied.md),
 * но передавать его в query-параметре нельзя: адрес осел бы в истории браузера,
 * в реферере и в логах обратного прокси, а список доступа — персональные данные,
 * которые в логи не пишутся (ADR-0006). Поэтому в адресе — непредсказуемый тикет,
 * который обменивается на email ровно один раз и живёт минуту.
 */
export const accessDeniedTicketKey = (ticket: string): string =>
  `${REDIS_KEY_PREFIX}:auth:denied:${ticket}`;

/** Время жизни OAuth-состояния: 10 минут (ADR-0002). */
export const OAUTH_STATE_TTL_SECONDS = 10 * 60;

/** Время жизни тикета экрана отказа: минуты человеку хватает, дольше — незачем. */
export const ACCESS_DENIED_TICKET_TTL_SECONDS = 60;

/** Время жизни сессии: 30 дней (stories/auth.md, US-02). */
export const SESSION_TTL_SECONDS = 30 * 24 * 60 * 60;
