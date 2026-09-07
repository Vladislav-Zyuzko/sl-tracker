import type { SessionRecord } from '../sessions/index.js';

/**
 * Пользователь, разрешённый охраной запроса.
 *
 * Доменный код видит только это — не cookie, не bearer, не сессию провайдера (ADR-0002).
 */
export interface AuthenticatedUser {
  id: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
  /**
   * Единственная глобальная роль продукта — владелец трекера (permissions.md, п. 1.2).
   * Прав внутри проектов не даёт.
   */
  isInstanceOwner: boolean;
}

/** Что охрана запроса кладёт в запрос. */
export interface AuthContext {
  user: AuthenticatedUser;
  session: SessionRecord;
}

declare module 'fastify' {
  interface FastifyRequest {
    /** Заполняется `SessionGuard`. У публичных маршрутов пусто. */
    slAuth?: AuthContext;
  }
}
