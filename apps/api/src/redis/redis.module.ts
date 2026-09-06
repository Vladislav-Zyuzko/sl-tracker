import { Global, Inject, Module, type OnApplicationShutdown } from '@nestjs/common';
import { Redis } from 'ioredis';
import { ENV, type Env } from '../config/index.js';
import { REDIS } from './redis.tokens.js';

@Global()
@Module({
  providers: [
    {
      provide: REDIS,
      inject: [ENV],
      useFactory: (env: Env) =>
        new Redis({
          host: env.REDIS_HOST,
          port: env.REDIS_PORT,
          password: env.REDIS_PASSWORD,
          // Ошибку подключения должен видеть вызывающий код, а не бесконечная очередь
          // команд, копящаяся в памяти процесса: после двух неудачных попыток команда
          // отклоняется.
          maxRetriesPerRequest: 2,
          connectTimeout: 5_000,
          // Офлайн-очередь оставлена включённой намеренно: без неё первая же команда,
          // отправленная до готовности сокета (а health-проба приходит сразу после
          // старта), падает с «Stream isn't writeable», хотя Redis доступен.
          enableOfflineQueue: true,
          lazyConnect: false,
        }),
    },
  ],
  exports: [REDIS],
})
export class RedisModule implements OnApplicationShutdown {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async onApplicationShutdown(): Promise<void> {
    await this.redis.quit();
  }
}
