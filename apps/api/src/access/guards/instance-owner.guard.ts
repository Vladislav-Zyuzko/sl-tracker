import {
  type CanActivate,
  type ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { FastifyRequest } from 'fastify';

/**
 * Право вести список доступа — единственная глобальная роль продукта (permissions.md,
 * п. 1.2). Ответ не-владельцу — 403, а не 404: пользователь **аутентифицирован**
 * и знает, что раздел существует, раз позвал его API. Правило «невидимость вместо
 * запрета» действует внутри проектов, где 404 скрывает сам факт наличия объекта;
 * здесь скрывать нечего, и нормативная таблица (permissions.md, п. 5) требует 403.
 * Спрятать пункт меню — задача клиента, а не защита.
 */
@Injectable()
export class InstanceOwnerGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const auth = request.slAuth;

    if (!auth) {
      throw new UnauthorizedException({ code: 'session_required', message: 'Требуется вход' });
    }

    if (!auth.user.isInstanceOwner) {
      throw new ForbiddenException({
        code: 'access_list_forbidden',
        message: 'Недостаточно прав',
      });
    }

    return true;
  }
}
