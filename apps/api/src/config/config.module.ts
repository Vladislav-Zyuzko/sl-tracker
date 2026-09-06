import { Global, Module } from '@nestjs/common';
import { loadEnv } from './env.js';
import { ENV } from './env.token.js';

/**
 * Конфигурация читается и проверяется ровно один раз, при построении контейнера.
 * Доменный код получает готовый типизированный объект и никогда не лезет в process.env.
 */
@Global()
@Module({
  providers: [
    {
      provide: ENV,
      useFactory: () => loadEnv(),
    },
  ],
  exports: [ENV],
})
export class ConfigModule {}
