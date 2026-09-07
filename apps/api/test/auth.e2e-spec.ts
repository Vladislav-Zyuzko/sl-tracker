import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import { FastifyAdapter, type NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { sql } from 'drizzle-orm';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import type { Redis } from 'ioredis';
import type pg from 'pg';
import { AccessBootstrapService } from '../src/access/index.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import {
  YANDEX_OAUTH,
  type YandexOAuthPort,
  YandexOAuthError,
  type YandexProfile,
} from '../src/auth/index.js';
import { loadEnv } from '../src/config/env.js';
import { DB } from '../src/database/index.js';
import * as schema from '../src/database/schema/index.js';
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Сквозная проверка входа, сессий и списка доступа на настоящих PostgreSQL и Redis.
 *
 * Единственная подделка — обмен с Яндекс ID: боевых `client_id` и `client_secret`
 * у нас пока нет (приложение не зарегистрировано), поэтому провайдер подставляется
 * через токен `YANDEX_OAUTH`. Всё остальное — настоящее: `state` в Redis, cookie,
 * охрана запроса, транзакции, гашение сессий.
 */

const APP_ORIGIN = new URL(loadEnv().APP_BASE_URL).origin;

const BASE_PROFILE: YandexProfile = {
  externalId: 'yandex-1000',
  displayName: 'Иван Петров',
  email: 'Ivan@Yandex.RU',
  avatarUrl: 'https://avatars.yandex.net/get-yapic/a/islands-200',
};

class FakeYandex implements YandexOAuthPort {
  configured = true;
  profile: YandexProfile = BASE_PROFILE;
  failure: YandexOAuthError | null = null;
  readonly usedCodes = new Set<string>();

  isConfigured(): boolean {
    return this.configured;
  }

  buildAuthorizeUrl(state: string): string {
    return `https://oauth.yandex.ru/authorize?response_type=code&state=${state}`;
  }

  exchangeCode(code: string): Promise<string> {
    if (this.failure) {
      return Promise.reject(this.failure);
    }
    if (this.usedCodes.has(code)) {
      return Promise.reject(
        new YandexOAuthError('provider_unavailable', 'код уже использован (invalid_grant)'),
      );
    }
    this.usedCodes.add(code);
    return Promise.resolve(`access-token-${code}`);
  }

  fetchProfile(): Promise<YandexProfile> {
    return Promise.resolve(this.profile);
  }
}

