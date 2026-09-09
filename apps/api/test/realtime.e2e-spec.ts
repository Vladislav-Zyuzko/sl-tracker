import type { AddressInfo } from 'node:net';
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import WebSocket from 'ws';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { SESSION_COOKIE_NAME } from '../src/auth/index.js';
import { ENV, type Env } from '../src/config/index.js';
import { DB } from '../src/database/index.js';
import * as schema from '../src/database/schema/index.js';
import { REDIS } from '../src/redis/index.js';
import { RealtimeGateway } from '../src/realtime/index.js';
import { SessionService } from '../src/sessions/index.js';
import {
  addProjectMember,
  grantTrackerAccess,
  seedIssue,
  seedProject,
  seedQueueInProject,
  seedUser,
  truncateAll,
} from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Живые обновления по WebSocket (D-26).
 *
 * Тест поднимает настоящий сервер на свободном порту и ходит настоящим
 * WebSocket-клиентом: `app.inject` рукопожатие не выполняет, а именно в нём живёт
 * аутентификация. Порт выбирает операционная система (`0`) — рабочий экземпляр API
 * на 3000 не трогается.
 *
 * Проверяется то, что легко сломать незаметно:
 *  - соединение без сессии не открывается вовсе;
 *  - подписка без прав отклоняется;
 *  - исключённый из проекта перестаёт получать события **немедленно**, не дожидаясь
 *    переподключения;
 *  - отзыв доступа рвёт открытый сокет;
 *  - переподключение не оставляет на сервере ни подписок, ни соединений.
 */
