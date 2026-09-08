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
import {
  addProjectMember,
  seedIssue,
  seedProject,
  seedQueueInProject,
  seedUser,
  truncateAll,
} from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Список активных задач пользователя и поиск по нему — сайдбар (US-81, US-82, D-20).
 *
 * Эндпоинтов создания задач ещё нет, поэтому задачи кладутся в базу фикстурой:
 * проверяется именно выборка — условие активности, порядок, поиск и границы видимости.
 */
describe('Мои активные задачи', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let sessions: SessionService;

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

  async function signIn(displayName: string): Promise<{ id: string; headers: Headers }> {
    const user = await seedUser(db, displayName);
    const session = await sessions.create(user.id, 'bearer');
    return { id: user.id, headers: { authorization: `Bearer ${session.token}` } };
  }

  function get(url: string, headers: Headers) {
    return app.inject({ method: 'GET', url, headers });
  }

  /**
   * Проект с очередью и набором задач: одна закрытая, одна чужая и две активные
   * с разным приоритетом.
   */
  async function seedWorkspace() {
    const anna = await signIn('Анна');
    const boris = await signIn('Борис');

    const project = await seedProject(db, {
      name: 'Проект',
      slug: 'proekt',
      adminId: anna.id,
    });
    await addProjectMember(db, project.id, boris.id, 'member');
    const queue = await seedQueueInProject(db, project.id, 'DEV', anna.id);

    await seedIssue(db, {
      queueId: queue.queueId,
      queueKey: 'DEV',
      number: 1,
      title: 'Автоматизация отчёта',
      statusId: queue.statusIds.open!,
      authorId: anna.id,
      assigneeId: anna.id,
      priority: 30,
    });
    await seedIssue(db, {
      queueId: queue.queueId,
      queueKey: 'DEV',
      number: 2,
      title: 'Починить сборку',
      statusId: queue.statusIds.in_progress!,
      authorId: anna.id,
      assigneeId: anna.id,
      priority: 80,
    });
    await seedIssue(db, {
      queueId: queue.queueId,
      queueKey: 'DEV',
      number: 3,
      title: 'Уже закрытая задача',
      statusId: queue.statusIds.closed!,
      authorId: anna.id,
      assigneeId: anna.id,
      priority: 90,
    });
    await seedIssue(db, {
      queueId: queue.queueId,
      queueKey: 'DEV',
      number: 4,
      title: 'Задача Бориса',
      statusId: queue.statusIds.open!,
      authorId: boris.id,
      assigneeId: boris.id,
      priority: 100,
    });
    await seedIssue(db, {
      queueId: queue.queueId,
      queueKey: 'DEV',
      number: 5,
      title: 'Ничья задача',
      statusId: queue.statusIds.open!,
      authorId: anna.id,
      assigneeId: null,
      priority: 100,
    });

    return { anna, boris, project, queue };
  }

  it('показывает только незакрытые задачи, где пользователь исполнитель', async () => {
    const { anna } = await seedWorkspace();

    const response = await get('/api/issues/my-active', anna.headers);

    expect(response.statusCode).toBe(200);
    expect(response.json().total).toBe(2);
    expect(response.json().items.map((item: { key: string }) => item.key)).toEqual([
      'DEV-2',
      'DEV-1',
    ]);
  });

  it('отдаёт ключ, тему, приоритет и статус', async () => {
    const { anna } = await seedWorkspace();

    const response = await get('/api/issues/my-active', anna.headers);

    expect(response.json().items[0]).toEqual({
      key: 'DEV-2',
      title: 'Починить сборку',
      priority: 80,
      status: { key: 'in_progress', name: 'В работе', category: 'in_progress' },
    });
  });

  it('сортирует по убыванию приоритета', async () => {
    const { anna } = await seedWorkspace();

    const priorities = (await get('/api/issues/my-active', anna.headers))
      .json()
      .items.map((item: { priority: number }) => item.priority);

    expect(priorities).toEqual([80, 30]);
  });

  it('ищет по подстроке в теме, без учёта регистра', async () => {
    const { anna } = await seedWorkspace();

    const response = await get('/api/issues/my-active?q=%D0%B0%D0%B2%D1%82%D0%BE', anna.headers);

    expect(response.json().items).toHaveLength(1);
    expect(response.json().items[0].key).toBe('DEV-1');
    // Счётчик у заголовка списка поиском не сужается.
    expect(response.json().total).toBe(2);
  });

  it('ищет по ключу задачи: dev-2 находит DEV-2', async () => {
    const { anna } = await seedWorkspace();

    const response = await get('/api/issues/my-active?q=dev-2', anna.headers);

    expect(response.json().items.map((item: { key: string }) => item.key)).toEqual(['DEV-2']);
  });

  it('поиск не выводит чужие и закрытые задачи (D-20)', async () => {
    const { anna } = await seedWorkspace();

    const foreign = await get(
      '/api/issues/my-active?q=%D0%91%D0%BE%D1%80%D0%B8%D1%81',
      anna.headers,
    );
    const closed = await get(
      '/api/issues/my-active?q=%D0%B7%D0%B0%D0%BA%D1%80%D1%8B%D1%82',
      anna.headers,
    );

    expect(foreign.json().items).toHaveLength(0);
    expect(closed.json().items).toHaveLength(0);
  });

  it('символы шаблона LIKE в запросе ничего не ломают', async () => {
    const { anna } = await seedWorkspace();

    const response = await get('/api/issues/my-active?q=%25', anna.headers);
    expect(response.statusCode).toBe(200);
    expect(response.json().items).toHaveLength(0);
  });

  it('после исключения из проекта задачи исчезают из списка (D-31)', async () => {
    const { anna, boris, project } = await seedWorkspace();

    expect((await get('/api/issues/my-active', boris.headers)).json().total).toBe(1);

    const removed = await app.inject({
      method: 'DELETE',
      url: `/api/projects/${project.slug}/members/${boris.id}`,
      headers: anna.headers,
    });
    expect(removed.statusCode).toBe(200);
    expect(removed.json().unassignedIssues).toBe(1);

    const after = await get('/api/issues/my-active', boris.headers);
    expect(after.json().items).toHaveLength(0);
    expect(after.json().total).toBe(0);
  });

  it('листает страницами', async () => {
    const { anna } = await seedWorkspace();

    const first = await get('/api/issues/my-active?limit=1', anna.headers);
    expect(first.json().items).toHaveLength(1);
    expect(first.json().nextCursor).not.toBeNull();

    const second = await get(
      `/api/issues/my-active?limit=1&cursor=${encodeURIComponent(first.json().nextCursor)}`,
      anna.headers,
    );
    expect(second.json().items.map((item: { key: string }) => item.key)).toEqual(['DEV-1']);
    expect(second.json().nextCursor).toBeNull();
  });

  it('без сессии список не отдаётся', async () => {
    const response = await app.inject({ method: 'GET', url: '/api/issues/my-active' });
    expect(response.statusCode).toBe(401);
  });
});
