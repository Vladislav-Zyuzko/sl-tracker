import {
  type CanActivate,
  type ExecutionContext,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { FastifyReply, FastifyRequest } from 'fastify';
import type { Redis } from 'ioredis';
import { REDIS, REDIS_KEY_PREFIX } from '../../redis/index.js';
import { RATE_LIMIT_KEY, type RateLimitOptions } from '../decorators/rate-limit.decorator.js';

/**
 * Ограничение частоты запросов, счётчик — в Redis.
 *
 * Окно фиксированное: для защиты входа и поиска этого достаточно, а скользящее окно
 * стоит дороже и в отчётах о нагрузке трекера малой команды разницы не даст.
 *
 * Ключ — по адресу клиента. За приложением стоит Caddy, и адрес берётся из `request.ip`,
 * который Fastify вычисляет с учётом `trustProxy` (см. `main.ts`).
 *
 * Если Redis недоступен, ограничение пропускает запрос: недоступный кэш не должен
 * закрывать вход в приложение. Это осознанный размен.
 */
@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly logger = new Logger(RateLimitGuard.name);

  constructor(
    private readonly reflector: Reflector,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const options = this.reflector.getAllAndOverride<RateLimitOptions | undefined>(RATE_LIMIT_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!options) {
      return true;
    }

    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const key = `${REDIS_KEY_PREFIX}:ratelimit:${options.name}:${request.ip}`;

    let used: number;
    try {
      used = await this.redis.incr(key);
      if (used === 1) {
        await this.redis.expire(key, options.windowSeconds);
      }
    } catch (error) {
      this.logger.warn(
        `Ограничение частоты пропущено, Redis недоступен: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return true;
    }

    if (used > options.limit) {
      const reply = context.switchToHttp().getResponse<FastifyReply>();
      void reply.header('retry-after', String(options.windowSeconds));
      throw new HttpException(
        { code: 'rate_limited', message: 'Слишком много запросов, попробуйте позже' },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
