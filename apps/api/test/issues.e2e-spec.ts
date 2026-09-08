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
 * Задачи: создание и ключи, чтение по ключу, изменение полей, удаление, список
 * очереди и история изменений (US-40 … US-44, US-47, US-50 … US-53, US-61, US-90 … US-92).
 *
 * Права проверяются на каждом действии, включая негативный случай: читатель ничего
 * не меняет, участник не удаляет, посторонний получает 404 без единого поля задачи.
 */
describe('Задачи', () => {
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
  interface Actor {
    id: string;
    displayName: string;
    headers: Headers;
  }

  async function signIn(displayName: string): Promise<Actor> {
    const user = await seedUser(db, displayName);
    const session = await sessions.create(user.id, 'bearer');
    return { id: user.id, displayName, headers: { authorization: `Bearer ${session.token}` } };
  }

  const get = (url: string, headers: Headers) => app.inject({ method: 'GET', url, headers });
  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });
  const del = (url: string, headers: Headers) => app.inject({ method: 'DELETE', url, headers });

  interface Workspace {
    admin: Actor;
    member: Actor;
    reader: Actor;
    outsider: Actor;
    statuses: Record<string, string>;
  }

  /** Проект с очередью `DEV` и полной расстановкой ролей. */
  async function seedWorkspace(): Promise<Workspace> {
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

    await post('/api/projects/sladkiy-limit/queues', admin.headers, {
      key: 'DEV',
      name: 'Разработка',
    });

    const list = (await get('/api/queues/DEV/statuses', admin.headers)).json();
    const statuses: Record<string, string> = {};
    for (const status of list.items as { key: string; id: string }[]) {
      statuses[status.key] = status.id;
    }

    return { admin, member, reader, outsider, statuses };
  }

  /**
   * Ответ задачи в том объёме, в каком его читают тесты. Тип нужен ровно затем,
   * чтобы `any` из `response.json()` не расползался за пределы помощника.
   */
  interface IssueBody {
    key: string;
    title: string;
    description: string | null;
    status: { id: string; key: string; name: string; category: string };
    priority: number;
    storyPoints: number | null;
    author: { id: string; displayName: string };
    assignee: { id: string; displayName: string } | null;
    queue: { key: string; name: string };
    project: { slug: string; name: string };
    links: { id: string; url: string; title: string | null }[];
    role: string;
    permissions: { canEdit: boolean; canDelete: boolean };
  }

  async function createIssue(actor: Actor, body: object = { title: 'Задача' }): Promise<IssueBody> {
    const response = await post('/api/queues/DEV/issues', actor.headers, body);
    expect(response.statusCode).toBe(201);
    const issue: IssueBody = response.json();
    return issue;
  }

  describe('Создание и ключи (US-40, ADR-0004)', () => {
    it('первая задача очереди получает ключ DEV-1 и значения по умолчанию', async () => {
      const { admin } = await seedWorkspace();
      const issue = await createIssue(admin, { title: 'Починить экспорт CSV' });

      expect(issue.key).toBe('DEV-1');
      expect(issue.title).toBe('Починить экспорт CSV');
      expect(issue.description).toBeNull();
      expect(issue.status.key).toBe('open');
      expect(issue.priority).toBe(50);
      expect(issue.storyPoints).toBeNull();
      expect(issue.author.id).toBe(admin.id);
      expect(issue.assignee).toBeNull();
      expect(issue.queue).toEqual({ key: 'DEV', name: 'Разработка' });
      expect(issue.project).toEqual({ slug: 'sladkiy-limit', name: 'Сладкий Лимит' });
      expect(issue.links).toEqual([]);
      expect(issue.permissions).toEqual({ canEdit: true, canDelete: true });
    });

    it('номера растут и не переиспользуются после удаления', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin, { title: 'Первая' });
      const second = await createIssue(admin, { title: 'Вторая' });
      expect(second.key).toBe('DEV-2');

      expect((await del(`/api/issues/${second.key}`, admin.headers)).statusCode).toBe(204);

      const third = await createIssue(admin, { title: 'Третья' });
      expect(third.key).toBe('DEV-3');
      expect((await get('/api/issues/DEV-2', admin.headers)).statusCode).toBe(404);
    });

    it('участник создаёт задачи, читатель — нет', async () => {
      const { member, reader } = await seedWorkspace();
      expect(
        (await post('/api/queues/DEV/issues', member.headers, { title: 'Моя' })).statusCode,
      ).toBe(201);

      const denied = await post('/api/queues/DEV/issues', reader.headers, { title: 'Чужая' });
      expect(denied.statusCode).toBe(403);
      expect(denied.json().code).toBe('issue_forbidden');
    });

    it('посторонний не может создать задачу в чужой очереди и получает 404', async () => {
      const { outsider } = await seedWorkspace();
      const response = await post('/api/queues/DEV/issues', outsider.headers, { title: 'Чужая' });
      expect(response.statusCode).toBe(404);
    });

    it('пустое название не принимается', async () => {
      const { admin } = await seedWorkspace();
      expect(
        (await post('/api/queues/DEV/issues', admin.headers, { title: '   ' })).statusCode,
      ).toBe(400);
      expect((await post('/api/queues/DEV/issues', admin.headers, {})).statusCode).toBe(400);
    });

    it('название длиннее 255 символов отклоняется', async () => {
      const { admin } = await seedWorkspace();
      const response = await post('/api/queues/DEV/issues', admin.headers, {
        title: 'я'.repeat(256),
      });
      expect(response.statusCode).toBe(400);
    });

    it('недопустимый приоритет отклоняется', async () => {
      const { admin } = await seedWorkspace();
      for (const priority of [55, -10, 110, 1]) {
        const response = await post('/api/queues/DEV/issues', admin.headers, {
          title: 'Задача',
          priority,
        });
        expect(response.statusCode).toBe(400);
      }
    });

    it('автором и исполнителем можно назначить только участника проекта', async () => {
      const { admin, member, outsider } = await seedWorkspace();

      const ok = await createIssue(admin, {
        title: 'С исполнителем',
        authorId: member.id,
        assigneeId: member.id,
        storyPoints: 8,
        priority: 80,
      });
      expect(ok.author.displayName).toBe('Борис Участников');
      expect(ok.assignee?.displayName).toBe('Борис Участников');
      expect(ok.storyPoints).toBe(8);
      expect(ok.priority).toBe(80);

      const badAuthor = await post('/api/queues/DEV/issues', admin.headers, {
        title: 'Плохой автор',
        authorId: outsider.id,
      });
      expect(badAuthor.statusCode).toBe(400);
      expect(badAuthor.json().code).toBe('author_not_member');

      const badAssignee = await post('/api/queues/DEV/issues', admin.headers, {
        title: 'Плохой исполнитель',
        assigneeId: outsider.id,
      });
      expect(badAssignee.statusCode).toBe(400);
      expect(badAssignee.json().code).toBe('assignee_not_member');
    });

    it('50 параллельных созданий дают 50 разных ключей (ADR-0004)', async () => {
      const { admin } = await seedWorkspace();
      const responses = await Promise.all(
        Array.from({ length: 50 }, (_, index) =>
          post('/api/queues/DEV/issues', admin.headers, { title: `Задача ${index}` }),
        ),
      );

      expect(responses.every((response) => response.statusCode === 201)).toBe(true);
      const keys = responses.map((response) => response.json<{ key: string }>().key);
      expect(new Set(keys).size).toBe(50);
    });
  });

  describe('Чтение по ключу (US-41)', () => {
    it('ключ регистронезависим', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);

      const lower = await get('/api/issues/dev-1', admin.headers);
      const upper = await get('/api/issues/DEV-1', admin.headers);
      expect(lower.statusCode).toBe(200);
      expect(upper.statusCode).toBe(200);
      expect(lower.json().key).toBe('DEV-1');
    });

    it('читатель видит задачу целиком, но без прав изменения', async () => {
      const { admin, reader } = await seedWorkspace();
      await createIssue(admin, { title: 'Видимая читателю' });

      const response = await get('/api/issues/DEV-1', reader.headers);
      expect(response.statusCode).toBe(200);
      expect(response.json().title).toBe('Видимая читателю');
      expect(response.json().permissions).toEqual({ canEdit: false, canDelete: false });
      expect(response.json().role).toBe('reader');
    });

    it('участник видит задачу и может её менять, но не удалять', async () => {
      const { admin, member } = await seedWorkspace();
      await createIssue(admin);
      const response = await get('/api/issues/DEV-1', member.headers);
      expect(response.json().permissions).toEqual({ canEdit: true, canDelete: false });
    });

    it('чужая и несуществующая задача отвечают одинаково и без данных задачи', async () => {
      const { admin, outsider } = await seedWorkspace();
      await createIssue(admin, { title: 'Секретное название' });

      const foreign = await get('/api/issues/DEV-1', outsider.headers);
      const missing = await get('/api/issues/DEV-9999', outsider.headers);
      expect(foreign.statusCode).toBe(404);
      expect(missing.statusCode).toBe(404);
      expect(foreign.json()).toMatchObject(missing.json());
      expect(JSON.stringify(foreign.json())).not.toContain('Секретное название');
    });
  });

  describe('Изменение полей (US-42, US-50 … US-53, US-61)', () => {
    it('участник меняет чужую задачу, включая статус, приоритет и сложность (D-11)', async () => {
      const { admin, member, statuses } = await seedWorkspace();
      await createIssue(admin, { title: 'Задача администратора' });

      const response = await patch('/api/issues/DEV-1', member.headers, {
        title: 'Переименовал участник',
        statusId: statuses.in_progress,
        priority: 90,
        storyPoints: 13,
        assigneeId: member.id,
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({
        title: 'Переименовал участник',
        priority: 90,
        storyPoints: 13,
      });
      expect(response.json().status.key).toBe('in_progress');
      expect(response.json().assignee.id).toBe(member.id);
    });

    it('переход разрешён из любого статуса в любой, включая возврат назад (D-10)', async () => {
      const { admin, statuses } = await seedWorkspace();
      await createIssue(admin);

      for (const key of ['closed', 'in_progress', 'testing', 'open']) {
        const response = await patch('/api/issues/DEV-1', admin.headers, {
          statusId: statuses[key],
        });
        expect(response.statusCode).toBe(200);
        expect(response.json().status.key).toBe(key);
      }
    });

    it('статус из чужой очереди отклоняется', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);
      await post('/api/projects/sladkiy-limit/queues', admin.headers, {
        key: 'OPS',
        name: 'Эксплуатация',
      });
      const ops = (await get('/api/queues/OPS/statuses', admin.headers)).json();

      const response = await patch('/api/issues/DEV-1', admin.headers, {
        statusId: ops.items[1].id,
      });
      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_status');
    });

    it('приоритет нельзя очистить и нельзя выставить промежуточное значение', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);

      expect((await patch('/api/issues/DEV-1', admin.headers, { priority: 55 })).statusCode).toBe(
        400,
      );
      expect((await patch('/api/issues/DEV-1', admin.headers, { priority: null })).statusCode).toBe(
        400,
      );
      expect((await get('/api/issues/DEV-1', admin.headers)).json().priority).toBe(50);
    });

    it('оценку сложности можно снять, вернув «не оценено»', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin, { title: 'Оценённая', storyPoints: 5 });

      const cleared = await patch('/api/issues/DEV-1', admin.headers, { storyPoints: null });
      expect(cleared.statusCode).toBe(200);
      expect(cleared.json().storyPoints).toBeNull();

      expect((await patch('/api/issues/DEV-1', admin.headers, { storyPoints: 7 })).statusCode).toBe(
        400,
      );
    });

    it('исполнителя можно снять, вернув «Не назначен»', async () => {
      const { admin, member } = await seedWorkspace();
      await createIssue(admin, { title: 'Задача', assigneeId: member.id });

      const cleared = await patch('/api/issues/DEV-1', admin.headers, { assigneeId: null });
      expect(cleared.json().assignee).toBeNull();
    });

    it('описание сохраняется как есть, включая markdown и сырой HTML (D-22)', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);
      const markdown = '# Заголовок\n\n- пункт\n\n<script>alert(1)</script>';

      const response = await patch('/api/issues/DEV-1', admin.headers, { description: markdown });
      expect(response.json().description).toBe(markdown);
    });

    it('описание длиннее 100 000 символов отклоняется', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);
      const response = await patch('/api/issues/DEV-1', admin.headers, {
        description: 'я'.repeat(100_001),
      });
      expect(response.statusCode).toBe(400);
    });

    it('пустое название не сохраняется, прежнее остаётся', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin, { title: 'Исходное название' });

      expect((await patch('/api/issues/DEV-1', admin.headers, { title: '  ' })).statusCode).toBe(
        400,
      );
      expect((await get('/api/issues/DEV-1', admin.headers)).json().title).toBe(
        'Исходное название',
      );
    });

    it('читатель не меняет ничего', async () => {
      const { admin, reader, statuses } = await seedWorkspace();
      await createIssue(admin);

      for (const body of [
        { title: 'Другое' },
        { statusId: statuses.closed },
        { priority: 100 },
        { assigneeId: reader.id },
      ]) {
        const response = await patch('/api/issues/DEV-1', reader.headers, body);
        expect(response.statusCode).toBe(403);
        expect(response.json().code).toBe('issue_forbidden');
      }
    });

    it('посторонний получает 404, а не 403', async () => {
      const { admin, outsider } = await seedWorkspace();
      await createIssue(admin);
      const response = await patch('/api/issues/DEV-1', outsider.headers, { title: 'Взлом' });
      expect(response.statusCode).toBe(404);
    });
  });

  describe('Удаление (US-44, D-12)', () => {
    it('администратор удаляет задачу, ссылка на неё навсегда отдаёт 404', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);

      expect((await del('/api/issues/DEV-1', admin.headers)).statusCode).toBe(204);
      expect((await get('/api/issues/DEV-1', admin.headers)).statusCode).toBe(404);
    });

    it('участник и читатель задачу не удаляют — даже свою', async () => {
      const { member, reader } = await seedWorkspace();
      await createIssue(member, { title: 'Своя задача участника' });

      expect((await del('/api/issues/DEV-1', member.headers)).statusCode).toBe(403);
      expect((await del('/api/issues/DEV-1', reader.headers)).statusCode).toBe(403);
      expect((await get('/api/issues/DEV-1', member.headers)).statusCode).toBe(200);
    });
  });

  describe('Список задач очереди (US-32, D-28)', () => {
    /** Четыре задачи с разными приоритетами и статусами. */
    async function seedIssues(workspace: Workspace) {
      const { admin, member, statuses } = workspace;
      await createIssue(admin, { title: 'Обычная', priority: 50 });
      await createIssue(admin, { title: 'Важная', priority: 90, assigneeId: member.id });
      await createIssue(admin, { title: 'Неважная', priority: 10 });
      const fourth = await createIssue(admin, { title: 'В работе', priority: 50 });
      await patch(`/api/issues/${fourth.key}`, admin.headers, { statusId: statuses.in_progress });
    }

    it('по умолчанию сортирует по приоритету, при равенстве — по номеру по убыванию', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);

      const response = await get('/api/queues/DEV/issues', workspace.reader.headers);
      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.items.map((issue: { key: string }) => issue.key)).toEqual([
        'DEV-2',
        'DEV-4',
        'DEV-1',
        'DEV-3',
      ]);
      expect(body.total).toBe(4);
      expect(body.role).toBe('reader');
    });

    it('«сначала новые» сортирует только по номеру', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);

      const body = (
        await get('/api/queues/DEV/issues?sort=newest', workspace.admin.headers)
      ).json();
      expect(body.items.map((issue: { key: string }) => issue.key)).toEqual([
        'DEV-4',
        'DEV-3',
        'DEV-2',
        'DEV-1',
      ]);
    });

    it('строка списка содержит ровно поля таблицы и исполнителя одним запросом', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);

      const body = (await get('/api/queues/DEV/issues', workspace.admin.headers)).json();
      const row = body.items[0];
      expect(Object.keys(row).sort()).toEqual(
        ['assignee', 'key', 'priority', 'status', 'storyPoints', 'title'].sort(),
      );
      expect(row.assignee.displayName).toBe('Борис Участников');
      expect(body.items[2].assignee).toBeNull();
    });

    it('фильтрует по ключам статусов', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);

      const inProgress = (
        await get('/api/queues/DEV/issues?status=in_progress', workspace.admin.headers)
      ).json();
      expect(inProgress.items.map((issue: { key: string }) => issue.key)).toEqual(['DEV-4']);
      expect(inProgress.total).toBe(1);

      const both = (
        await get('/api/queues/DEV/issues?status=open,in_progress', workspace.admin.headers)
      ).json();
      expect(both.total).toBe(4);
    });

    it('неизвестный ключ статуса даёт пустую страницу, а не ошибку', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);

      const response = await get('/api/queues/DEV/issues?status=nosuch', workspace.admin.headers);
      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({ items: [], total: 0, nextCursor: null });
    });

    it('фильтрует по исполнителю, автору и приоритету', async () => {
      const workspace = await seedWorkspace();
      await seedIssues(workspace);
      const { admin, member } = workspace;

      const byAssignee = (
        await get(`/api/queues/DEV/issues?assignee=${member.id}`, admin.headers)
      ).json();
      expect(byAssignee.items.map((issue: { key: string }) => issue.key)).toEqual(['DEV-2']);

      const unassigned = (await get('/api/queues/DEV/issues?assignee=none', admin.headers)).json();
      expect(unassigned.total).toBe(3);

      const byAuthor = (
        await get(`/api/queues/DEV/issues?author=${admin.id}`, admin.headers)
      ).json();
      expect(byAuthor.total).toBe(4);

      const byPriority = (await get('/api/queues/DEV/issues?priorityMin=50', admin.headers)).json();
      expect(byPriority.total).toBe(3);
    });

    it('курсорная пагинация отдаёт каждую задачу ровно один раз', async () => {
      const { admin } = await seedWorkspace();
      for (let index = 0; index < 7; index += 1) {
        await createIssue(admin, { title: `Задача ${index}`, priority: index % 2 === 0 ? 50 : 80 });
      }

      const seen: string[] = [];
      let cursor: string | null = null;
      for (let page = 0; page < 10; page += 1) {
        const url: string = cursor
          ? `/api/queues/DEV/issues?limit=3&cursor=${encodeURIComponent(cursor)}`
          : '/api/queues/DEV/issues?limit=3';
        const body = (await get(url, admin.headers)).json();
        seen.push(...body.items.map((issue: { key: string }) => issue.key));
        cursor = body.nextCursor;
        if (!cursor) {
          break;
        }
      }

      expect(seen).toHaveLength(7);
      expect(new Set(seen).size).toBe(7);
    });

    it('limit ограничивается жёстким максимумом, а не отдаёт всё сразу', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);
      const response = await get('/api/queues/DEV/issues?limit=100000', admin.headers);
      expect(response.statusCode).toBe(200);
    });

    it('испорченный курсор — 400, а не молчаливая первая страница', async () => {
      const { admin } = await seedWorkspace();
      const response = await get('/api/queues/DEV/issues?cursor=%2A%2A%2A', admin.headers);
      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_cursor');
    });

    it('посторонний не видит список задач чужой очереди', async () => {
      const { outsider } = await seedWorkspace();
      expect((await get('/api/queues/DEV/issues', outsider.headers)).statusCode).toBe(404);
    });
  });

  describe('История изменений (US-90 … US-92)', () => {
    it('у новой задачи ровно одна запись — о создании, с реальным создателем', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);

      const body = (await get('/api/issues/DEV-1/history', admin.headers)).json();
      expect(body.total).toBe(1);
      expect(body.items).toHaveLength(1);
      expect(body.items[0].changes).toHaveLength(1);
      expect(body.items[0].changes[0].kind).toBe('issue_created');
      expect(body.items[0].actor.displayName).toBe('Анна Админова');
    });

    it('одно действие с несколькими полями — одна группа', async () => {
      const { admin, member, statuses } = await seedWorkspace();
      await createIssue(admin);

      await patch('/api/issues/DEV-1', member.headers, {
        statusId: statuses.review,
        priority: 80,
        assigneeId: member.id,
      });

      const body = (await get('/api/issues/DEV-1/history', admin.headers)).json();
      expect(body.total).toBe(2);
      const latest = body.items[0];
      expect(latest.actor.displayName).toBe('Борис Участников');
      expect(latest.changes.map((change: { kind: string }) => change.kind).sort()).toEqual(
        ['assignee_changed', 'priority_changed', 'status_changed'].sort(),
      );
      const status = latest.changes.find(
        (change: { kind: string }) => change.kind === 'status_changed',
      );
      expect(status.oldValue).toBe('Открыт');
      expect(status.newValue).toBe('Ревью');
    });

    it('запись не создаётся, если значение не изменилось', async () => {
      const { admin, statuses } = await seedWorkspace();
      await createIssue(admin, { title: 'Задача' });

      await patch('/api/issues/DEV-1', admin.headers, {
        title: 'Задача',
        statusId: statuses.open,
        priority: 50,
      });

      expect((await get('/api/issues/DEV-1/history', admin.headers)).json().total).toBe(1);
    });

    it('у описания фиксируется только факт изменения, без текстов', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);
      await patch('/api/issues/DEV-1', admin.headers, { description: 'Секретные требования' });

      const body = (await get('/api/issues/DEV-1/history', admin.headers)).json();
      const change = body.items[0].changes[0];
      expect(change.kind).toBe('description_changed');
      expect(change.oldValue).toBeNull();
      expect(change.newValue).toBeNull();
      expect(JSON.stringify(body)).not.toContain('Секретные требования');
    });

    it('смена автора логируется отдельно и не трогает создателя (D-13)', async () => {
      const { admin, member } = await seedWorkspace();
      await createIssue(admin, { title: 'Задача' });
      await patch('/api/issues/DEV-1', admin.headers, { authorId: member.id });

      const body = (await get('/api/issues/DEV-1/history', admin.headers)).json();
      expect(body.items[0].changes[0]).toMatchObject({
        kind: 'author_changed',
        oldValue: 'Анна Админова',
        newValue: 'Борис Участников',
      });
      // Самая ранняя запись по-прежнему показывает реального создателя.
      const earliest = body.items[body.items.length - 1];
      expect(earliest.changes[0].kind).toBe('issue_created');
      expect(earliest.actor.displayName).toBe('Анна Админова');
      expect((await get('/api/issues/DEV-1', admin.headers)).json().author.id).toBe(member.id);
    });

    it('история подгружается порциями, группа не разрывается границей страницы', async () => {
      const { admin, statuses } = await seedWorkspace();
      await createIssue(admin);
      for (const key of ['in_progress', 'review', 'testing', 'closed']) {
        await patch('/api/issues/DEV-1', admin.headers, {
          statusId: statuses[key],
          priority: key === 'closed' ? 100 : 60,
        });
      }

      const first = (await get('/api/issues/DEV-1/history?limit=2', admin.headers)).json();
      expect(first.items).toHaveLength(2);
      expect(first.nextCursor).not.toBeNull();
      for (const group of first.items) {
        expect(group.changes.length).toBeGreaterThan(0);
      }

      const second = (
        await get(
          `/api/issues/DEV-1/history?limit=10&cursor=${encodeURIComponent(first.nextCursor)}`,
          admin.headers,
        )
      ).json();
      const ids = [...first.items, ...second.items].map((group: { id: string }) => group.id);
      expect(new Set(ids).size).toBe(ids.length);
      expect(ids).toHaveLength(first.total);
    });

    it('историю видит читатель, но не посторонний', async () => {
      const { admin, reader, outsider } = await seedWorkspace();
      await createIssue(admin);

      expect((await get('/api/issues/DEV-1/history', reader.headers)).statusCode).toBe(200);
      expect((await get('/api/issues/DEV-1/history', outsider.headers)).statusCode).toBe(404);
    });
  });

  describe('Внешние ссылки (US-47)', () => {
    it('участник добавляет и удаляет ссылку, оба действия попадают в историю', async () => {
      const { admin, member } = await seedWorkspace();
      await createIssue(admin);

      const added = await post('/api/issues/DEV-1/links', member.headers, {
        url: 'https://example.com/spec',
        title: 'Спецификация',
      });
      expect(added.statusCode).toBe(201);
      expect(added.json().links).toHaveLength(1);
      expect(added.json().links[0]).toMatchObject({
        url: 'https://example.com/spec',
        title: 'Спецификация',
      });

      const linkId = added.json().links[0].id;
      const removed = await del(`/api/issues/DEV-1/links/${linkId}`, member.headers);
      expect(removed.statusCode).toBe(200);
      expect(removed.json().links).toEqual([]);

      const history = (await get('/api/issues/DEV-1/history', admin.headers)).json();
      const kinds = history.items.flatMap((group: { changes: { kind: string }[] }) =>
        group.changes.map((change) => change.kind),
      );
      expect(kinds).toContain('link_added');
      expect(kinds).toContain('link_removed');
    });

    it('схемы кроме http и https отклоняются', async () => {
      const { admin } = await seedWorkspace();
      await createIssue(admin);

      for (const url of ['javascript:alert(1)', 'ftp://example.com', 'example.com']) {
        const response = await post('/api/issues/DEV-1/links', admin.headers, { url });
        expect(response.statusCode).toBe(400);
        expect(response.json().code).toBe('invalid_link_url');
      }
    });

    it('читатель ссылки не добавляет', async () => {
      const { admin, reader } = await seedWorkspace();
      await createIssue(admin);
      const response = await post('/api/issues/DEV-1/links', reader.headers, {
        url: 'https://example.com',
      });
      expect(response.statusCode).toBe(403);
    });
  });
});
