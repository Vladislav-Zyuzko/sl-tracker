import { type ExecutionContext, UnauthorizedException, createParamDecorator } from '@nestjs/common';
import type { FastifyRequest } from 'fastify';
import type { AuthenticatedUser } from '../auth.types.js';

/**
 * Текущий пользователь. Доступен только там, где отработала охрана сессии, —
 * на `@Public()`-маршруте вызов означает ошибку в коде, и она видна сразу.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthenticatedUser => {
    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const auth = request.slAuth;
    if (!auth) {
      throw new UnauthorizedException({ code: 'session_required', message: 'Требуется вход' });
    }
    return auth.user;
  },
);

/** Сессия текущего запроса — нужна выходу, чтобы погасить именно её. */
export const CurrentSession = createParamDecorator((_data: unknown, context: ExecutionContext) => {
  const request = context.switchToHttp().getRequest<FastifyRequest>();
  const auth = request.slAuth;
  if (!auth) {
    throw new UnauthorizedException({ code: 'session_required', message: 'Требуется вход' });
  }
  return auth.session;
});
