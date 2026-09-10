import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { DB } from '../src/database/index.js';
import type * as schema from '../src/database/schema/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Общий слой проверки запроса: то, что должно вести себя одинаково во всех эндпоинтах.
 *
 * Здесь два правила, и оба закреплены дефектами:
 *  - нулевой символ в тексте отклоняется на входе, а не роняет запрос в базе (DEF-03);
 *  - у **любого** отказа 400 есть машиночитаемый код и русский текст, независимо
 *    от того, кто его заметил — проверка DTO или доменный код (DEF-04).
 */
describe('Проверка запроса', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let sessions: SessionService;

  /** `U+0000`: PostgreSQL не хранит его в `text` ни в каком поле. */
  const NUL = String.fromCharCode(0);

  beforeAll(async () => {
    await prepareTestDatabase();
    pool = createTestPool(10);
    db = createTestDb(pool);

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DB)
      .useValue(db)
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter(), {
      logger: false,
    });
    await configureApp(app);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    redis = app.get<Redis>(REDIS);
    sessions = app.get(SessionService);
  });

  afterAll(async () => {
    await app.close();
    await pool.end();
  });

  beforeEach(async () => {
    await truncateAll(db);
    await redis.flushdb();
  });

  type Headers = Record<string, string>;

  const post = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });

  /** Пользователь с проектом, очередью и одной задачей — всё через API. */
  async function seedWorkspace(): Promise<{ headers: Headers; issueKey: string }> {
    const user = await seedUser(db, 'Анна Админова');
    const session = await sessions.create(user.id, 'bearer');
    const headers = { authorization: `Bearer ${session.token}` };

    const project = await post('/api/projects', headers, { name: 'Сладкий Лимит' });
    await post(`/api/projects/${project.json().slug}/queues`, headers, {
      key: 'DEV',
      name: 'Разработка',
    });
    const issue = await post('/api/queues/DEV/issues', headers, { title: 'Задача' });

    return { headers, issueKey: issue.json().key };
  }

  describe('DEF-03: нулевой символ', () => {
    it('название задачи с нулевым символом отклоняется, а не роняет сервер', async () => {
      const { headers } = await seedWorkspace();

      const response = await post('/api/queues/DEV/issues', headers, {
        title: `до${NUL}после`,
      });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_characters');
    });

    it('то же и в описании задачи, тексте комментария, названии проекта и подписи ссылки', async () => {
      const { headers, issueKey } = await seedWorkspace();

      const cases = [
        await post('/api/queues/DEV/issues', headers, {
          title: 'Задача с нулём в описании',
          description: `до${NUL}после`,
        }),
        await post(`/api/issues/${issueKey}/comments`, headers, { body: `до${NUL}после` }),
        await post('/api/projects', headers, { name: `Проект${NUL}ноль` }),
        await post(`/api/issues/${issueKey}/links`, headers, {
          url: 'https://example.com/nul',
          title: `до${NUL}после`,
        }),
        await patch(`/api/issues/${issueKey}`, headers, { title: `до${NUL}после` }),
      ];

      for (const response of cases) {
        expect(response.statusCode).toBe(400);
        expect(response.json().code).toBe('invalid_characters');
      }
    });

    it('нулевой символ в строке запроса тоже отклоняется', async () => {
      const { headers } = await seedWorkspace();

      const response = await app.inject({
        method: 'GET',
        url: `/api/issues/my-active?q=${encodeURIComponent(`до${NUL}после`)}`,
        headers,
      });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_characters');
    });

    it('прочие «страшные» строки сохраняются дословно (D-22, Н-4)', async () => {
      const { headers } = await seedWorkspace();
      const title = "'; drop table issues; -- <script>alert(1)</script> 🎉 файл‮gnp.exe";

      const created = await post('/api/queues/DEV/issues', headers, { title });

      expect(created.statusCode).toBe(201);
      expect(created.json().title).toBe(title);
    });
  });

  describe('DEF-04: машиночитаемый код у любого отказа 400', () => {
    it('слишком длинное название отвечает тем же кодом, что и пустое', async () => {
      const { headers } = await seedWorkspace();

      const tooLong = await post('/api/queues/DEV/issues', headers, { title: 'я'.repeat(256) });
      const empty = await post('/api/queues/DEV/issues', headers, { title: '   ' });

      expect(tooLong.statusCode).toBe(400);
      expect(tooLong.json().code).toBe('invalid_issue_title');
      expect(empty.json().code).toBe('invalid_issue_title');
      // Один код — один текст: клиент не должен видеть два разных объяснения.
      expect(tooLong.json().message).toBe(empty.json().message);
    });

    it('слишком длинный комментарий приходит с `invalid_comment_body`', async () => {
      const { headers, issueKey } = await seedWorkspace();

      const response = await post(`/api/issues/${issueKey}/comments`, headers, {
        body: 'т'.repeat(10_001),
      });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_comment_body');
    });

    it('приоритет вне шкалы отвечает общим кодом и называет поле', async () => {
      const { headers, issueKey } = await seedWorkspace();

      const response = await patch(`/api/issues/${issueKey}`, headers, { priority: 55 });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_request');
      expect(response.json().message).toContain('priority');
    });

    it('английский текст библиотеки проверки наружу не уходит', async () => {
      const { headers } = await seedWorkspace();

      const response = await post('/api/queues/DEV/issues', headers, { title: 'я'.repeat(256) });

      expect(response.body).not.toContain('must be');
      expect(Array.isArray(response.json().message)).toBe(false);
    });

    it('неизвестное поле в теле отклоняется, а не пропускается молча', async () => {
      const { headers } = await seedWorkspace();

      const response = await post('/api/queues/DEV/issues', headers, {
        title: 'Задача',
        hacker: true,
      });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_request');
    });

    it('доменные отказы свой код сохранили', async () => {
      const { headers, issueKey } = await seedWorkspace();

      const link = await post(`/api/issues/${issueKey}/links`, headers, {
        url: 'javascript:alert(1)',
      });
      const project = await post('/api/projects', headers, { name: '   ' });

      expect(link.json().code).toBe('invalid_link_url');
      expect(project.json().code).toBe('invalid_project_name');
    });
  });
});
