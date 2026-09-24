import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { eq } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { loadEnv } from '../src/config/env.js';
import { DB } from '../src/database/index.js';
import * as schema from '../src/database/schema/index.js';
import { REDIS, SESSION_TTL_SECONDS, sessionKey, userSessionsKey } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { PAT_ACTIVE_LIMIT } from '../src/tokens/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Персональные токены доступа — US-200, `SPEC-PAT-API.md` §4, `RFC-MCP-SERVER.md` §6.
 *
 * Проверяется на настоящих PostgreSQL и Redis: у токена нет собственного пути проверки,
 * он живёт кэшем сессий и отзывом через Redis, поэтому тест на моках не доказывал бы
 * ничего из того, ради чего он написан.
 *
 * Главная проверка блока — «скоуп равен роли»: машинный доступ не должен давать ничего
 * сверх прав человека, которому выдан токен.
 */
describe('Токены доступа (PAT)', () => {
  const APP_ORIGIN = new URL(loadEnv().APP_BASE_URL).origin;
  const DAY_MS = 24 * 60 * 60 * 1000;

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
    // Вместе с сессиями вычищаются и счётчики ограничения частоты: без этого
    // соседний тест упирался бы в 429 на выпуске токена.
    await redis.flushdb();
  });

  type Headers = Record<string, string>;

  interface Person {
    id: string;
    displayName: string;
    email: string;
    /** Браузерная сессия: только ей разрешено управлять токенами. */
    web: Headers;
  }

  const get = (url: string, headers: Headers) => app.inject({ method: 'GET', url, headers });
  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const patch = (url: string, headers: Headers, body: object) =>
    app.inject({ method: 'PATCH', url, headers, payload: body });
  const del = (url: string, headers: Headers) => app.inject({ method: 'DELETE', url, headers });

  /** Заголовки клиента с токеном: ровно то, что отправит MCP-сервер. */
  const asToken = (token: string): Headers => ({ authorization: `Bearer ${token}` });

  /**
   * Вход через браузер. Cookie-сессия создаётся напрямую сервисом: обмен с Яндекс ID
   * проверяется в `auth.e2e-spec.ts`, здесь он ничего не добавил бы.
   * Заголовок `Origin` обязателен — небезопасные методы под cookie проходят проверку CSRF.
   */
  async function signInWeb(displayName: string, email?: string): Promise<Person> {
    const user = await seedUser(db, displayName, email);
    const session = await sessions.create(user.id, 'cookie');
    return {
      id: user.id,
      displayName,
      email: user.email,
      web: { cookie: `sl_session=${session.token}`, origin: APP_ORIGIN },
    };
  }

  interface IssuedToken {
    id: string;
    name: string;
    prefix: string;
    token: string;
    expiresAt: string;
    createdAt: string;
  }

  async function issueToken(
    person: Person,
    body: { name: string; expiresInDays?: number } = { name: 'dsh-mcp' },
  ): Promise<IssuedToken> {
    const response = await post('/api/tokens', person.web, body);
    expect(response.statusCode).toBe(201);
    return response.json<IssuedToken>();
  }

  /** Секретная часть токена — та, по которой проверяется подлинность. */
  const verifierOf = (token: string): string => token.slice(token.indexOf('.') + 1);

  interface Workspace {
    admin: Person;
    statuses: Record<string, string>;
    projectId: string;
  }

  /** Проект `sladkiy-limit` с очередью `DEV` и её статусами по умолчанию. */
  async function seedWorkspace(): Promise<Workspace> {
    const admin = await signInWeb('Анна Админова');
    const project = await seedProject(db, {
      name: 'Сладкий Лимит',
      slug: 'sladkiy-limit',
      adminId: admin.id,
    });

    const created = await post('/api/projects/sladkiy-limit/queues', admin.web, {
      key: 'DEV',
      name: 'Разработка',
    });
    expect(created.statusCode).toBe(201);

    const list = (await get('/api/queues/DEV/statuses', admin.web)).json<{
      items: { key: string; id: string }[];
    }>();
    const statuses: Record<string, string> = {};
    for (const status of list.items) {
      statuses[status.key] = status.id;
    }

    return { admin, statuses, projectId: project.id };
  }

  /** Участник проекта с заданной ролью и токеном в руках. */
  async function memberWithToken(
    projectId: string,
    role: 'admin' | 'member' | 'reader',
    displayName: string,
  ): Promise<{ person: Person; issued: IssuedToken; headers: Headers }> {
    const person = await signInWeb(displayName);
    await addProjectMember(db, projectId, person.id, role);
    const issued = await issueToken(person, { name: `${role}-mcp` });
    return { person, issued, headers: asToken(issued.token) };
  }

  describe('§4.1 выпуск: токен работает как сессия владельца', () => {
    it('выпускает токен из cookie-сессии и отдаёт секрет один раз', async () => {
      const owner = await signInWeb('Иван Петров');

      const response = await post('/api/tokens', owner.web, {
        name: 'dsh-mcp',
        expiresInDays: 365,
      });

      expect(response.statusCode).toBe(201);
      const issued = response.json<IssuedToken>();
      expect(issued).toMatchObject({ name: 'dsh-mcp' });
      expect(issued.token).toContain('.');
      expect(issued.prefix).toBe(issued.token.slice(0, 8));
      expect(Math.round((Date.parse(issued.expiresAt) - Date.now()) / DAY_MS)).toBe(365);
    });

    it('запрос токеном обслуживается как запрос владельца: тот же userId', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);

      const web = await get('/api/me', owner.web);
      const machine = await get('/api/me', asToken(issued.token));

      expect(machine.statusCode).toBe(200);
      expect(machine.json().id).toBe(owner.id);
      expect(machine.json().id).toBe(web.json().id);
      expect(machine.json().session.kind).toBe('bearer');
    });

    it('без срока токен живёт 365 дней', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'по умолчанию' });

      expect(Math.round((Date.parse(issued.expiresAt) - Date.now()) / DAY_MS)).toBe(365);
    });

    it('секрет не попадает ни в базу, ни в Redis: хранится только HMAC', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);
      const verifier = verifierOf(issued.token);

      const [row] = await db
        .select()
        .from(schema.sessions)
        .where(eq(schema.sessions.id, issued.id));
      expect(JSON.stringify(row)).not.toContain(verifier);
      expect(row!.tokenHash).toHaveLength(64);
      expect(row!.purpose).toBe('pat');
      expect(row!.label).toBe('dsh-mcp');

      const cached = await redis.hgetall(sessionKey(issued.id));
      expect(JSON.stringify(cached)).not.toContain(verifier);
    });

    it('чужим токеном себе токен не выпустишь: владелец всегда текущий пользователь', async () => {
      const owner = await signInWeb('Иван Петров');
      const other = await signInWeb('Пётр Иванов');

      const response = await post('/api/tokens', owner.web, {
        name: 'подарок',
        userId: other.id,
      });

      // Лишнее поле отсекается валидацией, а не молча игнорируется.
      expect(response.statusCode).toBe(400);
    });

    it('двадцать первый действующий токен отклоняется с token_limit_reached', async () => {
      const owner = await signInWeb('Иван Петров');
      // Токены заводятся сервисом, а не через API: двадцать запросов подряд упёрлись бы
      // в ограничение частоты, а проверяется здесь лимит, а не частота.
      for (let index = 0; index < PAT_ACTIVE_LIMIT; index += 1) {
        await sessions.create(owner.id, 'bearer', {
          label: `токен ${index}`,
          purpose: 'pat',
          ttlSeconds: 365 * 24 * 60 * 60,
        });
      }

      const response = await post('/api/tokens', owner.web, { name: 'двадцать первый' });

      expect(response.statusCode).toBe(409);
      expect(response.json().code).toBe('token_limit_reached');
    });
  });

  describe('§4.2 список: секрета в нём нет', () => {
    it('в ответе нет поля token и нет самого секрета ни в каком виде', async () => {
      const owner = await signInWeb('Иван Петров');
      const first = await issueToken(owner, { name: 'ноутбук' });
      const second = await issueToken(owner, { name: 'dsh-mcp' });

      const response = await get('/api/tokens', owner.web);

      expect(response.statusCode).toBe(200);
      const body = response.json<{ items: Record<string, unknown>[]; total: number }>();
      expect(body.total).toBe(2);
      // Сначала новые.
      expect(body.items.map((item) => item.name)).toEqual(['dsh-mcp', 'ноутбук']);
      for (const item of body.items) {
        expect(item).not.toHaveProperty('token');
        expect(item).not.toHaveProperty('tokenHash');
      }
      expect(response.payload).not.toContain(verifierOf(first.token));
      expect(response.payload).not.toContain(verifierOf(second.token));
      expect(body.items[0]).toMatchObject({ prefix: second.prefix, purpose: 'pat' });
    });

    it('сессии входа в список токенов не попадают', async () => {
      const owner = await signInWeb('Иван Петров');
      await issueToken(owner);

      const body = (await get('/api/tokens', owner.web)).json<{ total: number }>();
      // У владельца есть ещё и cookie-сессия, но это не токен.
      expect(body.total).toBe(1);
    });

    it('отозванные по умолчанию скрыты и показываются по includeRevoked=true', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);
      expect((await del(`/api/tokens/${issued.id}`, owner.web)).statusCode).toBe(204);

      const hidden = (await get('/api/tokens', owner.web)).json<{ total: number }>();
      expect(hidden.total).toBe(0);

      const shown = (await get('/api/tokens?includeRevoked=true', owner.web)).json<{
        items: { id: string; revokedAt: string | null }[];
      }>();
      expect(shown.items).toHaveLength(1);
      expect(shown.items[0]!.revokedAt).not.toBeNull();
    });
  });

  describe('§4.3 отзыв', () => {
    it('DELETE отвечает 204, следующий запрос токеном — 401 session_expired', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);

      const revoked = await del(`/api/tokens/${issued.id}`, owner.web);
      expect(revoked.statusCode).toBe(204);

      const after = await get('/api/me', asToken(issued.token));
      expect(after.statusCode).toBe(401);
      expect(after.json().code).toBe('session_expired');
    });

    it('повторный отзыв своего токена — тоже 204', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);

      expect((await del(`/api/tokens/${issued.id}`, owner.web)).statusCode).toBe(204);
      expect((await del(`/api/tokens/${issued.id}`, owner.web)).statusCode).toBe(204);
    });

    it('отзыв токена не трогает ни браузерную сессию владельца, ни его другие токены', async () => {
      const owner = await signInWeb('Иван Петров');
      const doomed = await issueToken(owner, { name: 'утёкший' });
      const spared = await issueToken(owner, { name: 'рабочий' });

      expect((await del(`/api/tokens/${doomed.id}`, owner.web)).statusCode).toBe(204);

      expect((await get('/api/me', owner.web)).statusCode).toBe(200);
      expect((await get('/api/me', asToken(spared.token))).statusCode).toBe(200);
      expect((await get('/api/me', asToken(doomed.token))).statusCode).toBe(401);
    });

    it('несуществующий идентификатор — 404', async () => {
      const owner = await signInWeb('Иван Петров');

      const response = await del('/api/tokens/00000000-0000-4000-8000-000000000000', owner.web);
      expect(response.statusCode).toBe(404);
      expect(response.json().code).toBe('not_found');
    });

    it('сессию входа через раздел токенов отозвать нельзя', async () => {
      const owner = await signInWeb('Иван Петров');
      const cookieSession = await sessions.create(owner.id, 'cookie');

      const response = await del(`/api/tokens/${cookieSession.id}`, owner.web);

      expect(response.statusCode).toBe(404);
      const check = await get('/api/me', {
        cookie: `sl_session=${cookieSession.token}`,
      });
      expect(check.statusCode).toBe(200);
    });
  });

  describe('§4.4 токеном токенами не управляют', () => {
    it('POST /api/tokens с токеном — 403 pat_cannot_manage_tokens', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);

      const response = await post('/api/tokens', asToken(issued.token), { name: 'ещё один' });

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('pat_cannot_manage_tokens');
      // Ни одного лишнего токена в базе не появилось.
      const body = (await get('/api/tokens', owner.web)).json<{ total: number }>();
      expect(body.total).toBe(1);
    });

    it('GET /api/tokens с токеном — 403: список чужих токенов это разведка перед отзывом', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner);

      const response = await get('/api/tokens', asToken(issued.token));

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('pat_cannot_manage_tokens');
    });

    it('DELETE /api/tokens/{id} с токеном — 403, и токен продолжает работать', async () => {
      const owner = await signInWeb('Иван Петров');
      const first = await issueToken(owner, { name: 'первый' });
      const second = await issueToken(owner, { name: 'второй' });

      const response = await del(`/api/tokens/${second.id}`, asToken(first.token));

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('pat_cannot_manage_tokens');
      expect((await get('/api/me', asToken(second.token))).statusCode).toBe(200);
    });
  });

  describe('§4.5 чужой токен', () => {
    it('отзыв чужого токена — 404, и у владельца он продолжает работать', async () => {
      const owner = await signInWeb('Иван Петров');
      const stranger = await signInWeb('Пётр Посторонний');
      const issued = await issueToken(owner, { name: 'dsh-mcp' });

      const response = await del(`/api/tokens/${issued.id}`, stranger.web);

      expect(response.statusCode).toBe(404);
      expect(response.json().code).toBe('not_found');
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);

      const [row] = await db
        .select({ revokedAt: schema.sessions.revokedAt })
        .from(schema.sessions)
        .where(eq(schema.sessions.id, issued.id));
      expect(row!.revokedAt).toBeNull();
    });

    it('чужие токены не видны в списке', async () => {
      const owner = await signInWeb('Иван Петров');
      const stranger = await signInWeb('Пётр Посторонний');
      await issueToken(owner, { name: 'dsh-mcp' });

      const body = (await get('/api/tokens?includeRevoked=true', stranger.web)).json<{
        total: number;
      }>();
      expect(body.total).toBe(0);
    });
  });

  describe('§4.6 скоуп равен роли владельца', () => {
    it('токен читателя открывает задачу, но не меняет её и не комментирует', async () => {
      const { admin, statuses, projectId } = await seedWorkspace();
      const reader = await memberWithToken(projectId, 'reader', 'Вера Читателева');
      const issue = await post('/api/queues/DEV/issues', admin.web, { title: 'Задача' });
      expect(issue.statusCode).toBe(201);

      const read = await get('/api/issues/DEV-1', reader.headers);
      expect(read.statusCode).toBe(200);
      expect(read.json().key).toBe('DEV-1');

      const edited = await patch('/api/issues/DEV-1', reader.headers, { title: 'Правка агента' });
      expect(edited.statusCode).toBe(403);
      expect(edited.json().code).toBe('issue_forbidden');

      const statusChange = await patch('/api/issues/DEV-1', reader.headers, {
        statusId: statuses.closed,
      });
      expect(statusChange.statusCode).toBe(403);

      const commented = await post('/api/issues/DEV-1/comments', reader.headers, {
        body: 'Комментарий агента',
      });
      expect(commented.statusCode).toBe(403);
      expect(commented.json().code).toBe('comment_forbidden');

      // Читатель не создаёт и задач.
      expect(
        (await post('/api/queues/DEV/issues', reader.headers, { title: 'Своя' })).statusCode,
      ).toBe(403);
    });

    it('токен участника делает то же, что участник, и подписывает всё владельцем токена', async () => {
      const { statuses, projectId } = await seedWorkspace();
      const member = await memberWithToken(projectId, 'member', 'Борис Участников');

      const created = await post('/api/queues/DEV/issues', member.headers, {
        title: 'Задача от агента',
      });
      expect(created.statusCode).toBe(201);
      expect(created.json().author).toMatchObject({
        id: member.person.id,
        displayName: 'Борис Участников',
      });

      const edited = await patch('/api/issues/DEV-1', member.headers, {
        description: 'Описание от агента',
      });
      expect(edited.statusCode).toBe(200);

      const statusChange = await patch('/api/issues/DEV-1', member.headers, {
        statusId: statuses.closed,
      });
      expect(statusChange.statusCode).toBe(200);
      expect(statusChange.json().status.key).toBe('closed');

      const comment = await post('/api/issues/DEV-1/comments', member.headers, {
        body: 'Комментарий от агента',
      });
      expect(comment.statusCode).toBe(201);
      expect(comment.json().author).toMatchObject({ id: member.person.id });
    });

    it('в проекте, где владелец не состоит, токен получает 404, а не 403', async () => {
      const { admin, projectId } = await seedWorkspace();
      const outsider = await signInWeb('Гриша Посторонний');
      const issued = await issueToken(outsider, { name: 'чужой-mcp' });
      expect(projectId).toBeTruthy();

      const created = await post('/api/queues/DEV/issues', admin.web, { title: 'Задача' });
      expect(created.statusCode).toBe(201);

      const read = await get('/api/issues/DEV-1', asToken(issued.token));
      expect(read.statusCode).toBe(404);
    });
  });

  describe('§4.7 использование не продлевает срок', () => {
    /** Сессия «была здесь» больше суток назад: иначе `touch` не сработает по порогу. */
    async function ageSession(id: string): Promise<void> {
      await db
        .update(schema.sessions)
        .set({ lastSeenAt: new Date(Date.now() - 2 * DAY_MS) })
        .where(eq(schema.sessions.id, id));
      // Кэш хранит прежний `lastSeenAt`: без сброса сессия поднимется из Redis
      // со свежей отметкой и порог не сработает.
      await redis.del(sessionKey(id));
    }

    it('отметка «последний раз использован» обновляется не чаще раза в сутки', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'dsh-mcp' });

      async function lastSeenAt(): Promise<string> {
        const body = (await get('/api/tokens', owner.web)).json<{
          items: { lastSeenAt: string }[];
        }>();
        return body.items[0]!.lastSeenAt;
      }

      const beforeUse = await lastSeenAt();
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);

      // Осознанный порог `SessionService.touch`: иначе каждый запрос агента был бы
      // записью в PostgreSQL. Отметка «последний раз использован» огрубляется до суток,
      // и это видно на экране токенов — там она в первые сутки не двигается.
      expect(await lastSeenAt()).toBe(beforeUse);
    });

    it('токен: expiresAt не двигается, lastSeenAt обновляется', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'dsh-mcp', expiresInDays: 1 });
      await ageSession(issued.id);

      const response = await get('/api/me', asToken(issued.token));
      expect(response.statusCode).toBe(200);

      const [row] = await db
        .select({ expiresAt: schema.sessions.expiresAt, lastSeenAt: schema.sessions.lastSeenAt })
        .from(schema.sessions)
        .where(eq(schema.sessions.id, issued.id));

      expect(row!.expiresAt.toISOString()).toBe(issued.expiresAt);
      expect(Date.now() - row!.lastSeenAt.getTime()).toBeLessThan(60_000);
    });

    it('обычная сессия входа, наоборот, продлевается — иначе проверка выше ничего не значит', async () => {
      const user = await seedUser(db, 'Иван Петров');
      const session = await sessions.create(user.id, 'cookie', { ttlSeconds: 3600 });
      await ageSession(session.id);

      const response = await get('/api/me', { cookie: `sl_session=${session.token}` });
      expect(response.statusCode).toBe(200);

      const [row] = await db
        .select({ expiresAt: schema.sessions.expiresAt })
        .from(schema.sessions)
        .where(eq(schema.sessions.id, session.id));

      expect(row!.expiresAt.getTime()).toBeGreaterThan(session.expiresAt.getTime());
      expect(Math.round((row!.expiresAt.getTime() - Date.now()) / DAY_MS)).toBe(30);
    });
  });

  describe('§4.8 истёкший токен', () => {
    it('токен с истёкшим сроком отклоняется как истёкшая сессия', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'старый', expiresInDays: 1 });

      await db
        .update(schema.sessions)
        .set({ expiresAt: new Date(Date.now() - 60_000) })
        .where(eq(schema.sessions.id, issued.id));
      // Кэш ещё помнит живой срок — это отдельный путь проверки, и его тоже надо пройти.
      await redis.del(sessionKey(issued.id));

      const response = await get('/api/me', asToken(issued.token));

      expect(response.statusCode).toBe(401);
      expect(response.json().code).toBe('session_expired');
    });

    it('истёкший токен виден в списке как просроченный, а не пропадает', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'старый', expiresInDays: 1 });
      await db
        .update(schema.sessions)
        .set({ expiresAt: new Date(Date.now() - 60_000) })
        .where(eq(schema.sessions.id, issued.id));

      const body = (await get('/api/tokens', owner.web)).json<{
        items: { id: string; expiresAt: string }[];
      }>();
      expect(body.items).toHaveLength(1);
      expect(Date.parse(body.items[0]!.expiresAt)).toBeLessThan(Date.now());
    });
  });

  describe('§4.9 отзыв доступа гасит токены', () => {
    /**
     * Владелец токена и владелец трекера, который этот доступ отзывает.
     * Отзывать свою запись нельзя, поэтому людей ровно двое.
     */
    async function ownerWithAccessEntry(): Promise<{
      owner: Person;
      boss: Headers;
      entryId: string;
    }> {
      const owner = await signInWeb('Иван Петров', 'ivan@example.com');
      const bossUser = await seedUser(db, 'Ольга Владелева', 'olga@example.com');
      await db.insert(schema.accessEntries).values({
        email: 'olga@example.com',
        source: 'config',
        isInstanceOwner: true,
      });
      const [entry] = await db
        .insert(schema.accessEntries)
        .values({ email: 'ivan@example.com', source: 'manual' })
        .returning({ id: schema.accessEntries.id });

      const bossSession = await sessions.create(bossUser.id, 'bearer');
      return {
        owner,
        boss: asToken(bossSession.token),
        entryId: entry!.id,
      };
    }

    it('отзыв доступа владельцу гасит его токен немедленно', async () => {
      const { owner, boss, entryId } = await ownerWithAccessEntry();
      const issued = await issueToken(owner, { name: 'dsh-mcp' });
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);

      const revoked = await del(`/api/access-entries/${entryId}`, boss);
      expect(revoked.statusCode).toBe(200);
      expect(revoked.json().revokedSessions).toBeGreaterThanOrEqual(2);

      const response = await get('/api/me', asToken(issued.token));
      expect(response.statusCode).toBe(401);
      expect(response.json().code).toBe('session_expired');
    });

    it('регрессия: годовой токен гасится отзывом доступа, даже если множество сессий в Redis пропало', async () => {
      const { owner, boss, entryId } = await ownerWithAccessEntry();
      const issued = await issueToken(owner, { name: 'dsh-mcp', expiresInDays: 365 });
      expect((await get('/api/me', asToken(issued.token))).statusCode).toBe(200);

      // Множество `sl:sessions:by-user:<id>` живёт 31 день, а токен — год. Здесь
      // воспроизводится момент, когда множество уже истекло, а ключ сессии — ещё нет:
      // если уборка кэша держится только на множестве, отзыв доступа токен не погасит,
      // и он останется рабочим на месяцы (`SessionService.cache`).
      await redis.del(userSessionsKey(owner.id));
      expect(await redis.exists(sessionKey(issued.id))).toBe(1);

      expect((await del(`/api/access-entries/${entryId}`, boss)).statusCode).toBe(200);

      const response = await get('/api/me', asToken(issued.token));
      expect(response.statusCode).toBe(401);
      expect(response.json().code).toBe('session_expired');
      expect(await redis.exists(sessionKey(issued.id))).toBe(0);
    });

    it('инвариант кэша: ключ сессии не живёт дольше множества сессий пользователя', async () => {
      const owner = await signInWeb('Иван Петров');
      const issued = await issueToken(owner, { name: 'годовой', expiresInDays: 365 });

      const sessionTtl = await redis.ttl(sessionKey(issued.id));
      const setTtl = await redis.ttl(userSessionsKey(owner.id));

      expect(sessionTtl).toBeGreaterThan(0);
      expect(setTtl).toBeGreaterThan(0);
      expect(sessionTtl).toBeLessThanOrEqual(setTtl);
      // Верхняя граница — срок обычной сессии, а не срок токена.
      expect(sessionTtl).toBeLessThanOrEqual(SESSION_TTL_SECONDS);
    });
  });

  describe('охрана маршрутов', () => {
    it('без сессии все три маршрута отвечают 401', async () => {
      const anonymous: Headers = { origin: APP_ORIGIN };

      expect((await get('/api/tokens', anonymous)).statusCode).toBe(401);
      expect((await post('/api/tokens', anonymous, { name: 'x' })).statusCode).toBe(401);
      expect(
        (await del('/api/tokens/00000000-0000-4000-8000-000000000000', anonymous)).statusCode,
      ).toBe(401);
    });
  });
});
