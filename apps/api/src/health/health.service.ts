import { Inject, Injectable, Logger } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import type { Redis } from 'ioredis';
import { DB, type Database } from '../database/index.js';
import { REDIS } from '../redis/index.js';
import type { DependencyHealthDto, HealthResponseDto } from './dto/health-response.dto.js';

/** Проба не должна висеть дольше, чем интервал опроса у Caddy (10 с). */
const PROBE_TIMEOUT_MS = 2_000;

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    @Inject(DB) private readonly db: Database,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async check(): Promise<HealthResponseDto> {
    const [postgres, redis] = await Promise.all([this.checkPostgres(), this.checkRedis()]);

    return {
      status: postgres.status === 'up' && redis.status === 'up' ? 'ok' : 'degraded',
      uptimeSeconds: Math.round(process.uptime()),
      postgres,
      redis,
    };
  }

  private checkPostgres(): Promise<DependencyHealthDto> {
    return this.probe('postgres', async () => {
      await this.db.execute(sql`select 1`);
    });
  }

  private checkRedis(): Promise<DependencyHealthDto> {
    return this.probe('redis', async () => {
      const pong = await this.redis.ping();
      if (pong !== 'PONG') {
        throw new Error('неожиданный ответ на PING');
      }
    });
  }

  /**
   * Наружу отдаётся только «нет соединения» — ни адресов, ни имён баз, ни стектрейсов:
   * `/api/health` доступен без авторизации, и он не должен рассказывать о внутренностях.
   * Настоящая причина уходит в лог сервера.
   */
  private async probe(name: string, run: () => Promise<void>): Promise<DependencyHealthDto> {
    const startedAt = Date.now();
    try {
      await withTimeout(run(), PROBE_TIMEOUT_MS);
      return { status: 'up', latencyMs: Date.now() - startedAt };
    } catch (error) {
      this.logger.error(`Проба ${name} не прошла`, error instanceof Error ? error.stack : error);
      return {
        status: 'down',
        latencyMs: Date.now() - startedAt,
        error: 'нет соединения',
      };
    }
  }
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`превышен таймаут ${ms} мс`)), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error: unknown) => {
        clearTimeout(timer);
        reject(error instanceof Error ? error : new Error(String(error)));
      },
    );
  });
}