describe('Вход через Яндекс ID, сессии и список доступа', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let yandex: FakeYandex;
  let codeCounter = 0;

  beforeAll(async () => {
    await prepareTestDatabase();
    pool = createTestPool(10);
    db = createTestDb(pool);
    yandex = new FakeYandex();

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DB)
      .useValue(db)
      .overrideProvider(YANDEX_OAUTH)
      .useValue(yandex)
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter(), {
      logger: false,
    });
    await configureApp(app);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    redis = app.get<Redis>(REDIS);
  });

  afterAll(async () => {
    await app.close();
    await pool.end();
  });

  beforeEach(async () => {
    await truncateAll(db);
    yandex.profile = BASE_PROFILE;
    yandex.failure = null;
    yandex.usedCodes.clear();
    // Счётчики ограничения частоты живут в Redis дольше прогона: без уборки
    // повторный запуск тестов упирался бы в 429.
    const keys = await redis.keys('sl:ratelimit:*');
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  });

  /** Заводит запись в списке доступа так, как это делает конфигурация инстанса. */
  async function grantAccess(
    email: string,
    options: { owner?: boolean; source?: 'config' | 'manual' | 'invitation' } = {},
  ): Promise<string> {
    const [row] = await db
      .insert(schema.accessEntries)
      .values({
        email: email.toLowerCase(),
        source: options.source ?? 'config',
        isInstanceOwner: options.owner ?? false,
      })
      .returning({ id: schema.accessEntries.id });
    return row!.id;
  }

  /** Старт входа: возвращает `state`, реально выданный сервером и лежащий в Redis. */
  async function startLogin(query = ''): Promise<string> {
    const response = await app.inject({
      method: 'GET',
      url: `/api/auth/yandex/start${query}`,
    });
    expect(response.statusCode).toBe(302);
    const location = response.headers.location;
    const state = new URL(String(location)).searchParams.get('state');
    expect(state).toBeTruthy();
    return state!;
  }

  function callback(params: Record<string, string>) {
    const query = new URLSearchParams(params).toString();
    return app.inject({ method: 'GET', url: `/api/auth/yandex/callback?${query}` });
  }

  /** Полный вход: возвращает значение cookie сессии. */
  async function login(options: { next?: string; invite?: string } = {}): Promise<string> {
    const query = new URLSearchParams();
    if (options.next) {
      query.set('next', options.next);
    }
    if (options.invite) {
      query.set('invite', options.invite);
    }
    const state = await startLogin(query.size > 0 ? `?${query.toString()}` : '');
    const response = await callback({ code: `code-${(codeCounter += 1)}`, state });
    expect(response.statusCode).toBe(302);

    const cookie = response.cookies.find((item) => item.name === 'sl_session');
    if (!cookie) {
      throw new Error(`сессия не выдана, редирект на ${String(response.headers.location)}`);
    }
    return cookie.value;
  }

  function withSession(cookie: string) {
    return { cookie: `sl_session=${cookie}` };
  }

  describe('US-01, US-05: вход', () => {
    it('пускает человека из списка доступа, ставит httpOnly-cookie и возвращает на цель', async () => {
      await grantAccess('ivan@yandex.ru');

      const state = await startLogin('?next=/issues/DEV-42');
      const response = await callback({ code: 'code-ok', state });

      expect(response.statusCode).toBe(302);
      expect(response.headers.location).toBe(`${APP_ORIGIN}/issues/DEV-42`);

      const cookie = response.cookies.find((item) => item.name === 'sl_session');
      expect(cookie).toBeDefined();
      expect(cookie?.httpOnly).toBe(true);
      expect(cookie?.sameSite?.toLowerCase()).toBe('lax');
      expect(cookie?.path).toBe('/');

      const me = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: withSession(cookie!.value),
      });
      expect(me.statusCode).toBe(200);
      expect(me.json()).toMatchObject({
        displayName: 'Иван Петров',
        email: 'ivan@yandex.ru',
        isInstanceOwner: false,
        canManageAccessList: false,
        session: { kind: 'cookie' },
      });
    });

    it('повторный вход тем же аккаунтом не создаёт второго пользователя и обновляет профиль', async () => {
      await grantAccess('ivan@yandex.ru');
      await login();

      yandex.profile = { ...BASE_PROFILE, displayName: 'Иван Сидоров', avatarUrl: null };
      const cookie = await login();

      const users = await db.select({ id: schema.users.id }).from(schema.users);
      expect(users).toHaveLength(1);

      const me = await app.inject({ method: 'GET', url: '/api/me', headers: withSession(cookie) });
      expect(me.json()).toMatchObject({ displayName: 'Иван Сидоров', avatarUrl: null });
    });

    it('отказывает, когда адреса нет в списке: ни сессии, ни пользователя', async () => {
      const state = await startLogin();
      const response = await callback({ code: 'code-denied', state });

      expect(response.statusCode).toBe(302);
      const location = new URL(String(response.headers.location));
      expect(location.pathname).toBe('/access-denied');
      expect(response.cookies.find((item) => item.name === 'sl_session')).toBeUndefined();

      const users = await db.select({ id: schema.users.id }).from(schema.users);
      expect(users).toHaveLength(0);

      // Адреса в адресной строке нет — только одноразовый тикет.
      expect(location.search).not.toContain('@');
      const ticket = location.searchParams.get('ticket');
      expect(ticket).toBeTruthy();

      const info = await app.inject({
        method: 'GET',
        url: `/api/auth/access-denied/${String(ticket)}`,
      });
      expect(info.statusCode).toBe(200);
      expect(info.json()).toEqual({ email: 'ivan@yandex.ru' });

      // Тикет одноразовый.
      const again = await app.inject({
        method: 'GET',
        url: `/api/auth/access-denied/${String(ticket)}`,
      });
      expect(again.statusCode).toBe(404);
    });

    it('действующее приглашение пускает в обход списка доступа', async () => {
      const [user] = await db
        .insert(schema.users)
        .values({ displayName: 'Админ проекта', email: 'admin@example.com' })
        .returning({ id: schema.users.id });

      const slug = 'invite-project';
      const projectId = crypto.randomUUID();
      await db.insert(schema.projectSlugs).values({ slug, projectId: null, isCurrent: false });
      await db
        .insert(schema.projects)
        .values({ id: projectId, name: 'Проект', slug, createdByUserId: user!.id });
      await db
        .update(schema.projectSlugs)
        .set({ projectId, isCurrent: true })
        .where(sql`${schema.projectSlugs.slug} = ${slug}`);
      await db.insert(schema.invitations).values({
        projectId,
        token: 'invite-token-1',
        role: 'member',
        expiresAt: new Date(Date.now() + 86_400_000),
        createdByUserId: user!.id,
      });

      const cookie = await login({ invite: 'invite-token-1' });

      const me = await app.inject({ method: 'GET', url: '/api/me', headers: withSession(cookie) });
      expect(me.statusCode).toBe(200);
    });

    it('просроченное приглашение не пускает', async () => {
      const [user] = await db
        .insert(schema.users)
        .values({ displayName: 'Админ', email: 'admin@example.com' })
        .returning({ id: schema.users.id });

      const slug = 'expired-project';
      const projectId = crypto.randomUUID();
      await db.insert(schema.projectSlugs).values({ slug, projectId: null, isCurrent: false });
      await db
        .insert(schema.projects)
        .values({ id: projectId, name: 'Проект', slug, createdByUserId: user!.id });
      await db
        .update(schema.projectSlugs)
        .set({ projectId, isCurrent: true })
        .where(sql`${schema.projectSlugs.slug} = ${slug}`);
      await db.insert(schema.invitations).values({
        projectId,
        token: 'expired-token',
        role: 'member',
        expiresAt: new Date(Date.now() - 1000),
        createdByUserId: user!.id,
      });

      const state = await startLogin('?invite=expired-token');
      const response = await callback({ code: 'code-expired', state });

      expect(new URL(String(response.headers.location)).pathname).toBe('/access-denied');
    });
  });

  describe('ADR-0002: проверка state', () => {
    it('без параметра state отвечает 400 и ничего не делает', async () => {
      await grantAccess('ivan@yandex.ru');

      const response = await callback({ code: 'code-no-state' });

      expect(response.statusCode).toBe(400);
      const users = await db.select({ id: schema.users.id }).from(schema.users);
      expect(users).toHaveLength(0);
    });

    it('чужой state уводит на экран входа с invalid_state', async () => {
      await grantAccess('ivan@yandex.ru');

      const response = await callback({ code: 'code-foreign', state: 'A'.repeat(43) });

      expect(response.statusCode).toBe(302);
      const location = new URL(String(response.headers.location));
      expect(location.pathname).toBe('/login');
      expect(location.searchParams.get('error')).toBe('invalid_state');
      expect(response.cookies.find((item) => item.name === 'sl_session')).toBeUndefined();
    });

    it('повторный колбэк с тем же code второй сессии не создаёт', async () => {
      await grantAccess('ivan@yandex.ru');
      const state = await startLogin();

      const first = await callback({ code: 'code-reuse', state });
      const second = await callback({ code: 'code-reuse', state });

      expect(first.cookies.find((item) => item.name === 'sl_session')).toBeDefined();
      expect(second.statusCode).toBe(302);
      expect(new URL(String(second.headers.location)).searchParams.get('error')).toBe(
        'invalid_state',
      );
      expect(second.cookies.find((item) => item.name === 'sl_session')).toBeUndefined();

      const rows = await db.select({ id: schema.sessions.id }).from(schema.sessions);
      expect(rows).toHaveLength(1);
    });

    it('отказ пользователя на стороне Яндекса — понятный код, а не 500', async () => {
      const response = await callback({ error: 'access_denied', state: 'B'.repeat(43) });
      expect(new URL(String(response.headers.location)).searchParams.get('error')).toBe(
        'access_denied',
      );
    });

    it('unauthorized_client (приложение на модерации) уводит на экран входа с этим кодом', async () => {
      await grantAccess('ivan@yandex.ru');
      yandex.failure = new YandexOAuthError('unauthorized_client', 'на модерации');
      const state = await startLogin();

      const response = await callback({ code: 'code-moderation', state });

      expect(response.statusCode).toBe(302);
      expect(new URL(String(response.headers.location)).searchParams.get('error')).toBe(
        'unauthorized_client',
      );
    });
  });

  describe('US-02, US-03: сессия', () => {
    it('без сессии /api/me отвечает 401', async () => {
      const response = await app.inject({ method: 'GET', url: '/api/me' });
      expect(response.statusCode).toBe(401);
      expect(response.json()).toMatchObject({ code: 'session_required' });
    });

    it('подделанный токен не проходит', async () => {
      await grantAccess('ivan@yandex.ru');
      const cookie = await login();
      const [id] = cookie.split('.');

      const response = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: withSession(`${String(id)}.${'z'.repeat(43)}`),
      });
      expect(response.statusCode).toBe(401);
    });

    it('выход гасит сессию на сервере, а не только чистит cookie', async () => {
      await grantAccess('ivan@yandex.ru');
      const cookie = await login();

      const logout = await app.inject({
        method: 'POST',
        url: '/api/auth/logout',
        headers: { ...withSession(cookie), origin: APP_ORIGIN },
      });
      expect(logout.statusCode).toBe(204);

      const me = await app.inject({ method: 'GET', url: '/api/me', headers: withSession(cookie) });
      expect(me.statusCode).toBe(401);

      const [row] = await db.select({ revokedAt: schema.sessions.revokedAt }).from(schema.sessions);
      expect(row?.revokedAt).not.toBeNull();
    });

    it('выход без сессии отвечает 204: экран отказа зовёт его вслепую', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/logout',
        headers: { origin: APP_ORIGIN },
      });
      expect(response.statusCode).toBe(204);
    });

    it('bearer-сессия работает тем же кодом, что и cookie (ADR-0002)', async () => {
      await grantAccess('ivan@yandex.ru');
      await login();
      const [user] = await db.select({ id: schema.users.id }).from(schema.users);

      const sessions = app.get(SessionService);
      const issued = await sessions.create(user!.id, 'bearer');

      const response = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: { authorization: `Bearer ${issued.token}` },
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({ session: { kind: 'bearer' } });
    });

    it('небезопасный метод с cookie без Origin отклоняется (CSRF)', async () => {
      const ownerId = await grantAccess('ivan@yandex.ru', { owner: true });
      const cookie = await login();

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/access-entries/${ownerId}`,
        headers: withSession(cookie),
      });

      expect(response.statusCode).toBe(403);
      expect(response.json()).toMatchObject({ code: 'csrf_origin_mismatch' });
    });
  });

  describe('US-07: экран управления доступом', () => {
    /** Владелец трекера и его сессия. */
    async function loginAsOwner(): Promise<string> {
      await grantAccess('ivan@yandex.ru', { owner: true });
      return login();
    }

    it('не владелец не видит список: 403', async () => {
      await grantAccess('ivan@yandex.ru');
      const cookie = await login();

      const response = await app.inject({
        method: 'GET',
        url: '/api/access-entries',
        headers: withSession(cookie),
      });

      expect(response.statusCode).toBe(403);
      expect(response.json()).toMatchObject({ code: 'access_list_forbidden' });
    });

    it('без сессии список недоступен: 401', async () => {
      const response = await app.inject({ method: 'GET', url: '/api/access-entries' });
      expect(response.statusCode).toBe(401);
    });

    it('владелец видит список, свою запись и признак «входил»', async () => {
      const cookie = await loginAsOwner();
      await grantAccess('petr@yandex.ru', { source: 'manual' });

      const response = await app.inject({
        method: 'GET',
        url: '/api/access-entries',
        headers: withSession(cookie),
      });

      expect(response.statusCode).toBe(200);
      const body = response.json<{
        items: {
          email: string;
          isSelf: boolean;
          source: string;
          firstLoginAt: string | null;
          user: { displayName: string } | null;
        }[];
        total: number;
        nextCursor: string | null;
      }>();

      expect(body.total).toBe(2);
      const own = body.items.find((item) => item.email === 'ivan@yandex.ru');
      expect(own).toMatchObject({ isSelf: true, source: 'config' });
      expect(own?.user?.displayName).toBe('Иван Петров');
      expect(own?.firstLoginAt).not.toBeNull();

      const other = body.items.find((item) => item.email === 'petr@yandex.ru');
      expect(other).toMatchObject({ isSelf: false, source: 'manual', user: null });
    });

    it('список листается курсором и не повторяет записи', async () => {
      const cookie = await loginAsOwner();
      await grantAccess('a@example.com', { source: 'manual' });
      await grantAccess('b@example.com', { source: 'invitation' });

      const first = await app.inject({
        method: 'GET',
        url: '/api/access-entries?limit=2',
        headers: withSession(cookie),
      });
      expect(first.statusCode).toBe(200);
      const firstPage = first.json<{
        items: { email: string }[];
        nextCursor: string | null;
        total: number;
      }>();
      expect(firstPage.items).toHaveLength(2);
      expect(firstPage.total).toBe(3);
      expect(firstPage.nextCursor).not.toBeNull();

      const second = await app.inject({
        method: 'GET',
        url: `/api/access-entries?limit=2&cursor=${encodeURIComponent(String(firstPage.nextCursor))}`,
        headers: withSession(cookie),
      });
      expect(second.statusCode).toBe(200);
      const secondPage = second.json<{ items: { email: string }[]; nextCursor: string | null }>();
      expect(secondPage.items).toHaveLength(1);
      expect(secondPage.nextCursor).toBeNull();

      const emails = [...firstPage.items, ...secondPage.items].map((item) => item.email);
      expect(new Set(emails).size).toBe(3);
    });

    it('поиск по подстроке в адресе сужает список', async () => {
      const cookie = await loginAsOwner();
      await grantAccess('petr@yandex.ru', { source: 'manual' });

      const response = await app.inject({
        method: 'GET',
        url: '/api/access-entries?q=petr',
        headers: withSession(cookie),
      });

      expect(response.statusCode).toBe(200);
      const body = response.json<{ items: { email: string }[]; total: number }>();
      expect(body.items.map((item) => item.email)).toEqual(['petr@yandex.ru']);
      expect(body.total).toBe(1);
    });

    it('владелец добавляет адрес: источник manual, регистр не важен, дубликат — 409', async () => {
      const cookie = await loginAsOwner();
      const headers = { ...withSession(cookie), origin: APP_ORIGIN };

      const created = await app.inject({
        method: 'POST',
        url: '/api/access-entries',
        headers,
        payload: { email: 'Petr@Yandex.RU' },
      });
      expect(created.statusCode).toBe(201);
      expect(created.json()).toMatchObject({
        email: 'petr@yandex.ru',
        source: 'manual',
        isInstanceOwner: false,
        addedBy: { displayName: 'Иван Петров' },
      });

      const duplicate = await app.inject({
        method: 'POST',
        url: '/api/access-entries',
        headers,
        payload: { email: 'petr@YANDEX.ru' },
      });
      expect(duplicate.statusCode).toBe(409);
      expect(duplicate.json()).toMatchObject({ code: 'access_entry_exists' });
    });

    it('добавленный человек входит сразу, без перезапуска сервиса', async () => {
      const cookie = await loginAsOwner();
      await app.inject({
        method: 'POST',
        url: '/api/access-entries',
        headers: { ...withSession(cookie), origin: APP_ORIGIN },
        payload: { email: 'petr@yandex.ru' },
      });

      yandex.profile = {
        externalId: 'yandex-2000',
        displayName: 'Пётр Смирнов',
        email: 'petr@yandex.ru',
        avatarUrl: null,
      };
      const petrCookie = await login();

      const me = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: withSession(petrCookie),
      });
      expect(me.statusCode).toBe(200);
      expect(me.json()).toMatchObject({ email: 'petr@yandex.ru', canManageAccessList: false });
    });

    it('некорректный адрес не принимается', async () => {
      const cookie = await loginAsOwner();
      const response = await app.inject({
        method: 'POST',
        url: '/api/access-entries',
        headers: { ...withSession(cookie), origin: APP_ORIGIN },
        payload: { email: 'не-адрес' },
      });
      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({ code: 'invalid_email' });
    });

    it('свою запись удалить нельзя — 409', async () => {
      const cookie = await loginAsOwner();
      const [own] = await db
        .select({ id: schema.accessEntries.id })
        .from(schema.accessEntries)
        .where(sql`${schema.accessEntries.email} = 'ivan@yandex.ru'`);

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/access-entries/${own!.id}`,
        headers: { ...withSession(cookie), origin: APP_ORIGIN },
      });

      expect(response.statusCode).toBe(409);
      expect(response.json()).toMatchObject({ code: 'cannot_revoke_self' });
    });

    it('снять признак с последнего владельца нельзя — 409', async () => {
      const cookie = await loginAsOwner();
      const [own] = await db
        .select({ id: schema.accessEntries.id })
        .from(schema.accessEntries)
        .where(sql`${schema.accessEntries.email} = 'ivan@yandex.ru'`);

      const response = await app.inject({
        method: 'PATCH',
        url: `/api/access-entries/${own!.id}`,
        headers: { ...withSession(cookie), origin: APP_ORIGIN },
        payload: { isInstanceOwner: false },
      });

      expect(response.statusCode).toBe(409);
      expect(response.json()).toMatchObject({ code: 'last_instance_owner' });
    });

    it('признак владельца выдаётся и сразу открывает раздел новому владельцу', async () => {
      const ownerCookie = await loginAsOwner();
      const petrEntryId = await grantAccess('petr@yandex.ru', { source: 'manual' });

      yandex.profile = {
        externalId: 'yandex-2000',
        displayName: 'Пётр Смирнов',
        email: 'petr@yandex.ru',
        avatarUrl: null,
      };
      const petrCookie = await login();

      const before = await app.inject({
        method: 'GET',
        url: '/api/access-entries',
        headers: withSession(petrCookie),
      });
      expect(before.statusCode).toBe(403);

      const granted = await app.inject({
        method: 'PATCH',
        url: `/api/access-entries/${petrEntryId}`,
        headers: { ...withSession(ownerCookie), origin: APP_ORIGIN },
        payload: { isInstanceOwner: true },
      });
      expect(granted.statusCode).toBe(200);
      expect(granted.json()).toMatchObject({ isInstanceOwner: true });

      // Право читается на каждом запросе: перелогин не нужен.
      const after = await app.inject({
        method: 'GET',
        url: '/api/access-entries',
        headers: withSession(petrCookie),
      });
      expect(after.statusCode).toBe(200);

      const me = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: withSession(petrCookie),
      });
      expect(me.json()).toMatchObject({ canManageAccessList: true });
    });
  });

  describe('US-09: отзыв доступа', () => {
    it('удаление записи немедленно гасит все сессии человека', async () => {
      const ownerCookie = await (async () => {
        await grantAccess('ivan@yandex.ru', { owner: true });
        return login();
      })();

      const petrEntryId = await grantAccess('petr@yandex.ru', { source: 'manual' });
      yandex.profile = {
        externalId: 'yandex-2000',
        displayName: 'Пётр Смирнов',
        email: 'petr@yandex.ru',
        avatarUrl: null,
      };
      const petrFirst = await login();
      const petrSecond = await login();

      // Обе вкладки работают.
      for (const cookie of [petrFirst, petrSecond]) {
        const response = await app.inject({
          method: 'GET',
          url: '/api/me',
          headers: withSession(cookie),
        });
        expect(response.statusCode).toBe(200);
      }

      const revoked = await app.inject({
        method: 'DELETE',
        url: `/api/access-entries/${petrEntryId}`,
        headers: { ...withSession(ownerCookie), origin: APP_ORIGIN },
      });
      expect(revoked.statusCode).toBe(200);
      expect(revoked.json()).toMatchObject({ revokedSessions: 2 });

      // Обе вкладки получают 401 сразу же.
      for (const cookie of [petrFirst, petrSecond]) {
        const response = await app.inject({
          method: 'GET',
          url: '/api/me',
          headers: withSession(cookie),
        });
        expect(response.statusCode).toBe(401);
        expect(response.json()).toMatchObject({ code: 'session_expired' });
      }

      // Владелец продолжает работать.
      const owner = await app.inject({
        method: 'GET',
        url: '/api/me',
        headers: withSession(ownerCookie),
      });
      expect(owner.statusCode).toBe(200);
    });

    it('данные человека остаются, повторный вход приводит на экран отказа', async () => {
      await grantAccess('ivan@yandex.ru', { owner: true });
      const ownerCookie = await login();

      const petrEntryId = await grantAccess('petr@yandex.ru', { source: 'manual' });
      yandex.profile = {
        externalId: 'yandex-2000',
        displayName: 'Пётр Смирнов',
        email: 'petr@yandex.ru',
        avatarUrl: null,
      };
      await login();

      await app.inject({
        method: 'DELETE',
        url: `/api/access-entries/${petrEntryId}`,
        headers: { ...withSession(ownerCookie), origin: APP_ORIGIN },
      });

      // Учётная запись не удаляется (US-09).
      const users = await db.select({ email: schema.users.email }).from(schema.users);
      expect(users.map((row) => row.email)).toContain('petr@yandex.ru');

      const state = await startLogin();
      const response = await callback({ code: 'code-after-revoke', state });
      expect(new URL(String(response.headers.location)).pathname).toBe('/access-denied');
    });
  });

  describe('US-06: начальное наполнение списка доступа', () => {
    it('повторный запуск дубликатов не создаёт', async () => {
      const bootstrap = app.get(AccessBootstrapService);

      await db.insert(schema.accessEntries).values({
        email: 'anna@example.com',
        source: 'config',
        isInstanceOwner: true,
      });
      const inserted = await bootstrap.run();

      const rows = await db.select({ id: schema.accessEntries.id }).from(schema.accessEntries);
      // В окружении тестов переменная обычно пуста — тогда наполнение ничего не делает.
      expect(inserted).toBeGreaterThanOrEqual(0);
      expect(rows.length).toBeGreaterThanOrEqual(1);

      await bootstrap.run();
      const again = await db.select({ id: schema.accessEntries.id }).from(schema.accessEntries);
      expect(again).toHaveLength(rows.length);
    });
  });
});
