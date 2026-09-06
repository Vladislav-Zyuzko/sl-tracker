import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { API_PREFIX, configureApp, setupSwagger } from './app.setup.js';
import { AppModule } from './app.module.js';
import { ENV, type Env } from './config/index.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({
      // За приложением стоит Caddy: без этого в логах и в проверках Origin
      // окажется адрес прокси, а не клиента.
      trustProxy: true,
      bodyLimit: 1024 * 1024,
    }),
  );

  configureApp(app);

  const env = app.get<Env>(ENV);
  if (env.NODE_ENV !== 'production') {
    setupSwagger(app);
  }

  // CORS не включаем: фронт и API живут на одном домене (ADR-0001).
  await app.listen({ port: env.API_PORT, host: '0.0.0.0' });

  Logger.log(
    `SL Tracker API слушает порт ${env.API_PORT}, префикс /${API_PREFIX}, окружение ${env.NODE_ENV}`,
    'Bootstrap',
  );
}

void bootstrap().catch((error: unknown) => {
  // Ошибка конфигурации или недоступная зависимость на старте: падаем громко,
  // а не поднимаемся в полурабочем состоянии.
  Logger.error(
    error instanceof Error ? error.message : String(error),
    error instanceof Error ? error.stack : undefined,
    'Bootstrap',
  );
  process.exit(1);
});
