/** Способ, которым клиент предъявил сессию. Доменный код на него не смотрит (ADR-0002). */
export type SessionKind = 'cookie' | 'bearer';

/** Разрешённая сессия. Секрета здесь нет — он остаётся у клиента. */
export interface SessionRecord {
  id: string;
  userId: string;
  kind: SessionKind;
  expiresAt: Date;
  lastSeenAt: Date;
}

/** Только что созданная сессия: секрет отдаётся вызывающему коду ровно один раз. */
export interface IssuedSession {
  id: string;
  /** Значение для cookie или для заголовка `Authorization: Bearer`. */
  token: string;
  expiresAt: Date;
}
