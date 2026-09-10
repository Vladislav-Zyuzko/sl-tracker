import { randomUUID } from 'node:crypto';
import {
  afterAll,
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  jest,
} from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { eq, sql } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { DB } from '../src/database/index.js';
import * as schema from '../src/database/schema/index.js';
import { IssueAccessService } from '../src/issues/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { ObjectStorageService } from '../src/storage/index.js';
import { seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Запись в задачу, которую в этот же момент удаляют (DEF-02).
 *
 * Гонка воспроизводится не «двумя запросами наперегонки» — так она ловится через раз, —
 * а точно: задача удаляется **после** проверки прав и **до** вставки, ровно в то окно,
 * из-за которого приходил 500. Проверка прав подменяется на время теста, продуктовый код
 * при этом настоящий целиком.
 *
 * Ожидание: 404 «задача не найдена» — тот же ответ, что и на удалённую задачу, — и ни
 * одной осиротевшей строки. Для вложений вдобавок: файл, который успел лечь в MinIO,
 * не остаётся там навсегда.
 */
describe('Запись в удаляемую задачу', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let sessions: SessionService;
  let access: IssueAccessService;
  let storage: ObjectStorageService;

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
    access = app.get(IssueAccessService);
    storage = app.get(ObjectStorageService);
  });

  afterAll(async () => {
    await app.close();
    await pool.end();
  });

  beforeEach(async () => {
    await truncateAll(db);
    await redis.flushdb();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  type Headers = Record<string, string>;

  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });

  /** Пользователь с проектом, очередью и задачей — всё через API. */
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

  /**
   * Задача исчезает сразу после того, как проверка прав её увидела: то самое окно,
   * в котором вставка встречает задачу уже удалённой.
   */
  function deleteIssueAfterAccessCheck(): void {
    const original = access.require.bind(access);
    let done = false;

    jest.spyOn(access, 'require').mockImplementation(async (key, user) => {
      const context = await original(key, user);
      if (!done) {
        done = true;
        await db.delete(schema.issues).where(eq(schema.issues.id, context.detail.issue.id));
      }
      return context;
    });
  }

  async function countOf(table: 'comments' | 'issue_links' | 'attachments'): Promise<number> {
    const rows = await db.execute<{ value: number }>(
      sql`select count(*)::int as value from ${sql.identifier(table)}`,
    );
    return Number(rows.rows[0]?.value ?? 0);
  }

  /** Тело multipart с одним файлом: `app.inject` формы сам не собирает. */
  function upload(issueKey: string, headers: Headers, content: Buffer) {
    const boundary = `----sl${randomUUID().replace(/-/g, '')}`;
    const head = Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="note.txt"\r\n` +
        'Content-Type: text/plain\r\n\r\n',
      'utf8',
    );
    const tail = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

    return app.inject({
      method: 'POST',
      url: `/api/issues/${issueKey}/attachments`,
      headers: { ...headers, 'content-type': `multipart/form-data; boundary=${boundary}` },
      payload: Buffer.concat([head, content, tail]),
    });
  }

  it('комментарий в исчезнувшую задачу — 404, а не 500', async () => {
    const { headers, issueKey } = await seedWorkspace();
    deleteIssueAfterAccessCheck();

    const response = await post(`/api/issues/${issueKey}/comments`, headers, { body: 'Успею ли?' });

    expect(response.statusCode).toBe(404);
    expect(response.json().code).toBe('issue_not_found');
    expect(await countOf('comments')).toBe(0);
  });

  it('ссылка на исчезнувшую задачу — 404, а не 500', async () => {
    const { headers, issueKey } = await seedWorkspace();
    deleteIssueAfterAccessCheck();

    const response = await post(`/api/issues/${issueKey}/links`, headers, {
      url: 'https://example.com/spec',
      title: 'Спека',
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().code).toBe('issue_not_found');
    expect(await countOf('issue_links')).toBe(0);
  });

  it('вложение в исчезнувшую задачу — 404, и файл в хранилище не остаётся', async () => {
    const { headers, issueKey } = await seedWorkspace();

    // Ключ объекта, который сервер сгенерировал для этой загрузки: по нему потом
    // проверяется, что в бакете действительно ничего не осталось.
    const keys: string[] = [];
    const put = storage.put.bind(storage);
    jest.spyOn(storage, 'put').mockImplementation(async (objectKey, body, contentType) => {
      keys.push(objectKey);
      return put(objectKey, body, contentType);
    });

    deleteIssueAfterAccessCheck();

    const response = await upload(issueKey, headers, Buffer.from('содержимое', 'utf8'));

    expect(response.statusCode).toBe(404);
    expect(response.json().code).toBe('issue_not_found');
    expect(await countOf('attachments')).toBe(0);

    expect(keys).toHaveLength(1);
    const orphan = await fetch(await storage.signedUrl(keys[0]!));
    expect(orphan.status).toBe(404);
  });

  it('без гонки те же три записи проходят как обычно', async () => {
    const { headers, issueKey } = await seedWorkspace();

    const comment = await post(`/api/issues/${issueKey}/comments`, headers, { body: 'Обычный' });
    const link = await post(`/api/issues/${issueKey}/links`, headers, {
      url: 'https://example.com/spec',
    });
    const attachment = await upload(issueKey, headers, Buffer.from('файл', 'utf8'));

    expect([comment.statusCode, link.statusCode, attachment.statusCode]).toEqual([201, 201, 201]);
  });
});
