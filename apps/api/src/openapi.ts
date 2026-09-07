/**
 * Генерация `docs/api/openapi.json` из кода.
 *
 * Скрипт лежит в `src/` и запускается уже собранным (`node dist/openapi.js`) намеренно:
 * метаданные для Swagger дают декораторы и плагин `@nestjs/swagger`, который работает
 * только на сборке через `nest build`. Запуск исходника через esbuild/tsx метаданные
 * теряет, и контракт получается беднее того, что реально отдаёт сервер.
 *
 * Файл контракта руками не редактируется: по нему фронтенд генерирует клиент,
 * и расхождение обнаружилось бы только в проде.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { AppModule } from './app.module.js';
import { buildOpenApiDocument, configureApp } from './app.setup.js';

const here = dirname(fileURLToPath(import.meta.url));
const OUTPUT = resolve(here, '../../../docs/api/openapi.json');

async function main(): Promise<void> {
  const app = await NestFactory.create<NestFastifyApplication>(AppModule, new FastifyAdapter(), {
    logger: ['error', 'warn'],
  });
  await configureApp(app);
  await app.init();

  const document = buildOpenApiDocument(app);
  mkdirSync(dirname(OUTPUT), { recursive: true });
  writeFileSync(OUTPUT, `${JSON.stringify(document, null, 2)}\n`, 'utf8');

  await app.close();
  console.warn(`OpenAPI записан: ${OUTPUT}`);
}

await main();
