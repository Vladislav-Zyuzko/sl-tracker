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
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Очереди и их статусы (US-30 … US-34, US-60).
 *
 * Проверяется поведение, которое нельзя увидеть в unit-тесте: глобальная уникальность
 * ключа, бронь ключа после удаления очереди, отказ удалять непустую очередь и границы
 * видимости — чужой проект отвечает 404, а не 403.
 */
describe('Очереди', () => {
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

  const get = (url: string, headers: Headers) => app.inject({ method: 'GET', url, headers });
  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });
  const del = (url: string, headers: Headers) => app.inject({ method: 'DELETE', url, headers });

  /** Проект с админом, участником и читателем — базовая расстановка для проверки прав. */
  async function seedTeam() {
    const admin = await signIn('Анна Админова');
    const member = await signIn('Борис Участников');
    const reader = await signIn('Вера Читателева');
    const outsider = await signIn('Гриша Посторонний');

    const project = await seedProject(db, {
      name: 'Сладкий Лимит',
      slug: 'sladkiy-limit',
      adminId: admin.id,
    });
    await addProjectMember(db, project.id, member.id, 'member');
    await addProjectMember(db, project.id, reader.id, 'reader');

    return { admin, member, reader, outsider, project };
  }

  describe('Создание (US-30)', () => {
    it('администратор создаёт очередь и сразу получает пять статусов по умолчанию', async () => {
      const { admin } = await seedTeam();

      const response = await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
        description: 'Задачи команды разработки',
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.key).toBe('DEV');
      expect(body.name).toBe('Разработка');
      expect(body.openIssueCount).toBe(0);
      expect(body.projectSlug).toBe('sladkiy-limit');
      expect(body.role).toBe('admin');
      expect(body.statuses.map((status: { key: string }) => status.key)).toEqual([
        'open',
        'in_progress',
        'review',
        'testing',
        'closed',
      ]);
      expect(body.statuses.map((status: { category: string }) => status.category)).toEqual([
        'open',
        'in_progress',
        'in_progress',
        'in_progress',
        'done',
      ]);
    });

    it('ключ приводится к верхнему регистру', async () => {
      const { admin } = await seedTeam();
      const response = await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'dev',
        name: 'Разработка',
      });
      expect(response.statusCode).toBe(201);
      expect(response.json().key).toBe('DEV');
    });

    it('ключ не по формату отклоняется', async () => {
      const { admin } = await seedTeam();
      for (const key of ['D', '1DEV', 'DEV-1', 'РАЗРАБОТКА', 'DEVELOPMENTX']) {
        const response = await post('/api/projects/sladkiy-limit/queues', admin.headers, {
          key,
          name: 'Очередь',
        });
        expect(response.statusCode).toBe(400);
      }
    });

    it('ключ уникален на весь трекер: занятый в чужом проекте даёт 409', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const other = await signIn('Дмитрий Другой');
      await seedProject(db, { name: 'Другой проект', slug: 'drugoy', adminId: other.id });

      const response = await post('/api/projects/drugoy/queues', other.headers, {
        key: 'DEV',
        name: 'Своя разработка',
      });

      expect(response.statusCode).toBe(409);
      const body = response.json();
      expect(body.code).toBe('queue_key_taken');
      // Ответ не раскрывает, в каком именно проекте ключ занят.
      expect(JSON.stringify(body)).not.toContain('sladkiy-limit');
      expect(JSON.stringify(body)).not.toContain('Сладкий Лимит');
    });

    it('участник и читатель создать очередь не могут', async () => {
      const { member, reader } = await seedTeam();
      for (const actor of [member, reader]) {
        const response = await post('/api/projects/sladkiy-limit/queues', actor.headers, {
          key: 'DEV',
          name: 'Разработка',
        });
        expect(response.statusCode).toBe(403);
        expect(response.json().code).toBe('project_forbidden');
      }
    });

    it('не участник проекта получает 404, а не 403', async () => {
      const { outsider } = await seedTeam();
      const response = await post('/api/projects/sladkiy-limit/queues', outsider.headers, {
        key: 'DEV',
        name: 'Разработка',
      });
      expect(response.statusCode).toBe(404);
    });
  });

  describe('Список очередей проекта (US-31)', () => {
    it('виден всем участникам, включая читателя, и отсортирован по названию', async () => {
      const { admin, reader } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'OPS',
        name: 'Эксплуатация',
      });
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const response = await get('/api/projects/sladkiy-limit/queues', reader.headers);
      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.items.map((queue: { key: string }) => queue.key)).toEqual(['DEV', 'OPS']);
      expect(body.items[0].role).toBe('reader');
      expect(body.total).toBe(2);
    });

    it('не участник не видит списка очередей чужого проекта', async () => {
      const { outsider } = await seedTeam();
      const response = await get('/api/projects/sladkiy-limit/queues', outsider.headers);
      expect(response.statusCode).toBe(404);
    });
  });

  describe('Чтение очереди и её статусов (US-60)', () => {
    it('ключ в адресе регистронезависим', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const lower = await get('/api/queues/dev', admin.headers);
      const upper = await get('/api/queues/DEV', admin.headers);
      expect(lower.statusCode).toBe(200);
      expect(upper.statusCode).toBe(200);
      expect(lower.json().key).toBe('DEV');
    });

    it('статусы отдаются в фиксированном порядке и принадлежат своей очереди', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'OPS',
        name: 'Эксплуатация',
      });

      const dev = (await get('/api/queues/DEV/statuses', admin.headers)).json();
      const ops = (await get('/api/queues/OPS/statuses', admin.headers)).json();

      expect(dev.items.map((status: { position: number }) => status.position)).toEqual([
        1, 2, 3, 4, 5,
      ]);
      const devIds: string[] = dev.items.map((status: { id: string }) => status.id);
      const opsIds: string[] = ops.items.map((status: { id: string }) => status.id);
      expect(devIds.some((id) => opsIds.includes(id))).toBe(false);
    });

    it('чужая очередь неотличима от несуществующей: обе 404', async () => {
      const { admin, outsider } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const foreign = await get('/api/queues/DEV', outsider.headers);
      const missing = await get('/api/queues/NOPE', outsider.headers);
      expect(foreign.statusCode).toBe(404);
      expect(missing.statusCode).toBe(404);
      expect(foreign.json().code).toBe(missing.json().code);
      expect(JSON.stringify(foreign.json())).not.toContain('Разработка');
    });
  });

  describe('Переименование (US-33)', () => {
    it('администратор меняет название и описание, ключ остаётся прежним', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const response = await patch('/api/queues/DEV', admin.headers, {
        name: 'Продуктовая разработка',
        description: 'Обновлённое описание',
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({
        key: 'DEV',
        name: 'Продуктовая разработка',
        description: 'Обновлённое описание',
      });
    });

    it('ключ изменить нельзя: поле в теле запроса не принимается', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      const response = await patch('/api/queues/DEV', admin.headers, { key: 'OPS' });
      expect(response.statusCode).toBe(400);
      expect((await get('/api/queues/DEV', admin.headers)).statusCode).toBe(200);
    });

    it('участник и читатель переименовать очередь не могут', async () => {
      const { admin, member, reader } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      for (const actor of [member, reader]) {
        const response = await patch('/api/queues/DEV', actor.headers, { name: 'Своё название' });
        expect(response.statusCode).toBe(403);
      }
    });
  });

  describe('Удаление (US-34, D-24, D-25)', () => {
    it('пустая очередь удаляется, а её ключ остаётся занятым навсегда', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      expect((await del('/api/queues/DEV', admin.headers)).statusCode).toBe(204);
      expect((await get('/api/queues/DEV', admin.headers)).statusCode).toBe(404);

      const again = await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Снова разработка',
      });
      expect(again.statusCode).toBe(409);
      expect(again.json().code).toBe('queue_key_taken');
    });

    it('непустая очередь не удаляется', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });
      await post('/api/queues/DEV/issues', admin.headers, { title: 'Первая задача' });

      const response = await del('/api/queues/DEV', admin.headers);
      expect(response.statusCode).toBe(409);
      expect(response.json().code).toBe('queue_not_empty');
      expect((await get('/api/queues/DEV', admin.headers)).statusCode).toBe(200);
    });

    it('закрытая задача тоже держит очередь: проверяется наличие задач в любом статусе', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });
      const statuses = (await get('/api/queues/DEV/statuses', admin.headers)).json();
      const closed = statuses.items.find((status: { key: string }) => status.key === 'closed');
      const issue = (
        await post('/api/queues/DEV/issues', admin.headers, { title: 'Задача' })
      ).json();
      await patch(`/api/issues/${issue.key}`, admin.headers, { statusId: closed.id });

      const response = await del('/api/queues/DEV', admin.headers);
      expect(response.statusCode).toBe(409);
    });

    it('участник и читатель очередь не удаляют', async () => {
      const { admin, member, reader } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });

      for (const actor of [member, reader]) {
        expect((await del('/api/queues/DEV', actor.headers)).statusCode).toBe(403);
      }
    });
  });

  describe('Счётчик незавершённых задач (US-31)', () => {
    it('считает задачи вне категории done', async () => {
      const { admin } = await seedTeam();
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'DEV',
        name: 'Разработка',
      });
      const statuses = (await get('/api/queues/DEV/statuses', admin.headers)).json();
      const closed = statuses.items.find((status: { key: string }) => status.key === 'closed');

      await post('/api/queues/DEV/issues', admin.headers, { title: 'Открытая' });
      await post('/api/queues/DEV/issues', admin.headers, { title: 'Тоже открытая' });
      const third = (
        await post('/api/queues/DEV/issues', admin.headers, { title: 'Закрытая' })
      ).json();
      await patch(`/api/issues/${third.key}`, admin.headers, { statusId: closed.id });

      const list = (await get('/api/projects/sladkiy-limit/queues', admin.headers)).json();
      expect(list.items[0].openIssueCount).toBe(2);
      expect((await get('/api/queues/DEV', admin.headers)).json().openIssueCount).toBe(2);
    });
  });
});
