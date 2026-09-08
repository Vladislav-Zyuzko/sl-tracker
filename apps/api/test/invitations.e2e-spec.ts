import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
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
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Приглашения в проект (US-20 … US-22) и их связь со списком доступа (ADR-0006, п. 3).
 *
 * Ключевая проверка здесь — приём приглашения добавляет запись в список доступа
 * с источником `invitation`: без неё человек, вошедший по ссылке, при следующем
 * входе в трекер не попадёт.
 */
describe('Приглашения в проект', () => {
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

  interface Person {
    id: string;
    email: string;
    headers: Headers;
  }

  async function signIn(displayName: string, email?: string): Promise<Person> {
    const user = await seedUser(db, displayName, email);
    const session = await sessions.create(user.id, 'bearer');
    return {
      id: user.id,
      email: user.email,
      headers: { authorization: `Bearer ${session.token}` },
    };
  }

  function get(url: string, headers: Headers) {
    return app.inject({ method: 'GET', url, headers });
  }

  function post(url: string, headers: Headers, body?: object) {
    return app.inject({ method: 'POST', url, headers, payload: body });
  }

  /** Проект с администратором. Приглашения выдаёт только он. */
  async function projectWithAdmin(): Promise<{ admin: Person; slug: string; projectId: string }> {
    const admin = await signIn('Анна Иванова');
    const project = await seedProject(db, {
      name: 'Сладкий лимит',
      slug: 'sladkiy-limit',
      adminId: admin.id,
    });
    return { admin, slug: project.slug, projectId: project.id };
  }

  async function createInvitation(
    slug: string,
    headers: Headers,
    body: { role: 'member' | 'reader'; expiresInDays?: number } = { role: 'member' },
  ) {
    const response = await post(`/api/projects/${slug}/invitations`, headers, body);
    expect(response.statusCode).toBe(201);
    const invitation: { id: string; url: string; role: string; state: string } = response.json();
    return invitation;
  }

  /** Токен из полной ссылки: наружу отдаётся именно ссылка, а не голый токен. */
  function tokenOf(invitation: { url: string }): string {
    return invitation.url.slice(invitation.url.lastIndexOf('/') + 1);
  }

  describe('US-20: создание ссылки', () => {
    it('администратор создаёт ссылку с ролью и сроком, ссылка сразу готова к копированию', async () => {
      const { admin, slug } = await projectWithAdmin();

      const invitation = await createInvitation(slug, admin.headers, {
        role: 'reader',
        expiresInDays: 30,
      });

      expect(invitation).toMatchObject({ role: 'reader', state: 'active' });
      expect(invitation.url).toContain('/invite/');
      expect(tokenOf(invitation).length).toBeGreaterThan(20);
    });

    it('срок по умолчанию — 7 дней', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'member' });

      const [row] = await db
        .select({
          expiresAt: schema.invitations.expiresAt,
          createdAt: schema.invitations.createdAt,
        })
        .from(schema.invitations)
        .where(eq(schema.invitations.id, invitation.id));

      const days = (row!.expiresAt.getTime() - row!.createdAt.getTime()) / (24 * 60 * 60 * 1000);
      expect(Math.round(days)).toBe(7);
    });

    it('роль администратора через приглашение выдать нельзя (D-05)', async () => {
      const { admin, slug } = await projectWithAdmin();

      const response = await post(`/api/projects/${slug}/invitations`, admin.headers, {
        role: 'admin',
      });
      expect(response.statusCode).toBe(400);
    });

    it('бессрочных приглашений нет: произвольный срок отклоняется', async () => {
      const { admin, slug } = await projectWithAdmin();

      const response = await post(`/api/projects/${slug}/invitations`, admin.headers, {
        role: 'member',
        expiresInDays: 3650,
      });
      expect(response.statusCode).toBe(400);
    });

    it('участник и читатель приглашений не создают и не видят, посторонний получает 404', async () => {
      const { admin, slug, projectId } = await projectWithAdmin();
      const member = await signIn('Борис');
      const reader = await signIn('Вера');
      const stranger = await signIn('Посторонний');
      await addProjectMember(db, projectId, member.id, 'member');
      await addProjectMember(db, projectId, reader.id, 'reader');
      await createInvitation(slug, admin.headers);

      expect(
        (await post(`/api/projects/${slug}/invitations`, member.headers, { role: 'member' }))
          .statusCode,
      ).toBe(403);
      expect((await get(`/api/projects/${slug}/invitations`, reader.headers)).statusCode).toBe(403);
      expect((await get(`/api/projects/${slug}/invitations`, stranger.headers)).statusCode).toBe(
        404,
      );
    });
  });

  describe('US-21: вступление по ссылке', () => {
    it('человек вступает в проект и попадает в список доступа с источником invitation', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'member' });
      const guest = await signIn('Гость', 'Guest@Yandex.RU');

      const preview = await get(`/api/invitations/${tokenOf(invitation)}`, guest.headers);
      expect(preview.statusCode).toBe(200);
      expect(preview.json()).toMatchObject({
        projectName: 'Сладкий лимит',
        projectSlug: slug,
        role: 'member',
        alreadyMember: false,
      });

      const accepted = await post(`/api/invitations/${tokenOf(invitation)}/accept`, guest.headers);
      expect(accepted.statusCode).toBe(200);
      expect(accepted.json()).toEqual({
        projectSlug: slug,
        role: 'member',
        alreadyMember: false,
      });

      // Проект стал доступен.
      expect((await get(`/api/projects/${slug}`, guest.headers)).json().role).toBe('member');

      // И появилась запись списка доступа — иначе следующий вход не состоится.
      const entries = await db
        .select({ email: schema.accessEntries.email, source: schema.accessEntries.source })
        .from(schema.accessEntries);
      expect(entries).toEqual([{ email: 'guest@yandex.ru', source: 'invitation' }]);
    });

    it('экран подтверждения не раскрывает содержимое проекта', async () => {
      const { admin, slug, projectId } = await projectWithAdmin();
      await addProjectMember(db, projectId, (await signIn('Секретный участник')).id, 'member');
      const invitation = await createInvitation(slug, admin.headers, { role: 'reader' });
      const guest = await signIn('Гость');

      const preview = await get(`/api/invitations/${tokenOf(invitation)}`, guest.headers);

      expect(Object.keys(preview.json()).sort()).toEqual([
        'alreadyMember',
        'coverUrl',
        'projectName',
        'projectSlug',
        'role',
      ]);
      expect(JSON.stringify(preview.json())).not.toContain('Секретный участник');
      expect(JSON.stringify(preview.json())).not.toContain('Анна');
    });

    it('одной ссылкой пользуются несколько человек', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'member' });
      const first = await signIn('Первый');
      const second = await signIn('Второй');

      expect(
        (await post(`/api/invitations/${tokenOf(invitation)}/accept`, first.headers)).statusCode,
      ).toBe(200);
      expect(
        (await post(`/api/invitations/${tokenOf(invitation)}/accept`, second.headers)).statusCode,
      ).toBe(200);

      const list = await get(`/api/projects/${slug}/invitations`, admin.headers);
      expect(list.json().items[0].acceptedCount).toBe(2);
    });

    it('уже состоящий в проекте не теряет роль и не понижается', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'reader' });

      const preview = await get(`/api/invitations/${tokenOf(invitation)}`, admin.headers);
      expect(preview.json()).toMatchObject({ alreadyMember: true, role: 'admin' });

      const accepted = await post(`/api/invitations/${tokenOf(invitation)}/accept`, admin.headers);
      expect(accepted.json()).toEqual({
        projectSlug: slug,
        role: 'admin',
        alreadyMember: true,
      });

      expect((await get(`/api/projects/${slug}`, admin.headers)).json().role).toBe('admin');
    });

    it('неизвестный токен — 404 и ни слова о проекте', async () => {
      const guest = await signIn('Гость');

      const preview = await get('/api/invitations/neizvestnyy-token', guest.headers);
      expect(preview.statusCode).toBe(404);
      expect(preview.json().code).toBe('invitation_not_found');

      const accept = await post('/api/invitations/neizvestnyy-token/accept', guest.headers);
      expect(accept.statusCode).toBe(404);
    });

    it('истёкшая ссылка — 410, членство не выдаётся', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'member' });
      const guest = await signIn('Гость');

      await db
        .update(schema.invitations)
        .set({ expiresAt: new Date(Date.now() - 60_000) })
        .where(eq(schema.invitations.id, invitation.id));

      const preview = await get(`/api/invitations/${tokenOf(invitation)}`, guest.headers);
      expect(preview.statusCode).toBe(410);
      expect(preview.json().code).toBe('invitation_inactive');

      const accept = await post(`/api/invitations/${tokenOf(invitation)}/accept`, guest.headers);
      expect(accept.statusCode).toBe(410);

      expect((await get(`/api/projects/${slug}`, guest.headers)).statusCode).toBe(404);
      expect(await db.select().from(schema.accessEntries)).toHaveLength(0);
    });

    it('без сессии приглашение не смотрится и не принимается', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers);

      const anonymous = await app.inject({
        method: 'GET',
        url: `/api/invitations/${tokenOf(invitation)}`,
      });
      expect(anonymous.statusCode).toBe(401);
    });
  });

  describe('US-22: просмотр и отзыв', () => {
    it('список показывает состояние, срок, автора и число вступивших', async () => {
      const { admin, slug } = await projectWithAdmin();
      await createInvitation(slug, admin.headers, { role: 'member', expiresInDays: 1 });

      const list = await get(`/api/projects/${slug}/invitations`, admin.headers);

      expect(list.statusCode).toBe(200);
      expect(list.json().total).toBe(1);
      expect(list.json().items[0]).toMatchObject({
        role: 'member',
        state: 'active',
        acceptedCount: 0,
        createdBy: { id: admin.id, displayName: 'Анна Иванова' },
      });
    });

    it('отозванная ссылка перестаёт работать, а вступившие остаются участниками', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers, { role: 'member' });
      const early = await signIn('Ранний');
      await post(`/api/invitations/${tokenOf(invitation)}/accept`, early.headers);

      const revoked = await post(
        `/api/projects/${slug}/invitations/${invitation.id}/revoke`,
        admin.headers,
      );
      expect(revoked.statusCode).toBe(200);
      expect(revoked.json()).toMatchObject({ state: 'revoked', url: null });

      const late = await signIn('Поздний');
      const accept = await post(`/api/invitations/${tokenOf(invitation)}/accept`, late.headers);
      expect(accept.statusCode).toBe(410);

      // Ранее вступивший остался участником.
      expect((await get(`/api/projects/${slug}`, early.headers)).statusCode).toBe(200);
    });

    it('отозвать может другой администратор проекта', async () => {
      const { admin, slug, projectId } = await projectWithAdmin();
      const second = await signIn('Второй администратор');
      await addProjectMember(db, projectId, second.id, 'admin');
      const invitation = await createInvitation(slug, admin.headers);

      const response = await post(
        `/api/projects/${slug}/invitations/${invitation.id}/revoke`,
        second.headers,
      );
      expect(response.statusCode).toBe(200);
      expect(response.json().state).toBe('revoked');
    });

    it('отозванное и истёкшее остаются в списке, но копировать у них нечего', async () => {
      const { admin, slug } = await projectWithAdmin();
      const revoked = await createInvitation(slug, admin.headers, { role: 'member' });
      const expired = await createInvitation(slug, admin.headers, { role: 'reader' });

      await post(`/api/projects/${slug}/invitations/${revoked.id}/revoke`, admin.headers);
      await db
        .update(schema.invitations)
        .set({ expiresAt: new Date(Date.now() - 60_000) })
        .where(eq(schema.invitations.id, expired.id));

      const list = await get(`/api/projects/${slug}/invitations`, admin.headers);
      const states = list
        .json()
        .items.map((item: { state: string; url: string | null }) => [item.state, item.url]);

      expect(list.json().total).toBe(2);
      expect(states).toContainEqual(['revoked', null]);
      expect(states).toContainEqual(['expired', null]);
    });

    it('приглашение чужого проекта по идентификатору не отзывается', async () => {
      const { admin, slug } = await projectWithAdmin();
      const invitation = await createInvitation(slug, admin.headers);

      const outsider = await signIn('Чужой администратор');
      const other = await seedProject(db, {
        name: 'Чужой проект',
        slug: 'chuzhoy',
        adminId: outsider.id,
      });
      expect(other.slug).toBe('chuzhoy');

      const response = await post(
        `/api/projects/chuzhoy/invitations/${invitation.id}/revoke`,
        outsider.headers,
      );
      expect(response.statusCode).toBe(404);
      expect(response.json().code).toBe('invitation_not_found');

      const [row] = await db
        .select({ revokedAt: schema.invitations.revokedAt })
        .from(schema.invitations)
        .where(sql`${schema.invitations.id} = ${invitation.id}::uuid`);
      expect(row!.revokedAt).toBeNull();
    });
  });
});
