import {
  type CanActivate,
  type ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { FastifyRequest } from 'fastify';

/**
 * Управлять токенами можно только из браузера — из cookie-сессии живого человека.
 *
 * Смысл ограничения в том, чтобы утечка токена не размножалась: укравший PAT не должен
 * уметь ни выпустить себе новый, ни отозвать остальные, ни **перечислить** их —
 * список чужих токенов это разведка перед отзывом (RFC MCP, §5.4). Поэтому охрана
 * стоит на всём контроллере, а не только на изменяющих методах.
 *
 * Проверяется способ предъявления (`kind`), а не назначение (`purpose`): cookie выдаётся
 * только входом через Яндекс ID, а PAT — всегда bearer. Так правило продолжит работать
 * и для будущей мобилки, которая тоже ходит bearer-ом и токенами управлять не должна.
 */
@Injectable()
export class CookieSessionGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const auth = request.slAuth;

    if (!auth) {
      throw new UnauthorizedException({ code: 'session_required', message: 'Требуется вход' });
    }

    if (auth.session.kind !== 'cookie') {
      throw new ForbiddenException({
        code: 'pat_cannot_manage_tokens',
        message: 'Управление токенами доступно только из веб-интерфейса',
      });
    }

    return true;
  }
}
