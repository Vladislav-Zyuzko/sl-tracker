import {
  type CanActivate,
  type ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { FastifyRequest } from 'fastify';
import { ENV, type Env } from '../../config/index.js';
import { type SessionKind, SessionService } from '../../sessions/index.js';
import { AuthRepository } from '../auth.repository.js';
import { UNSAFE_METHODS, assertSameOrigin } from '../csrf.js';
import { SESSION_COOKIE_NAME } from '../auth.constants.js';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator.js';

/**
 * Охрана запроса. Включена глобально: маршрут закрыт, пока явно не помечен `@Public()`.
 *
 * Поддерживает обе стратегии сразу (ADR-0002): cookie для веба и
 * `Authorization: Bearer` для будущей мобилки. Дальше по коду разницы нет — в запрос
 * кладётся один и тот же `AuthContext`.
 *
 * Признак владельца трекера читается из БД на каждом запросе, а не берётся из сессии:
 * снятие признака должно действовать сразу (US-07), а не после перелогина.
 */
@Injectable()
export class SessionGuard implements CanActivate {
  private readonly appOrigin: string;

  constructor(
    private readonly reflector: Reflector,
    private readonly sessions: SessionService,
    private readonly repository: AuthRepository,
    @Inject(ENV) env: Env,
  ) {
    this.appOrigin = new URL(env.APP_BASE_URL).origin;
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const presented = extractToken(request);
    if (!presented) {
      throw new UnauthorizedException({ code: 'session_required', message: 'Требуется вход' });
    }

    // CSRF: SameSite=Lax закрывает основное, но небезопасные методы при cookie-сессии
    // дополнительно требуют совпадения Origin. Bearer-запросы браузер сам не отправит
    // от чужого имени — им проверка не нужна.
    if (presented.kind === 'cookie' && UNSAFE_METHODS.has(request.method.toUpperCase())) {
      assertSameOrigin(request, this.appOrigin);
    }

    const session = await this.sessions.resolve(presented.token);
    if (!session) {
      // Сюда же попадает погашенная при отзыве доступа сессия (US-09): 401.
      throw new UnauthorizedException({ code: 'session_expired', message: 'Сессия завершена' });
    }

    const user = await this.repository.findAuthenticatedUser(session.userId);
    if (!user) {
      throw new UnauthorizedException({ code: 'session_expired', message: 'Сессия завершена' });
    }

    request.slAuth = { user, session };
    await this.sessions.touch(session);
    return true;
  }
}

/**
 * Достаёт токен из запроса. Bearer имеет приоритет: если клиент прислал заголовок явно,
 * он знает, чего хочет, и случайная cookie в браузере разработчика ничего не меняет.
 */
export function extractToken(request: FastifyRequest): { token: string; kind: SessionKind } | null {
  const header = request.headers.authorization;
  if (typeof header === 'string' && header.toLowerCase().startsWith('bearer ')) {
    const token = header.slice('bearer '.length).trim();
    return token.length > 0 ? { token, kind: 'bearer' } : null;
  }

  const cookie = readCookie(request, SESSION_COOKIE_NAME);
  return cookie ? { token: cookie, kind: 'cookie' } : null;
}

function readCookie(request: FastifyRequest, name: string): string | null {
  const parsed = request.cookies as Record<string, string | undefined> | undefined;
  const value = parsed?.[name];
  return value && value.length > 0 ? value : null;
}
