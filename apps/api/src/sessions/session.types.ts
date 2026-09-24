/** Способ, которым клиент предъявил сессию. Доменный код на него не смотрит (ADR-0002). */
export type SessionKind = 'cookie' | 'bearer';

/**
 * Зачем сессия выдана: обычный вход (`session`) или персональный токен доступа (`pat`).
 *
 * В отличие от `SessionKind`, это различие доменному коду видно: PAT не продлевается
 * при использовании и не имеет права управлять токенами (RFC MCP, §5.3, §5.4).
 */
export type SessionPurpose = 'session' | 'pat';

/** Разрешённая сессия. Секрета здесь нет — он остаётся у клиента. */
export interface SessionRecord {
  id: string;
  userId: string;
  kind: SessionKind;
  purpose: SessionPurpose;
  expiresAt: Date;
  lastSeenAt: Date;
}

/** Только что созданная сессия: секрет отдаётся вызывающему коду ровно один раз. */
export interface IssuedSession {
  id: string;
  /** Значение для cookie или для заголовка `Authorization: Bearer`. */
  token: string;
  /** Начало токена для списка токенов. Не секрет (см. `tokenPrefix`). */
  prefix: string;
  expiresAt: Date;
  createdAt: Date;
}

/**
 * Строка списка сессий — то, что показывает экран «Токены доступа».
 * Секрета и его хеша здесь нет ни в каком виде.
 */
export interface SessionSummary {
  id: string;
  /** Имя, данное владельцем. У сессий входа его нет. */
  label: string | null;
  prefix: string | null;
  purpose: SessionPurpose;
  createdAt: Date;
  /**
   * Последнее обращение с точностью до суток (см. `SessionService.touch`).
   * Пока токен ни разу не предъявляли, равен `createdAt`.
   */
  lastSeenAt: Date;
  expiresAt: Date;
  revokedAt: Date | null;
}

/** Опции создания сессии. Всё необязательно: обычный вход не задаёт ничего. */
export interface CreateSessionOptions {
  /** Имя от владельца. Осмысленно только для PAT. */
  label?: string;
  /** По умолчанию `session`. */
  purpose?: SessionPurpose;
  /** Срок жизни. По умолчанию `SESSION_TTL_SECONDS` (30 дней). */
  ttlSeconds?: number;
}
