import { createHmac, randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';

/**
 * Формат предъявляемого секрета сессии — `<sessionId>.<verifier>`.
 *
 * Схема «идентификатор + верификатор», а не «случайная строка целиком», выбрана потому,
 * что сессии обязаны находиться по идентификатору: раскладка ключей Redis
 * (`src/redis/session-keys.ts`) держит множество идентификаторов сессий на пользователя,
 * иначе отзыв доступа не смог бы погасить все сессии человека (ADR-0006).
 *
 * По идентификатору сессия находится, верификатором подтверждается право её предъявить.
 * В базе и в Redis хранится только HMAC-SHA256 от верификатора: дамп БД не даёт
 * возможности предъявить чужую сессию.
 *
 * Один и тот же формат используется и для cookie веба, и для `Authorization: Bearer`
 * будущей мобилки — доменный код разницы не видит (ADR-0002).
 */

/** 32 байта из криптографического генератора: 256 бит энтропии на верификатор. */
const VERIFIER_BYTES = 32;

const SESSION_ID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const VERIFIER_PATTERN = /^[A-Za-z0-9_-]{40,64}$/;

export interface SessionTokenParts {
  /** Идентификатор сессии: по нему сессия находится в Redis и в PostgreSQL. */
  id: string;
  verifier: string;
}

export function generateSessionId(): string {
  return randomUUID();
}

export function generateSessionVerifier(): string {
  return randomBytes(VERIFIER_BYTES).toString('base64url');
}

export function formatSessionToken(sessionId: string, verifier: string): string {
  return `${sessionId}.${verifier}`;
}

/**
 * Разбирает предъявленный секрет. Возвращает `null` на любой мусор — вызывающий код
 * отвечает 401 и не пытается ничего искать в хранилище.
 */
export function parseSessionToken(raw: string | undefined | null): SessionTokenParts | null {
  if (!raw) {
    return null;
  }

  const separator = raw.indexOf('.');
  if (separator < 0) {
    return null;
  }

  const id = raw.slice(0, separator);
  const verifier = raw.slice(separator + 1);

  if (!SESSION_ID_PATTERN.test(id) || !VERIFIER_PATTERN.test(verifier)) {
    return null;
  }

  return { id, verifier };
}

/**
 * HMAC-SHA256 от верификатора с секретом приложения (`SESSION_SECRET`) в роли перца.
 * Ровно 64 hex-символа — под колонку `sessions.token_hash char(64)`.
 */
export function hashSessionVerifier(verifier: string, pepper: string): string {
  return createHmac('sha256', pepper).update(verifier).digest('hex');
}

/** Сравнение хешей за постоянное время: длина фиксирована, утечки по времени нет. */
export function verifierMatches(verifier: string, pepper: string, expectedHash: string): boolean {
  const actual = Buffer.from(hashSessionVerifier(verifier, pepper), 'utf8');
  const expected = Buffer.from(expectedHash, 'utf8');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
