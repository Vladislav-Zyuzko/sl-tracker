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
import { mentionToken } from '../src/mentions/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Уведомления (US-100 … US-104, US-23).
 *
 * Тесты держат два обещания продукта, которые легко нарушить незаметно:
 * **никаких уведомлений о собственных действиях** и **не более одного уведомления
 * на человека на одно событие**.
 */
describe('Уведомления', () => {
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
  const put = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PUT', url, headers, payload: body });

  interface Workspace {
    admin: Actor;
    member: Actor;
    reader: Actor;
    projectId: string;
    issueKey: string;
    statuses: Record<string, string>;
  }

  async function seedWorkspace(): Promise<Workspace> {
    const admin = await signIn('Анна Админова');
    const member = await signIn('Борис Участников');
    const reader = await signIn('Вера Читателева');

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

    const statusList = (await get('/api/queues/DEV/statuses', admin.headers)).json();
    const statuses: Record<string, string> = {};
    for (const status of statusList.items as { key: string; id: string }[]) {
      statuses[status.key] = status.id;
    }

    const issue = await post('/api/queues/DEV/issues', admin.headers, {
      title: 'Починить экспорт CSV',
    });

    return {
      admin,
      member,
      reader,
      projectId: project.id,
      issueKey: issue.json().key,
      statuses,
    };
  }

  interface NotificationBody {
    id: string;
    type: string;
    actor: { id: string; displayName: string } | null;
    issueKey: string | null;
    projectSlug: string | null;
    commentId: string | null;
    payload: Record<string, string>;
    readAt: string | null;
  }

  async function inbox(actor: Actor): Promise<NotificationBody[]> {
    const response = await get('/api/notifications', actor.headers);
    expect(response.statusCode).toBe(200);
    return response.json().items as NotificationBody[];
  }

  describe('US-100: назначение', () => {
    it('исполнитель узнаёт о назначении, а назначивший себе — нет', async () => {
      const space = await seedWorkspace();

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        assigneeId: space.member.id,
      });

      const forMember = await inbox(space.member);
      expect(forMember).toHaveLength(1);
      expect(forMember[0]).toMatchObject({
        type: 'issue_assigned',
        actor: { id: space.admin.id },
        issueKey: space.issueKey,
        readAt: null,
      });
      expect(forMember[0]!.payload).toMatchObject({
        issueKey: space.issueKey,
        issueTitle: 'Починить экспорт CSV',
      });

      // Назначил сам — уведомления себе нет.
      await patch(`/api/issues/${space.issueKey}`, space.member.headers, {
        assigneeId: space.member.id,
      });
      expect(await inbox(space.member)).toHaveLength(1);
    });

    it('снятие с задачи уведомления не создаёт', async () => {
      const space = await seedWorkspace();
      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        assigneeId: space.member.id,
      });

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, { assigneeId: null });

      expect(await inbox(space.member)).toHaveLength(1);
    });

    it('новый автор получает уведомление о назначении автором', async () => {
      const space = await seedWorkspace();

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        authorId: space.member.id,
      });

      expect((await inbox(space.member))[0]).toMatchObject({
        type: 'issue_author_assigned',
        issueKey: space.issueKey,
      });
    });

    it('задача, созданная сразу на другого, уведомляет исполнителя', async () => {
      const space = await seedWorkspace();

      await post('/api/queues/DEV/issues', space.admin.headers, {
        title: 'Новая задача',
        assigneeId: space.member.id,
      });

      expect((await inbox(space.member))[0]).toMatchObject({ type: 'issue_assigned' });
    });
  });

  describe('US-101: смена статуса', () => {
    it('подписчики узнают о смене статуса, инициатор — нет', async () => {
      const space = await seedWorkspace();
      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        assigneeId: space.member.id,
      });

      await patch(`/api/issues/${space.issueKey}`, space.member.headers, {
        statusId: space.statuses.in_progress,
      });

      const forAdmin = await inbox(space.admin);
      expect(forAdmin[0]).toMatchObject({
        type: 'issue_status_changed',
        actor: { id: space.member.id },
      });
      expect(forAdmin[0]!.payload).toMatchObject({
        fromStatusName: 'Открыт',
        toStatusName: 'В работе',
      });

      // Инициатор о своём действии уведомления не получает.
      expect((await inbox(space.member)).map((row) => row.type)).toEqual(['issue_assigned']);
    });

    it('не подписанный на задачу участник уведомления не получает', async () => {
      const space = await seedWorkspace();

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        statusId: space.statuses.in_progress,
      });

      expect(await inbox(space.reader)).toEqual([]);
    });

    it('одно действие — не больше одного уведомления человеку', async () => {
      const space = await seedWorkspace();

      // Один запрос меняет и исполнителя, и статус: Борис — и новый исполнитель,
      // и подписчик. Уведомление должно быть одно, о назначении (US-101).
      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        assigneeId: space.member.id,
        statusId: space.statuses.in_progress,
      });

      const forMember = await inbox(space.member);
      expect(forMember).toHaveLength(1);
      expect(forMember[0]!.type).toBe('issue_assigned');
    });

    it('изменение приоритета и названия уведомлений не создаёт', async () => {
      const space = await seedWorkspace();
      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        assigneeId: space.member.id,
      });

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        priority: 80,
        title: 'Другое название',
        storyPoints: 5,
      });

      expect((await inbox(space.member)).map((row) => row.type)).toEqual(['issue_assigned']);
    });
  });

  describe('US-102: комментарии', () => {
    it('подписчики узнают о комментарии, автор комментария — нет', async () => {
      const space = await seedWorkspace();

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Поправил отступы, посмотри',
      });

      const forAdmin = await inbox(space.admin);
      expect(forAdmin[0]).toMatchObject({
        type: 'issue_commented',
        actor: { id: space.member.id },
      });
      expect(forAdmin[0]!.payload.excerpt).toBe('Поправил отступы, посмотри');
      // Комментарий ведёт к самому себе: клиент прокручивает ленту к нему.
      expect(forAdmin[0]!.commentId).not.toBeNull();

      expect(await inbox(space.member)).toEqual([]);
    });

    it('автор комментария становится подписчиком и узнаёт о следующих', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Первый',
      });

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Второй',
      });

      expect((await inbox(space.member))[0]).toMatchObject({ type: 'issue_commented' });
    });

    it('удаление комментария не создаёт уведомлений и не удаляет старые, но снимает ссылку', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Скоро удалю',
      });

      await app.inject({
        method: 'DELETE',
        url: `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        headers: space.member.headers,
      });

      const forAdmin = await inbox(space.admin);
      expect(forAdmin).toHaveLength(1);
      expect(forAdmin[0]!.commentId).toBeNull();
      // Текст в уведомлении остался снимком — он не исчезает вместе с комментарием.
      expect(forAdmin[0]!.payload.excerpt).toBe('Скоро удалю');
    });
  });

  describe('US-104: упоминания', () => {
    it('упомянутый получает уведомление об упоминании вместо уведомления о комментарии', async () => {
      const space = await seedWorkspace();

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `${mentionToken(space.admin.id, 'Анна')}, какой размер порции берём?`,
      });

      const forAdmin = await inbox(space.admin);
      // Анна — и автор задачи (подписчик), и упомянутая: уведомление одно.
      expect(forAdmin).toHaveLength(1);
      expect(forAdmin[0]).toMatchObject({ type: 'issue_mentioned' });
      expect(forAdmin[0]!.payload).toMatchObject({
        excerpt: '@Анна, какой размер порции берём?',
        source: 'comment',
      });
    });

    it('упоминание самого себя уведомления не создаёт', async () => {
      const space = await seedWorkspace();

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `Напоминание себе: ${mentionToken(space.member.id, 'Борис')}`,
      });

      expect(await inbox(space.member)).toEqual([]);
    });

    it('правка добавляет уведомление только вновь упомянутым', async () => {
      const space = await seedWorkspace();
      const created = await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `${mentionToken(space.admin.id, 'Анна')}, посмотри`,
      });

      await patch(
        `/api/issues/${space.issueKey}/comments/${created.json().id}`,
        space.member.headers,
        {
          body: `${mentionToken(space.admin.id, 'Анна')} и ${mentionToken(space.reader.id, 'Вера')}, посмотрите`,
        },
      );

      // Анна упомянута повторно — второго уведомления нет.
      expect(await inbox(space.admin)).toHaveLength(1);
      // Вера упомянута впервые — уведомление есть, хотя она читатель.
      expect((await inbox(space.reader))[0]).toMatchObject({ type: 'issue_mentioned' });
    });

    it('упоминание в описании задачи уведомляет и указывает на описание', async () => {
      const space = await seedWorkspace();

      await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        description: `Нужна помощь: ${mentionToken(space.member.id, 'Борис')}`,
      });

      const forMember = await inbox(space.member);
      expect(forMember[0]).toMatchObject({ type: 'issue_mentioned', commentId: null });
      expect(forMember[0]!.payload.source).toBe('description');
    });
  });

  describe('US-23: новый участник проекта', () => {
    it('администраторы узнают о вступившем, сам вступивший — нет', async () => {
      const space = await seedWorkspace();
      const newcomer = await signIn('Дарья Новенькая');

      const invitation = await post(
        '/api/projects/sladkiy-limit/invitations',
        space.admin.headers,
        { role: 'member' },
      );
      const token = (invitation.json().url as string).split('/invite/')[1]!;

      const accepted = await post(`/api/invitations/${token}/accept`, newcomer.headers);
      expect(accepted.statusCode).toBe(200);

      const forAdmin = await inbox(space.admin);
      expect(forAdmin[0]).toMatchObject({
        type: 'project_member_joined',
        actor: { id: newcomer.id },
        projectSlug: 'sladkiy-limit',
      });
      expect(forAdmin[0]!.payload).toMatchObject({
        projectName: 'Сладкий Лимит',
        memberName: 'Дарья Новенькая',
      });

      // Обычному участнику и самому вступившему уведомления не приходят.
      expect(await inbox(space.member)).toEqual([]);
      expect(await inbox(newcomer)).toEqual([]);
    });
  });

  describe('US-103: центр уведомлений', () => {
    it('счётчик непрочитанных растёт и гаснет при пометке прочитанным', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Первый',
      });
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Второй',
      });

      const before = await get('/api/notifications/unread-count', space.admin.headers);
      expect(before.json().unreadCount).toBe(2);

      const items = await inbox(space.admin);
      const marked = await post(`/api/notifications/${items[0]!.id}/read`, space.admin.headers);
      // 200, а не 201: пометка ничего не создаёт, и ровно это обещает контракт (DEF-01).
      expect(marked.statusCode).toBe(200);
      expect(marked.json().unreadCount).toBe(1);

      // Повторная пометка идемпотентна.
      await post(`/api/notifications/${items[0]!.id}/read`, space.admin.headers);
      expect((await get('/api/notifications/unread-count', space.admin.headers)).json()).toEqual({
        unreadCount: 1,
      });

      const all = await post('/api/notifications/read-all', space.admin.headers);
      expect(all.statusCode).toBe(200);
      expect(all.json().updated).toBe(1);
      expect(
        (await get('/api/notifications/unread-count', space.admin.headers)).json().unreadCount,
      ).toBe(0);

      // «Отметить все» не удаляет и не переупорядочивает строки.
      expect(await inbox(space.admin)).toHaveLength(2);
    });

    it('лента отдаётся порциями, сначала новые', async () => {
      const space = await seedWorkspace();
      for (const body of ['Первый', 'Второй', 'Третий']) {
        await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, { body });
      }

      const page = await get('/api/notifications?limit=2', space.admin.headers);
      expect(page.json().total).toBe(3);
      expect((page.json().items as NotificationBody[]).map((row) => row.payload.excerpt)).toEqual([
        'Третий',
        'Второй',
      ]);

      const next = await get(
        `/api/notifications?limit=2&cursor=${encodeURIComponent(page.json().nextCursor)}`,
        space.admin.headers,
      );
      expect((next.json().items as NotificationBody[]).map((row) => row.payload.excerpt)).toEqual([
        'Первый',
      ]);
      expect(next.json().nextCursor).toBeNull();
    });

    it('чужое уведомление не прочитать и не увидеть', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Только для Анны',
      });
      const [own] = await inbox(space.admin);

      expect(await inbox(space.member)).toEqual([]);

      const foreign = await post(`/api/notifications/${own!.id}/read`, space.member.headers);
      expect(foreign.statusCode).toBe(404);
      expect(foreign.json().code).toBe('notification_not_found');
    });

    it('без сессии центр уведомлений недоступен', async () => {
      const response = await app.inject({ method: 'GET', url: '/api/notifications' });
      expect(response.statusCode).toBe(401);
    });

    it('по умолчанию включены все типы, отключённый не создаёт ни записи, ни счётчика', async () => {
      const space = await seedWorkspace();

      const settings = await get('/api/notifications/settings', space.admin.headers);
      expect(settings.json().items).toHaveLength(6);
      expect((settings.json().items as { enabled: boolean }[]).every((item) => item.enabled)).toBe(
        true,
      );

      const updated = await put('/api/notifications/settings', space.admin.headers, {
        items: [{ type: 'issue_commented', enabled: false }],
      });
      expect(updated.statusCode).toBe(200);
      expect(
        (updated.json().items as { type: string; enabled: boolean }[]).find(
          (item) => item.type === 'issue_commented',
        ),
      ).toMatchObject({ enabled: false });

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Шум, который отключили',
      });

      expect(await inbox(space.admin)).toEqual([]);
      expect(
        (await get('/api/notifications/unread-count', space.admin.headers)).json().unreadCount,
      ).toBe(0);
    });

    it('отключённый «комментарий» не мешает уведомлению об упоминании', async () => {
      const space = await seedWorkspace();
      await put('/api/notifications/settings', space.admin.headers, {
        items: [{ type: 'issue_commented', enabled: false }],
      });

      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: `${mentionToken(space.admin.id, 'Анна')}, глянь`,
      });

      expect((await inbox(space.admin))[0]).toMatchObject({ type: 'issue_mentioned' });
    });

    it('исключённый из проекта перестаёт получать уведомления по его задачам', async () => {
      const space = await seedWorkspace();
      await post(`/api/issues/${space.issueKey}/comments`, space.member.headers, {
        body: 'Подписался',
      });

      await app.inject({
        method: 'DELETE',
        url: `/api/projects/sladkiy-limit/members/${space.member.id}`,
        headers: space.admin.headers,
      });

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'После исключения',
      });

      // Полученное раньше остаётся, новых нет.
      const forMember = await inbox(space.member);
      expect(forMember.map((row) => row.payload.excerpt)).not.toContain('После исключения');
    });
  });
});
