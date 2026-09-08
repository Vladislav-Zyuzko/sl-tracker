import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { DB } from '../src/database/index.js';
import * as schema from '../src/database/schema/index.js';
import { mentionToken } from '../src/mentions/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Комментарии и упоминания (US-70 … US-74).
 *
 * Права проверяются на каждом действии вместе с негативным случаем: читатель
 * не пишет, чужой комментарий не правит никто, посторонний не видит обсуждения,
 * а упоминание не-участника не создаёт ни связи, ни уведомления.
 */
describe('Комментарии', () => {
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
    projectId: string;
    issueKey: string;
  }

  /** Проект с очередью `DEV`, полной расстановкой ролей и одной задачей. */
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
    const issue = await post('/api/queues/DEV/issues', admin.headers, {
      title: 'Починить экспорт CSV',
    });

    return {
      admin,
      member,
      reader,
      outsider,
      projectId: project.id,
      issueKey: issue.json().key,
    };
  }

  describe('US-70: чтение ленты', () => {
    it('отдаёт комментарии сначала старые, с автором и счётчиком', async () => {
      const space = await seedWorkspace();

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Первый',
      });
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Второй',
      });

      const response = await get(`/api/issues/${space.issueKey}/comments`, space.reader.headers);

      expect(response.statusCode).toBe(200);
      const list = response.json();
      expect(list.items.map((item: { body: string }) => item.body)).toEqual(['Первый', 'Второй']);
      expect(list.total).toBe(2);
      expect(list.nextCursor).toBeNull();
      // Данные автора приезжают сразу: второго запроса за именем и аватаром нет.
      expect(list.items[0].author).toMatchObject({ displayName: 'Анна Админова' });
      expect(list.items[0].editedAt).toBeNull();
    });

    it('читатель ленту видит, но поля ввода у него нет', async () => {
      const space = await seedWorkspace();
      const response = await get(`/api/issues/${space.issueKey}/comments`, space.reader.headers);

      expect(response.statusCode).toBe(200);
      expect(response.json().canComment).toBe(false);
    });

    it('порция ограничена, а курсор ведёт к более ранним комментариям', async () => {
      const space = await seedWorkspace();
      for (let index = 1; index <= 5; index += 1) {
        await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
          body: `Комментарий ${index}`,
        });
      }

      const last = await get(
        `/api/issues/${space.issueKey}/comments?limit=2`,
        space.member.headers,
      );
      expect(last.json().items.map((item: { body: string }) => item.body)).toEqual([
        'Комментарий 4',
        'Комментарий 5',
      ]);
      expect(last.json().total).toBe(5);

      const earlier = await get(
        `/api/issues/${space.issueKey}/comments?limit=2&cursor=${encodeURIComponent(last.json().nextCursor)}`,
        space.member.headers,
      );
      expect(earlier.json().items.map((item: { body: string }) => item.body)).toEqual([
        'Комментарий 2',
        'Комментарий 3',
      ]);
    });

    it('испорченный курсор — 400, а не пустая страница', async () => {
      const space = await seedWorkspace();
      const response = await get(
        `/api/issues/${space.issueKey}/comments?cursor=не-курсор`,
        space.member.headers,
      );

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_cursor');
    });

    it('посторонний не видит ни задачи, ни её обсуждения', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Внутреннее обсуждение',
      });

      const response = await get(`/api/issues/${space.issueKey}/comments`, space.outsider.headers);

      expect(response.statusCode).toBe(404);
      expect(response.body).not.toContain('Внутреннее обсуждение');
    });
  });

  describe('US-71: написание комментария', () => {
    it('участник пишет комментарий и сразу получает его целиком', async () => {
      const space = await seedWorkspace();

      const response = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Посмотрел, всё ок',
      });

      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        body: 'Посмотрел, всё ок',
        author: { id: space.member.id, displayName: 'Борис Участников' },
        editedAt: null,
        mentions: [],
        permissions: { canEdit: true, canDelete: true },
      });
    });

    it('читатель комментировать не может: 403', async () => {
      const space = await seedWorkspace();

      const response = await post(`/api/issues/${space.issueKey}/comments`, space.reader.headers, {
        body: 'Можно я тоже?',
      });

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('comment_forbidden');
      expect(await db.select().from(schema.comments)).toHaveLength(0);
    });

    it('пустой комментарий и комментарий из пробелов отклоняются', async () => {
      const space = await seedWorkspace();

      for (const body of ['', '   \n  ']) {
        const response = await post(
          `/api/issues/${space.issueKey}/comments`,
          space.member.headers,
          { body },
        );
        expect(response.statusCode).toBe(400);
      }
    });

    it('текст длиннее 10 000 символов не принимается', async () => {
      const space = await seedWorkspace();

      const response = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'я'.repeat(10001),
      });

      expect(response.statusCode).toBe(400);
    });
  });

  describe('US-72: правка своего комментария', () => {
    it('автор правит свой текст, комментарий помечается изменённым', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Первая редакция',
      });

      const response = await patch(
        `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        space.member.headers,
        { body: 'Вторая редакция' },
      );

      expect(response.statusCode).toBe(200);
      expect(response.json().body).toBe('Вторая редакция');
      expect(response.json().editedAt).not.toBeNull();
    });

    it('администратор чужой комментарий не правит: 403 и текст на месте', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Мой текст',
      });

      const response = await patch(
        `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        space.admin.headers,
        { body: 'Переписал за тебя' },
      );

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('comment_forbidden');

      const [row] = await db
        .select({ body: schema.comments.body })
        .from(schema.comments)
        .where(eq(schema.comments.id, created.json().id));
      expect(row!.body).toBe('Мой текст');
    });

    it('в правах комментария видно, что чужой править нельзя', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Чужой',
      });

      const list = await get(`/api/issues/${space.issueKey}/comments`, space.admin.headers);

      // Администратор чужой комментарий удалить может, а править — нет (US-72, US-73).
      expect(list.json().items[0].permissions).toEqual({ canEdit: false, canDelete: true });
    });
  });

  describe('US-73: удаление комментария', () => {
    it('автор удаляет свой комментарий, и он исчезает из ленты полностью', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Ошибся веткой',
      });

      const response = await del(
        `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        space.member.headers,
      );

      expect(response.statusCode).toBe(204);
      const list = await get(`/api/issues/${space.issueKey}/comments`, space.member.headers);
      expect(list.json().items).toEqual([]);
      expect(list.json().total).toBe(0);
    });

    it('участник чужой комментарий не удаляет, администратор — удаляет', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Комментарий администратора',
      });

      const byMember = await del(
        `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        space.member.headers,
      );
      expect(byMember.statusCode).toBe(403);

      const other = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Комментарий участника',
      });
      const byAdmin = await del(
        `/api/issues/${space.issueKey}/comments/${other.json().id}`,
        space.admin.headers,
      );
      expect(byAdmin.statusCode).toBe(204);
    });

    it('удаление попадает в историю задачи — кто удалил и чей, без текста', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Секретный текст комментария',
      });

      await del(`/api/issues/${space.issueKey}/comments/${created.json().id}`, space.admin.headers);

      const history = await get(`/api/issues/${space.issueKey}/history`, space.admin.headers);
      const groups = history.json().items as {
        actor: { id: string } | null;
        changes: { kind: string; oldValue: string | null; oldRefId: string | null }[];
      }[];
      const deletion = groups.find((group) =>
        group.changes.some((change) => change.kind === 'comment_deleted'),
      );

      expect(deletion?.actor?.id).toBe(space.admin.id);
      expect(deletion?.changes[0]).toMatchObject({
        kind: 'comment_deleted',
        oldValue: 'Борис Участников',
        oldRefId: space.member.id,
      });
      expect(history.body).not.toContain('Секретный текст комментария');
    });
  });

  describe('US-74: упоминания', () => {
    it('упоминание участника сохраняется ссылкой и отдаётся актуальным именем', async () => {
      const space = await seedWorkspace();

      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `Посмотри, ${mentionToken(space.admin.id, 'Анна Админова')}`,
      });

      expect(created.json().mentions).toEqual([
        expect.objectContaining({ id: space.admin.id, displayName: 'Анна Админова' }),
      ]);

      // Человек сменил имя — во всех старых комментариях показывается новое.
      await db
        .update(schema.users)
        .set({ displayName: 'Анна Иванова' })
        .where(eq(schema.users.id, space.admin.id));

      const list = await get(`/api/issues/${space.issueKey}/comments`, space.member.headers);
      expect(list.json().items[0].mentions[0].displayName).toBe('Анна Иванова');
    });

    it('упоминание постороннего игнорируется молча: ни ошибки, ни связи', async () => {
      const space = await seedWorkspace();
      const body = `Привет, ${mentionToken(space.outsider.id, 'Гриша Посторонний')}`;

      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body,
      });

      expect(created.statusCode).toBe(201);
      expect(created.json().mentions).toEqual([]);
      // Текст остаётся текстом, а строки упоминания не появляется.
      expect(created.json().body).toBe(body);
      expect(await db.select().from(schema.mentions)).toHaveLength(0);
      // Уведомление об упоминании не создаётся; постороннему не приходит ничего вовсе.
      const notifications = await db.select().from(schema.notifications);
      expect(notifications.map((row) => row.type)).not.toContain('issue_mentioned');
      expect(notifications.map((row) => row.recipientId)).not.toContain(space.outsider.id);
    });

    it('повторное упоминание того же человека в одном комментарии — одна связь', async () => {
      const space = await seedWorkspace();
      const token = mentionToken(space.admin.id, 'Анна Админова');

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `${token} и ещё раз ${token}`,
      });

      expect(await db.select().from(schema.mentions)).toHaveLength(1);
    });
  });

  describe('US-74: подсказка упоминаний', () => {
    it('показывает только участников проекта и фильтрует по имени и email', async () => {
      const space = await seedWorkspace();

      const all = await get(
        `/api/issues/${space.issueKey}/mention-suggestions`,
        space.member.headers,
      );
      const ids = (all.json().items as { id: string }[]).map((item) => item.id);

      expect(ids).toContain(space.admin.id);
      expect(ids).toContain(space.reader.id);
      // Себя упомянуть можно — подсказка это допускает (US-74).
      expect(ids).toContain(space.member.id);
      // Посторонний не появляется никогда: подсказка не раскрывает состав трекера.
      expect(ids).not.toContain(space.outsider.id);

      const filtered = await get(
        `/api/issues/${space.issueKey}/mention-suggestions?query=админов`,
        space.member.headers,
      );
      expect((filtered.json().items as { id: string }[]).map((item) => item.id)).toEqual([
        space.admin.id,
      ]);
    });

    it('перебором состав трекера через подсказку не узнать', async () => {
      const space = await seedWorkspace();
      await signIn('Гриша Посторонний Второй');

      const response = await get(
        `/api/issues/${space.issueKey}/mention-suggestions?query=гриша`,
        space.member.headers,
      );

      expect(response.json().items).toEqual([]);
    });

    it('читатель подсказку не получает: он не создаёт текстов', async () => {
      const space = await seedWorkspace();

      const response = await get(
        `/api/issues/${space.issueKey}/mention-suggestions`,
        space.reader.headers,
      );

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('mention_forbidden');
    });

    it('посторонний получает 404 — задачи для него не существует', async () => {
      const space = await seedWorkspace();

      const response = await get(
        `/api/issues/${space.issueKey}/mention-suggestions`,
        space.outsider.headers,
      );

      expect(response.statusCode).toBe(404);
    });
  });
});
