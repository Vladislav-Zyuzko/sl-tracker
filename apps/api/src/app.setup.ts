import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import type { NestFastifyApplication } from '@nestjs/platform-fastify';
import { DocumentBuilder, type OpenAPIObject, SwaggerModule } from '@nestjs/swagger';
import { AllExceptionsFilter } from './common/index.js';

/** Глобальный префикс. Caddy проксирует в API именно `/api/*` (ADR-0001, ADR-0005). */
export const API_PREFIX = 'api';

/**
 * Настройка приложения, общая для боевого запуска, e2e-тестов и генерации OpenAPI.
 * Держится в одном месте, чтобы тесты и сгенерированный контракт не разъезжались
 * с тем, что реально поднимается на сервере.
 */
export function configureApp(app: NestFastifyApplication): void {
  app.setGlobalPrefix(API_PREFIX);
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: undefined });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      // Наружу — только текст ошибки валидации, без внутренних деталей.
      disableErrorMessages: false,
    }),
  );

  app.useGlobalFilters(new AllExceptionsFilter());
  app.enableShutdownHooks();
}

export function buildOpenApiDocument(app: NestFastifyApplication): OpenAPIObject {
  const config = new DocumentBuilder()
    .setTitle('SL Tracker API')
    .setDescription(
      'HTTP API трекера задач SL Tracker. Единственный источник правды по контракту: ' +
        'файл генерируется из кода, руками не редактируется.',
    )
    .setVersion('0.1.0')
    .addCookieAuth('sl_session', {
      type: 'apiKey',
      in: 'cookie',
      name: 'sl_session',
      description: 'Сессия веб-клиента: httpOnly Secure SameSite=Lax cookie (ADR-0001).',
    })
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        // Токен непрозрачный, а не JWT: состояние сессии живёт на сервере,
        // иначе отзыв доступа не сработал бы до истечения токена (ADR-0006).
        bearerFormat: 'opaque',
        description: 'Сессия будущего мобильного клиента (ADR-0002).',
      },
      'bearer',
    )
    .build();

  return SwaggerModule.createDocument(app, config);
}

export function setupSwagger(app: NestFastifyApplication): void {
  const document = buildOpenApiDocument(app);
  SwaggerModule.setup(`${API_PREFIX}/docs`, app, document, {
    jsonDocumentUrl: `${API_PREFIX}/docs/openapi.json`,
  });
  Logger.log(`Swagger UI: /${API_PREFIX}/docs`, 'Bootstrap');
}
