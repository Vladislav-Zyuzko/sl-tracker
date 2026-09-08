import 'reflect-metadata';
import net from 'node:net';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { API_PREFIX, configureApp, setupSwagger } from './app.setup.js';
import { AppModule } from './app.module.js';
import { ENV, type Env } from './config/index.js';

// Happy Eyeballs (RFC 8305): пробуем IPv4 и IPv6 наперегонки и берём тот адрес,
// который ответил первым.
//
// Зачем: у Яндекса есть и A, и AAAA-записи. Если в сети, где работает сервер,
// IPv6 объявлен, но не проходит, `fetch` молча висит на попытке подключения
// до собственного таймаута — вход через Яндекс ID падает с `provider_unavailable`,
// хотя сервис доступен. Поймано на живом входе: TCP к IPv4 занимал 311 мс,
// к IPv6 — не завершался вовсе. С переключением ответ приходит за ~1 с.
//
// Ставится до создания приложения: значение читается при установке соединения.
net.setDefaultAutoSelectFamily(true);
net.setDefaultAutoSelectFamilyAttemptTimeout(500);

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

  await configureApp(app);

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
