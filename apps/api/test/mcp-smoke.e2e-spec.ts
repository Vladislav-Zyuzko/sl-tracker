import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { loadEnv } from '../src/config/env.js';
import { DB } from '../src/database/index.js';
import type * as schema from '../src/database/schema/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Сквозной путь MCP-клиента (`RFC-MCP-SERVER.md` §1, `SPEC-PAT-API.md` §4 «E2E smoke»).
 *
 * Проверяются ровно те пять операций, ради которых заводился машинный доступ:
 * `create_task`, `update_task_description`, `add_comment`, `set_task_status`, `get_task`.
 * Клиент здесь ходит так же, как настоящий MCP-сервер, — одним заголовком
 * `Authorization: Bearer <токен>`, без cookie и без знания о браузере.
 */
describe('MCP-путь: работа с задачей одним токеном', () => {
  const APP_ORIGIN = new URL(loadEnv().APP_BASE_URL).origin;

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

  const get = (url: string, headers: Headers) => app.inject({ method: 'GET', url, headers });
  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });

  interface Machine {
    /** Человек, которому принадлежит токен: авторство будет его. */
    ownerId: string;
    ownerName: string;
    /** Заголовки MCP-клиента. */
    headers: Headers;
    statuses: Record<string, string>;
  }

  /**
   * Участник проекта выпускает себе токен из браузера и отдаёт его агенту.
   * Дальше в тесте браузер не участвует — работает только токен.
   */
  async function agentOfProjectMember(): Promise<Machine> {
    const adminUser = await seedUser(db, 'Анна Админова');
    const adminSession = await sessions.create(adminUser.id, 'cookie');
    const adminWeb: Headers = {
      cookie: `sl_session=${adminSession.token}`,
      origin: APP_ORIGIN,
    };

    const project = await seedProject(db, {
      name: 'Сладкий Лимит',
      slug: 'sladkiy-limit',
      adminId: adminUser.id,
    });

    const ownerUser = await seedUser(db, 'Борис Участников');
    await addProjectMember(db, project.id, ownerUser.id, 'member');
    const ownerSession = await sessions.create(ownerUser.id, 'cookie');
    const ownerWeb: Headers = {
      cookie: `sl_session=${ownerSession.token}`,
      origin: APP_ORIGIN,
    };

    const queue = await post('/api/projects/sladkiy-limit/queues', adminWeb, {
      key: 'DEV',
      name: 'Разработка',
    });
    expect(queue.statusCode).toBe(201);

    const issued = await post('/api/tokens', ownerWeb, { name: 'dsh-mcp', expiresInDays: 365 });
    expect(issued.statusCode).toBe(201);

    const statusList = (await get('/api/queues/DEV/statuses', ownerWeb)).json<{
      items: { key: string; id: string }[];
    }>();
    const statuses: Record<string, string> = {};
    for (const status of statusList.items) {
      statuses[status.key] = status.id;
    }

    return {
      ownerId: ownerUser.id,
      ownerName: 'Борис Участников',
      headers: { authorization: `Bearer ${issued.json<{ token: string }>().token}` },
      statuses,
    };
  }

  it('создаёт задачу, правит описание, комментирует, меняет статус и читает результат', async () => {
    const agent = await agentOfProjectMember();

    // create_task
    const created = await post('/api/queues/DEV/issues', agent.headers, {
      title: 'Собрать отчёт по нагрузке',
      description: 'Черновик от агента',
    });
    expect(created.statusCode).toBe(201);
    const key = created.json<{ key: string }>().key;
    expect(key).toBe('DEV-1');

    // update_task_description
    const described = await patch(`/api/issues/${key}`, agent.headers, {
      description: 'Уточнённое описание: нужны графики p95 за неделю',
    });
    expect(described.statusCode).toBe(200);

    // add_comment
    const commented = await post(`/api/issues/${key}/comments`, agent.headers, {
      body: 'Взял в работу, отчёт будет к вечеру',
    });
    expect(commented.statusCode).toBe(201);

    // set_task_status
    const moved = await patch(`/api/issues/${key}`, agent.headers, {
      statusId: agent.statuses.in_progress,
    });
    expect(moved.statusCode).toBe(200);

    // get_task
    const read = await get(`/api/issues/${key}`, agent.headers);
    expect(read.statusCode).toBe(200);
    const issue = read.json<{
      title: string;
      description: string | null;
      status: { key: string };
      author: { id: string; displayName: string };
    }>();

    expect(issue.title).toBe('Собрать отчёт по нагрузке');
    expect(issue.description).toBe('Уточнённое описание: нужны графики p95 за неделю');
    expect(issue.status.key).toBe('in_progress');
    // Авторство честное: задача подписана человеком, выдавшим токен, без пометки «бот».
    expect(issue.author).toMatchObject({ id: agent.ownerId, displayName: agent.ownerName });

    const comments = (await get(`/api/issues/${key}/comments`, agent.headers)).json<{
      items: { body: string; author: { id: string } }[];
    }>();
    expect(comments.items).toHaveLength(1);
    expect(comments.items[0]).toMatchObject({
      body: 'Взял в работу, отчёт будет к вечеру',
      author: { id: agent.ownerId },
    });

    // История изменений видит того же человека: отдельной машинной идентичности нет.
    const history = (await get(`/api/issues/${key}/history`, agent.headers)).json<{
      items: { actor: { id: string; displayName: string }; changes: { kind: string }[] }[];
    }>();
    const kinds = history.items.flatMap((item) => item.changes.map((change) => change.kind));
    expect(kinds).toContain('issue_created');
    expect(kinds).toContain('status_changed');
    for (const item of history.items) {
      expect(item.actor.id).toBe(agent.ownerId);
    }
  });
});