describe('Живые обновления (WebSocket)', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let sessions: SessionService;
  let gateway: RealtimeGateway;
  let env: Env;
  let port: number;

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
    // Слушать нужно по-настоящему: рукопожатие WebSocket идёт через сокет,
    // а не через инъекцию запроса.
    await app.listen(0, '127.0.0.1');

    port = (app.getHttpServer().address() as AddressInfo).port;
    redis = app.get<Redis>(REDIS);
    sessions = app.get(SessionService);
    gateway = app.get(RealtimeGateway);
    env = app.get<Env>(ENV);
  });

  afterAll(async () => {
    await app.close();
    await pool.end();
  });

  beforeEach(async () => {
    await truncateAll(db);
    await redis.flushdb();
  });

  // --- Клиент ------------------------------------------------------------------

  interface Frame {
    type: string;
    [key: string]: unknown;
  }

  interface Client {
    frames: Frame[];
    send(frame: object): void;
    waitFor(match: (frame: Frame) => boolean, hint?: string): Promise<Frame>;
    waitClosed(hint?: string): Promise<number>;
    close(): void;
  }

  const opened: Client[] = [];

  afterEach(() => {
    for (const client of opened.splice(0)) {
      client.close();
    }
  });

  function connect(headers: Record<string, string>): Promise<Client> {
    const socket = new WebSocket(`ws://127.0.0.1:${port}/api/ws`, { headers });
    const frames: Frame[] = [];
    const listeners = new Set<() => void>();
    let closeCode: number | null = null;

    const notify = (): void => {
      for (const listener of [...listeners]) {
        listener();
      }
    };

    socket.on('message', (raw: Buffer) => {
      frames.push(JSON.parse(raw.toString('utf8')) as Frame);
      notify();
    });
    socket.on('close', (code) => {
      closeCode = code;
      notify();
    });

    const client: Client = {
      frames,
      send: (frame) => socket.send(JSON.stringify(frame)),
      waitFor: (match, hint = 'кадр') =>
        new Promise<Frame>((resolve, reject) => {
          const check = (): void => {
            const found = frames.find(match);
            if (found) {
              stop();
              resolve(found);
              return;
            }
            if (closeCode !== null) {
              stop();
              reject(new Error(`соединение закрылось (${closeCode}), не дождавшись: ${hint}`));
            }
          };
          const timer = setTimeout(() => {
            stop();
            reject(new Error(`не дождались: ${hint}. Пришло: ${JSON.stringify(frames)}`));
          }, 5000);
          const stop = (): void => {
            clearTimeout(timer);
            listeners.delete(check);
          };
          listeners.add(check);
          check();
        }),
      waitClosed: (hint = 'закрытие соединения') =>
        new Promise<number>((resolve, reject) => {
          const check = (): void => {
            if (closeCode !== null) {
              stop();
              resolve(closeCode);
            }
          };
          const timer = setTimeout(() => {
            stop();
            reject(new Error(`не дождались: ${hint}`));
          }, 5000);
          const stop = (): void => {
            clearTimeout(timer);
            listeners.delete(check);
          };
          listeners.add(check);
          check();
        }),
      close: () => {
        socket.removeAllListeners();
        socket.close();
        socket.terminate();
      },
    };

    return new Promise<Client>((resolve, reject) => {
      socket.once('open', () => {
        opened.push(client);
        resolve(client);
      });
      socket.once('error', reject);
    });
  }

  /** Открывает соединение и дожидается кадра `ready`. */
  async function connectReady(actor: Actor): Promise<Client> {
    const client = await connect(actor.headers);
    await client.waitFor((frame) => frame.type === 'ready', 'ready');
    return client;
  }

  async function subscribe(client: Client, topic: string, id: string): Promise<Frame> {
    client.send({ type: 'subscribe', id, topic });
    return client.waitFor(
      (frame) => (frame.type === 'subscribed' || frame.type === 'error') && frame.id === id,
      `ответ на подписку ${topic}`,
    );
  }

  /** Ждёт, пока подписки соединения действительно осядут на сервере. */
  async function settle(): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, 150));
  }

  // --- Данные ------------------------------------------------------------------

  type Headers = Record<string, string>;

  interface Actor {
    id: string;
    email: string;
    sessionId: string;
    token: string;
    headers: Headers;
  }

  async function signIn(displayName: string): Promise<Actor> {
    const user = await seedUser(db, displayName);
    await grantTrackerAccess(db, user.email);
    const session = await sessions.create(user.id, 'bearer');
    return {
      id: user.id,
      email: user.email,
      sessionId: session.id,
      token: session.token,
      headers: { authorization: `Bearer ${session.token}` },
    };
  }

  interface Workspace {
    admin: Actor;
    member: Actor;
    outsider: Actor;
    projectSlug: string;
    projectId: string;
    issueKey: string;
    statuses: Record<string, string>;
  }

  let counter = 0;

  async function workspace(): Promise<Workspace> {
    counter += 1;
    const admin = await signIn('Анна Админова');
    const member = await signIn('Борис Участников');
    const outsider = await signIn('Виктор Посторонний');

    const slug = `rt-project-${counter}`;
    const project = await seedProject(db, { name: 'Живой проект', slug, adminId: admin.id });
    await addProjectMember(db, project.id, member.id, 'member');

    const queueKey = `RT${counter}`;
    const queue = await seedQueueInProject(db, project.id, queueKey, admin.id);
    const issue = await seedIssue(db, {
      queueId: queue.queueId,
      queueKey,
      number: 1,
      title: 'Живая задача',
      statusId: queue.statusIds.open!,
      authorId: member.id,
      assigneeId: member.id,
    });

    return {
      admin,
      member,
      outsider,
      projectSlug: slug,
      projectId: project.id,
      issueKey: issue.key,
      statuses: queue.statusIds,
    };
  }

  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });
  const remove = (url: string, headers: Headers) => app.inject({ method: 'DELETE', url, headers });

  // --- Рукопожатие -------------------------------------------------------------

  describe('рукопожатие', () => {
    it('без сессии соединение не открывается вовсе, а не висит', async () => {
      await expect(connect({})).rejects.toThrow(/401/);
    });

    it('поддельный bearer отклоняется так же, как отсутствие сессии', async () => {
      await expect(
        connect({
          authorization:
            'Bearer 11111111-1111-1111-1111-111111111111.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        }),
      ).rejects.toThrow(/401/);
    });

    it('погашенная сессия соединение не открывает (US-09)', async () => {
      const actor = await signIn('Анна');
      await sessions.destroyAllForUser(actor.id);
      await expect(connect(actor.headers)).rejects.toThrow(/401/);
    });

    it('cookie принимается, когда Origin совпадает с адресом приложения', async () => {
      const actor = await signIn('Анна');
      const client = await connect({
        cookie: `${SESSION_COOKIE_NAME}=${actor.token}`,
        origin: new URL(env.APP_BASE_URL).origin,
      });
      await expect(client.waitFor((frame) => frame.type === 'ready')).resolves.toBeDefined();
    });

    it('cookie с чужого сайта отклоняется: сокет тоже угоняют', async () => {
      const actor = await signIn('Анна');
      await expect(
        connect({
          cookie: `${SESSION_COOKIE_NAME}=${actor.token}`,
          origin: 'https://evil.example.com',
        }),
      ).rejects.toThrow(/401/);
    });

    it('на своей теме соединение оказывается сразу: счётчик нужен на каждом экране', async () => {
      const actor = await signIn('Анна');
      const client = await connect(actor.headers);
      const ready = await client.waitFor((frame) => frame.type === 'ready');
      expect(ready.topics).toEqual(['user:me']);
    });
  });

  // --- Подписка ----------------------------------------------------------------

  describe('подписка', () => {
    it('участник подписывается на задачу, ярлык возвращается каноническим', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      const answer = await subscribe(client, `issue:${space.issueKey.toLowerCase()}`, '1');
      expect(answer).toEqual({ type: 'subscribed', id: '1', topic: `issue:${space.issueKey}` });
    });

    it('посторонний на задачу не подписывается', async () => {
      const space = await workspace();
      const client = await connectReady(space.outsider);

      const answer = await subscribe(client, `issue:${space.issueKey}`, '1');
      expect(answer).toEqual({
        type: 'error',
        id: '1',
        code: 'topic_forbidden',
        message: 'Тема недоступна',
      });
    });

    it('посторонний на проект не подписывается', async () => {
      const space = await workspace();
      const client = await connectReady(space.outsider);

      const answer = await subscribe(client, `project:${space.projectSlug}`, '1');
      expect(answer.type).toBe('error');
      expect(answer.code).toBe('topic_forbidden');
    });

    it('несуществующая задача отвечает тем же, что и чужая: догадаться нельзя', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      const answer = await subscribe(client, 'issue:NOPE-999', '1');
      expect(answer.code).toBe('topic_forbidden');
    });

    it('чужая тема пользователя не разбирается вовсе', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      const answer = await subscribe(client, `user:${space.admin.id}`, '1');
      expect(answer.code).toBe('invalid_topic');
    });

    it('отписка идемпотентна и не рассказывает о существовании темы', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      client.send({ type: 'unsubscribe', id: 'u1', topic: 'issue:NOPE-999' });
      const answer = await client.waitFor((frame) => frame.id === 'u1');
      expect(answer.type).toBe('unsubscribed');
    });

    it('прикладной ping получает pong: клиент сам следит за живостью сервера', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      client.send({ type: 'ping', id: 'p1' });
      await expect(client.waitFor((frame) => frame.type === 'pong')).resolves.toEqual({
        type: 'pong',
        id: 'p1',
      });
    });

    it('мусор вместо команды не роняет соединение', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      client.send({ type: 'взорвись' });
      const answer = await client.waitFor((frame) => frame.type === 'error');
      expect(answer.code).toBe('unknown_command');

      // Соединение живо: следующая команда обрабатывается как обычно.
      const ok = await subscribe(client, `issue:${space.issueKey}`, '2');
      expect(ok.type).toBe('subscribed');
    });
  });

  // --- Доставка ----------------------------------------------------------------

  describe('доставка', () => {
    it('новый комментарий доходит до подписчиков задачи', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);
      await subscribe(listener, `issue:${space.issueKey}`, '1');

      const created = await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Первый',
      });
      expect(created.statusCode).toBe(201);
      const commentId: string = created.json<{ id: string }>().id;

      const event = await listener.waitFor(
        (frame) => frame.type === 'event' && frame.event === 'comment.created',
        'comment.created',
      );
      expect(event).toMatchObject({
        type: 'event',
        topic: `issue:${space.issueKey}`,
        event: 'comment.created',
        actorId: space.admin.id,
        // Идентификатор тот же, что вернул REST: клиент по нему находит комментарий.
        data: { id: commentId, issueKey: space.issueKey },
      });
      expect(typeof event.at).toBe('string');
    });

    it('изменение полей задачи приходит с именами полей из ответа REST', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);
      await subscribe(listener, `issue:${space.issueKey}`, '1');

      const response = await patch(`/api/issues/${space.issueKey}`, space.admin.headers, {
        statusId: space.statuses.in_progress,
        title: 'Переименована',
      });
      expect(response.statusCode).toBe(200);

      const event = await listener.waitFor(
        (frame) => frame.type === 'event' && frame.event === 'issue.updated',
        'issue.updated',
      );
      expect(event.data).toEqual({
        key: space.issueKey,
        changedFields: expect.arrayContaining(['status', 'title']),
      });
    });

    it('удаление задачи доходит до открывших её', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);
      await subscribe(listener, `issue:${space.issueKey}`, '1');

      const response = await remove(`/api/issues/${space.issueKey}`, space.admin.headers);
      expect(response.statusCode).toBe(204);

      const event = await listener.waitFor(
        (frame) => frame.type === 'event' && frame.event === 'issue.deleted',
        'issue.deleted',
      );
      expect(event.data).toEqual({ key: space.issueKey });
    });

    it('уведомление и счётчик приходят на свою тему без отдельной подписки', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);

      // Участник — автор и исполнитель задачи, то есть её подписчик (D-17).
      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Есть вопрос',
      });

      const event = await listener.waitFor(
        (frame) => frame.type === 'event' && frame.event === 'notification.created',
        'notification.created',
      );
      expect(event.topic).toBe('user:me');
      expect(event.data).toMatchObject({ type: 'issue_commented', unreadCount: 1 });

      // Счётчик совпадает с тем, что отдаёт REST: иначе цифра в шапке разъедется.
      const rest = await app.inject({
        method: 'GET',
        url: '/api/notifications/unread-count',
        headers: space.member.headers,
      });
      expect(rest.json()).toEqual({
        unreadCount: (event.data as { unreadCount: number }).unreadCount,
      });
    });

    it('вступление в проект доходит до подписчиков проекта', async () => {
      const space = await workspace();
      const listener = await connectReady(space.admin);
      await subscribe(listener, `project:${space.projectSlug}`, '1');

      const invitation = await post(
        `/api/projects/${space.projectSlug}/invitations`,
        space.admin.headers,
        { role: 'member' },
      );
      expect(invitation.statusCode).toBe(201);
      const url: string = invitation.json<{ url: string }>().url;
      const token = url.slice(url.lastIndexOf('/') + 1);

      const accepted = await post(`/api/invitations/${token}/accept`, space.outsider.headers);
      expect(accepted.statusCode).toBe(200);

      const event = await listener.waitFor(
        (frame) => frame.type === 'event' && frame.event === 'project.member_joined',
        'project.member_joined',
      );
      expect(event.data).toEqual({ userId: space.outsider.id, role: 'member' });
    });

    it('посторонний не получает событий задачи, даже держа открытое соединение', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);
      await subscribe(listener, `issue:${space.issueKey}`, '1');
      const outsider = await connectReady(space.outsider);
      await subscribe(outsider, `issue:${space.issueKey}`, '1');
      await settle();

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, { body: 'Тайна' });
      await listener.waitFor((frame) => frame.event === 'comment.created', 'comment.created');

      // Событие, дошедшее до участника, до постороннего дойти уже не может:
      // рассылка идёт всем сразу.
      expect(outsider.frames.filter((frame) => frame.type === 'event')).toEqual([]);
    });
  });

  // --- Отзыв прав --------------------------------------------------------------

  describe('отзыв прав', () => {
    it('исключённый из проекта перестаёт получать события немедленно', async () => {
      const space = await workspace();
      const listener = await connectReady(space.member);
      await subscribe(listener, `issue:${space.issueKey}`, '1');
      await settle();

      const removed = await remove(
        `/api/projects/${space.projectSlug}/members/${space.member.id}`,
        space.admin.headers,
      );
      expect(removed.statusCode).toBe(200);

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Уже без него',
      });

      // Право проверяется при **рассылке**, а не только при подписке: подписка
      // снимается, событие не доходит.
      const answer = await listener.waitFor(
        (frame) => frame.type === 'error' && frame.code === 'topic_forbidden',
        'снятие подписки при рассылке',
      );
      expect(answer.code).toBe('topic_forbidden');
      expect(listener.frames.filter((frame) => frame.event === 'comment.created')).toEqual([]);
    });

    it('отзыв доступа к трекеру рвёт открытые соединения (US-09)', async () => {
      const space = await workspace();
      const owner = await signIn('Ольга Владелица');
      await db
        .update(schema.accessEntries)
        .set({ isInstanceOwner: true })
        .where(sql`${schema.accessEntries.email} = ${owner.email}`);

      const client = await connectReady(space.member);
      const [entry] = await db
        .select({ id: schema.accessEntries.id })
        .from(schema.accessEntries)
        .where(sql`${schema.accessEntries.email} = ${space.member.email}`);

      const revoked = await remove(`/api/access-entries/${entry!.id}`, owner.headers);
      expect(revoked.statusCode).toBe(200);

      await expect(client.waitClosed('закрытие сокета при отзыве доступа')).resolves.toBe(4403);
    });

    it('выход закрывает сокет, открытый под этой сессией (US-03)', async () => {
      const space = await workspace();
      const client = await connectReady(space.member);

      const response = await post('/api/auth/logout', space.member.headers);
      expect(response.statusCode).toBe(204);

      await expect(client.waitClosed('закрытие сокета при выходе')).resolves.toBe(4403);
    });
  });

  // --- Устойчивость ------------------------------------------------------------

  describe('устойчивость', () => {
    it('переподключение не ломает состояние сервера и не оставляет подписок', async () => {
      const space = await workspace();
      const before = gateway.stats();

      const first = await connectReady(space.member);
      await subscribe(first, `issue:${space.issueKey}`, '1');
      await settle();
      expect(gateway.stats().connections).toBe(before.connections + 1);
      // Своя тема плюс тема задачи.
      expect(gateway.stats().channels).toBe(before.channels + 2);

      first.close();
      await settle();
      expect(gateway.stats()).toEqual(before);

      // Клиент возвращается и подписывается заново — как в первый раз.
      const second = await connectReady(space.member);
      await subscribe(second, `issue:${space.issueKey}`, '1');
      await settle();

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'После переподключения',
      });

      await expect(
        second.waitFor(
          (frame) => frame.type === 'event' && frame.event === 'comment.created',
          'comment.created после переподключения',
        ),
      ).resolves.toBeDefined();
    });

    it('два соединения на одну тему живут независимо: уход одного не гасит второе', async () => {
      const space = await workspace();
      const first = await connectReady(space.member);
      const second = await connectReady(space.member);
      await subscribe(first, `issue:${space.issueKey}`, '1');
      await subscribe(second, `issue:${space.issueKey}`, '1');
      await settle();

      first.close();
      await settle();

      await post(`/api/issues/${space.issueKey}/comments`, space.admin.headers, {
        body: 'Второму',
      });

      await expect(
        second.waitFor((frame) => frame.event === 'comment.created', 'comment.created'),
      ).resolves.toBeDefined();
    });
  });
});
