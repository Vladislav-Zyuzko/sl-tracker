import { randomUUID } from 'node:crypto';
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
 * Проекты, короткие имена в адресе, обложки и участники (US-10 … US-18).
 *
 * Всё настоящее: PostgreSQL, Redis и MinIO. Подделок здесь нет вовсе — обложка
 * действительно уезжает в хранилище, и тест проверяет, что прямая ссылка на объект
 * без подписи содержимое не отдаёт.
 *
 * Сессии выдаются напрямую через `SessionService`: вход через Яндекс ID проверяется
 * в своём наборе тестов, и повторять его на каждом проектном сценарии незачем.
 */

/** Минимальный «настоящий» PNG: подпись плюс наполнитель. Тип определяется по подписи. */
const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.alloc(512, 7),
]);

describe('Проекты, участники и обложки', () => {
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
    // Логическая база Redis у тестов своя, поэтому чистим её целиком: счётчики
    // ограничения частоты живут дольше прогона и упирались бы в 429.
    await redis.flushdb();
  });

  /** Сессия через bearer: небезопасные методы по cookie требуют ещё и проверки Origin. */
  async function signIn(displayName: string): Promise<{ id: string; headers: Headers }> {
    const user = await seedUser(db, displayName);
    const session = await sessions.create(user.id, 'bearer');
    return { id: user.id, headers: { authorization: `Bearer ${session.token}` } };
  }

  type Headers = Record<string, string>;

  function get(url: string, headers: Headers) {
    return app.inject({ method: 'GET', url, headers });
  }

  function post(url: string, headers: Headers, body?: object) {
    return app.inject({ method: 'POST', url, headers, payload: body });
  }

  function patch(url: string, headers: Headers, body: object) {
    return app.inject({ method: 'PATCH', url, headers, payload: body });
  }

  function put(url: string, headers: Headers, body: object) {
    return app.inject({ method: 'PUT', url, headers, payload: body });
  }

  function del(url: string, headers: Headers) {
    return app.inject({ method: 'DELETE', url, headers });
  }

  /** Тело multipart с одним файлом: `app.inject` формы сам не собирает. */
  function filePayload(content: Buffer, filename: string, contentType: string) {
    const boundary = `----sl${randomUUID().replace(/-/g, '')}`;
    const head = Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\n` +
        `Content-Type: ${contentType}\r\n\r\n`,
      'utf8',
    );
    const tail = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

    return {
      payload: Buffer.concat([head, content, tail]),
      contentType: `multipart/form-data; boundary=${boundary}`,
    };
  }

  function uploadCover(
    slug: string,
    headers: Headers,
    content: Buffer,
    filename = 'cover.png',
    type = 'image/png',
  ) {
    const form = filePayload(content, filename, type);
    return app.inject({
      method: 'PUT',
      url: `/api/projects/${slug}/cover`,
      headers: { ...headers, 'content-type': form.contentType },
      payload: form.payload,
    });
  }

  describe('US-11: создание проекта', () => {
    it('создаёт проект, выдаёт короткое имя из названия и делает создателя администратором', async () => {
      const admin = await signIn('Анна Иванова');

      const response = await post('/api/projects', admin.headers, {
        name: 'Сладкий Лимит 2026!',
        description: 'Мобильное приложение',
      });

      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        slug: 'sladkiy-limit-2026',
        name: 'Сладкий Лимит 2026!',
        description: 'Мобильное приложение',
        role: 'admin',
        memberCount: 1,
        coverUrl: null,
      });

      const members = await db.select().from(schema.projectMembers);
      expect(members).toHaveLength(1);
      expect(members[0]).toMatchObject({ userId: admin.id, role: 'admin' });
    });

    it('при совпадении короткого имени добавляет числовой суффикс', async () => {
      const first = await signIn('Первый');
      const second = await signIn('Второй');

      const a = await post('/api/projects', first.headers, { name: 'Сладкий лимит' });
      const b = await post('/api/projects', second.headers, { name: 'Сладкий лимит' });

      expect(a.json().slug).toBe('sladkiy-limit');
      expect(b.json().slug).toBe('sladkiy-limit-2');
    });

    it('название без допустимых символов даёт имя вида project-…', async () => {
      const admin = await signIn('Анна');

      const first = await post('/api/projects', admin.headers, { name: '🎉🎉🎉' });
      const second = await post('/api/projects', admin.headers, { name: '!!!' });

      expect(first.json().slug).toBe('project');
      expect(second.json().slug).toBe('project-2');
    });

    it('название из одних пробелов отклоняется', async () => {
      const admin = await signIn('Анна');
      const response = await post('/api/projects', admin.headers, { name: '   ' });

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_project_name');
    });

    it('без сессии проект не создаётся', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/projects',
        payload: { name: 'Тайный проект' },
      });
      expect(response.statusCode).toBe(401);
    });
  });

  describe('US-10: мои проекты', () => {
    it('показывает только проекты, где пользователь состоит', async () => {
      const anna = await signIn('Анна');
      const boris = await signIn('Борис');

      await post('/api/projects', anna.headers, { name: 'Аннин проект' });
      await post('/api/projects', boris.headers, { name: 'Борисов проект' });

      const list = await get('/api/projects', anna.headers);
      expect(list.statusCode).toBe(200);
      expect(list.json().total).toBe(1);
      expect(list.json().items.map((item: { name: string }) => item.name)).toEqual([
        'Аннин проект',
      ]);
    });

    it('отдаёт участников для группы аватаров и число участников', async () => {
      const anna = await signIn('Анна');
      const boris = await signIn('Борис');
      const created = await post('/api/projects', anna.headers, { name: 'Общий' });
      await addProjectMember(db, created.json().id, boris.id, 'member');

      const list = await get('/api/projects', anna.headers);
      const project = list.json().items[0];

      expect(project.memberCount).toBe(2);
      expect(project.members).toHaveLength(2);
      // Администраторы идут первыми (design/screens/project.md).
      expect(project.members[0].role).toBe('admin');
    });

    it('листает страницами и не теряет проекты', async () => {
      const anna = await signIn('Анна');
      for (const name of ['Альфа', 'Бета', 'Гамма']) {
        await post('/api/projects', anna.headers, { name });
      }

      const first = await get('/api/projects?limit=2', anna.headers);
      expect(first.json().items).toHaveLength(2);
      expect(first.json().total).toBe(3);

      const second = await get(
        `/api/projects?limit=2&cursor=${encodeURIComponent(first.json().nextCursor)}`,
        anna.headers,
      );
      expect(second.json().items).toHaveLength(1);
      expect(second.json().nextCursor).toBeNull();

      const names = [...first.json().items, ...second.json().items].map(
        (item: { name: string }) => item.name,
      );
      expect(names).toEqual(['Альфа', 'Бета', 'Гамма']);
    });

    it('испорченный курсор — 400, а не молчаливая первая страница', async () => {
      const anna = await signIn('Анна');
      const response = await get('/api/projects?cursor=%21%21%21', anna.headers);

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_cursor');
    });
  });

  describe('US-13, US-18: открытие проекта по адресу', () => {
    it('чужой проект отвечает 404 и не раскрывает ни названия, ни существования', async () => {
      const anna = await signIn('Анна');
      const stranger = await signIn('Посторонний');
      const created = await post('/api/projects', anna.headers, { name: 'Секретный' });

      const response = await get(`/api/projects/${created.json().slug}`, stranger.headers);

      expect(response.statusCode).toBe(404);
      expect(response.json().code).toBe('project_not_found');
      expect(JSON.stringify(response.json())).not.toContain('Секретный');
    });

    it('несуществующий адрес отвечает тем же 404, что и чужой проект', async () => {
      const stranger = await signIn('Посторонний');
      const response = await get('/api/projects/nikogo-net', stranger.headers);

      expect(response.statusCode).toBe(404);
      expect(response.json().code).toBe('project_not_found');
    });
  });

  describe('US-12: название, описание и права на изменение', () => {
    it('администратор меняет название, короткое имя при этом не меняется', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Сладкий лимит' });

      const updated = await patch(`/api/projects/sladkiy-limit`, admin.headers, {
        name: 'Кислый лимит',
        description: 'Новое описание',
      });

      expect(updated.statusCode).toBe(200);
      expect(updated.json()).toMatchObject({
        name: 'Кислый лимит',
        description: 'Новое описание',
        slug: 'sladkiy-limit',
      });

      // Ранее отправленная ссылка продолжает открывать проект.
      const byOldAddress = await get('/api/projects/sladkiy-limit', admin.headers);
      expect(byOldAddress.json().id).toBe(created.json().id);
    });

    it('участник и читатель получают 403, посторонний — 404', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const reader = await signIn('Вера');
      const stranger = await signIn('Посторонний');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');
      await addProjectMember(db, created.json().id, reader.id, 'reader');

      const slug = created.json().slug;
      expect(
        (await patch(`/api/projects/${slug}`, member.headers, { name: 'Моё' })).statusCode,
      ).toBe(403);
      expect(
        (await patch(`/api/projects/${slug}`, reader.headers, { name: 'Моё' })).statusCode,
      ).toBe(403);
      expect(
        (await patch(`/api/projects/${slug}`, stranger.headers, { name: 'Моё' })).statusCode,
      ).toBe(404);

      // Участник и читатель при этом проект видят.
      expect((await get(`/api/projects/${slug}`, reader.headers)).statusCode).toBe(200);
    });

    it('пустое описание убирается, а не сохраняется пустой строкой', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, {
        name: 'Проект',
        description: 'Было',
      });

      const updated = await patch(`/api/projects/${created.json().slug}`, admin.headers, {
        description: '   ',
      });
      expect(updated.json().description).toBeNull();
    });
  });

  describe('US-18: смена короткого имени', () => {
    it('меняет адрес, прежний продолжает открывать проект и отдаёт актуальное имя', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Сладкий лимит' });

      const changed = await put('/api/projects/sladkiy-limit/slug', admin.headers, {
        slug: 'sweet-limit',
      });
      expect(changed.statusCode).toBe(200);
      expect(changed.json().slug).toBe('sweet-limit');

      const byOld = await get('/api/projects/sladkiy-limit', admin.headers);
      expect(byOld.statusCode).toBe(200);
      expect(byOld.json().id).toBe(created.json().id);
      // Клиент заменяет адрес в строке браузера на актуальный.
      expect(byOld.json().slug).toBe('sweet-limit');
    });

    it('прежнее имя занято навсегда и другому проекту не достаётся', async () => {
      const anna = await signIn('Анна');
      const boris = await signIn('Борис');
      await post('/api/projects', anna.headers, { name: 'Сладкий лимит' });
      await put('/api/projects/sladkiy-limit/slug', anna.headers, { slug: 'sweet-limit' });

      const conflict = await put('/api/projects/sweet-limit/slug', anna.headers, {
        slug: 'sladkiy-limit',
      });
      expect(conflict.statusCode).toBe(409);

      const other = await post('/api/projects', boris.headers, { name: 'Сладкий лимит' });
      expect(other.json().slug).toBe('sladkiy-limit-2');
    });

    it('занятое чужим проектом имя — 409 без указания, чьё оно', async () => {
      const anna = await signIn('Анна');
      const boris = await signIn('Борис');
      await post('/api/projects', anna.headers, { name: 'Альфа' });
      const mine = await post('/api/projects', boris.headers, { name: 'Бета' });

      const response = await put(`/api/projects/${mine.json().slug}/slug`, boris.headers, {
        slug: 'alfa',
      });

      expect(response.statusCode).toBe(409);
      expect(response.json().code).toBe('slug_taken');
      expect(JSON.stringify(response.json())).not.toContain('Альфа');
    });

    it.each(['issues', 'invite', 'projects', 'profile', 'me', 'api', 'login', 'notifications'])(
      'системный адрес %s отклоняется',
      async (reserved) => {
        const admin = await signIn('Анна');
        const created = await post('/api/projects', admin.headers, { name: 'Проект' });

        const response = await put(`/api/projects/${created.json().slug}/slug`, admin.headers, {
          slug: reserved,
        });
        expect(response.statusCode).toBe(409);
        expect(response.json().code).toBe('reserved_slug');
      },
    );

    it.each([
      ['кириллица', 'сладкий'],
      ['пробел', 'sweet limit'],
      ['заглавные', 'Sweet'],
      ['дефис в конце', 'sweet-'],
    ])('недопустимый ввод (%s) — 400', async (_case, value) => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });

      const response = await put(`/api/projects/${created.json().slug}/slug`, admin.headers, {
        slug: value,
      });
      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('invalid_slug');
    });

    it('участнику менять адрес нельзя', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const response = await put(`/api/projects/${created.json().slug}/slug`, member.headers, {
        slug: 'moy-adres',
      });
      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('project_forbidden');
    });
  });

  describe('US-12: обложка проекта в MinIO', () => {
    it('загружает обложку и отдаёт её подписанной ссылкой; без подписи ссылка не работает', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });

      const uploaded = await uploadCover(created.json().slug, admin.headers, PNG);
      expect(uploaded.statusCode).toBe(200);

      const coverUrl: string = uploaded.json().coverUrl;
      expect(coverUrl).toContain('X-Amz-Signature');

      const signed = await fetch(coverUrl);
      expect(signed.status).toBe(200);
      expect(Buffer.from(await signed.arrayBuffer()).equals(PNG)).toBe(true);

      // Та же ссылка без подписи: бакет не публичный, содержимое не отдаётся.
      const withoutSignature = await fetch(coverUrl.split('?')[0]!);
      expect(withoutSignature.status).toBe(403);
      expect(await withoutSignature.text()).not.toContain('PNG');
    });

    it('имя объекта в хранилище генерирует сервер, а не имя файла пользователя', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });

      await uploadCover(created.json().slug, admin.headers, PNG, '../../etc/passwd.png');

      const [row] = await db
        .select({ key: schema.projects.coverObjectKey })
        .from(schema.projects)
        .where(eq(schema.projects.id, created.json().id));

      expect(row!.key).toMatch(
        new RegExp(`^projects/${created.json().id}/cover/[0-9a-f-]{36}\\.png$`),
      );
    });

    it('файл не того типа отклоняется, прежняя обложка остаётся на месте', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      const slug = created.json().slug;

      const first = await uploadCover(slug, admin.headers, PNG);
      const coverBefore = first.json().coverUrl;

      // Заявленный тип — картинка, содержимое — нет: решает содержимое.
      const response = await uploadCover(
        slug,
        admin.headers,
        Buffer.from('%PDF-1.7 совсем не картинка'),
        'cover.png',
        'image/png',
      );

      expect(response.statusCode).toBe(400);
      expect(response.json().code).toBe('cover_unsupported_type');

      const project = await get(`/api/projects/${slug}`, admin.headers);
      expect(project.json().coverUrl).not.toBeNull();
      expect(coverBefore).not.toBeNull();
    });

    it('файл больше 5 МБ отклоняется', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });

      const huge = Buffer.concat([PNG, Buffer.alloc(6 * 1024 * 1024, 1)]);
      const response = await uploadCover(created.json().slug, admin.headers, huge);

      expect(response.statusCode).toBe(413);
      expect(response.json().code).toBe('cover_too_large');
    });

    it('обложку можно удалить', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      const slug = created.json().slug;

      await uploadCover(slug, admin.headers, PNG);
      const removed = await del(`/api/projects/${slug}/cover`, admin.headers);

      expect(removed.statusCode).toBe(200);
      expect(removed.json().coverUrl).toBeNull();
    });

    it('участник обложку не меняет, посторонний её вообще не видит', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const stranger = await signIn('Посторонний');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      const slug = created.json().slug;
      await addProjectMember(db, created.json().id, member.id, 'member');
      await uploadCover(slug, admin.headers, PNG);

      expect((await uploadCover(slug, member.headers, PNG)).statusCode).toBe(403);
      expect((await del(`/api/projects/${slug}/cover`, member.headers)).statusCode).toBe(403);
      // Ссылку на обложку выдаёт только эндпоинт проекта, а он посторонним отвечает 404.
      expect((await get(`/api/projects/${slug}`, stranger.headers)).statusCode).toBe(404);
    });
  });

  describe('US-17: удаление проекта', () => {
    it('администратор удаляет проект, короткое имя остаётся занятым', async () => {
      const admin = await signIn('Анна');
      const created = await post('/api/projects', admin.headers, { name: 'Сладкий лимит' });

      const removed = await del('/api/projects/sladkiy-limit', admin.headers);
      expect(removed.statusCode).toBe(204);

      expect((await get('/api/projects/sladkiy-limit', admin.headers)).statusCode).toBe(404);
      expect((await get('/api/projects', admin.headers)).json().total).toBe(0);

      const again = await post('/api/projects', admin.headers, { name: 'Сладкий лимит' });
      expect(again.json().slug).toBe('sladkiy-limit-2');
      expect(created.json().id).not.toBe(again.json().id);
    });

    it('участник удалить проект не может', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const response = await del(`/api/projects/${created.json().slug}`, member.headers);
      expect(response.statusCode).toBe(403);
      expect((await get(`/api/projects/${created.json().slug}`, admin.headers)).statusCode).toBe(
        200,
      );
    });
  });

  describe('US-14 … US-16: участники и роли', () => {
    it('список участников виден читателю и помечает текущего пользователя', async () => {
      const admin = await signIn('Анна');
      const reader = await signIn('Вера');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, reader.id, 'reader');

      const response = await get(`/api/projects/${created.json().slug}/members`, reader.headers);

      expect(response.statusCode).toBe(200);
      expect(response.json().total).toBe(2);
      // Администраторы первыми.
      expect(response.json().items[0]).toMatchObject({ role: 'admin', isSelf: false });
      expect(response.json().items[1]).toMatchObject({ role: 'reader', isSelf: true });
    });

    it('посторонний список участников не получает', async () => {
      const admin = await signIn('Анна');
      const stranger = await signIn('Посторонний');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });

      const response = await get(`/api/projects/${created.json().slug}/members`, stranger.headers);
      expect(response.statusCode).toBe(404);
    });

    it('администратор меняет роль участника', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'reader');

      const response = await patch(
        `/api/projects/${created.json().slug}/members/${member.id}`,
        admin.headers,
        { role: 'admin' },
      );

      expect(response.statusCode).toBe(200);
      expect(response.json().role).toBe('admin');
    });

    it('последнего администратора нельзя разжаловать', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const response = await patch(
        `/api/projects/${created.json().slug}/members/${admin.id}`,
        admin.headers,
        { role: 'member' },
      );

      expect(response.statusCode).toBe(409);
      expect(response.json().code).toBe('last_project_admin');
    });

    it('администратор может понизить себя, если он не последний', async () => {
      const admin = await signIn('Анна');
      const second = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, second.id, 'admin');

      const response = await patch(
        `/api/projects/${created.json().slug}/members/${admin.id}`,
        admin.headers,
        { role: 'member' },
      );

      expect(response.statusCode).toBe(200);
      // Управление проектом действительно потеряно.
      expect(
        (await patch(`/api/projects/${created.json().slug}`, admin.headers, { name: 'Моё' }))
          .statusCode,
      ).toBe(403);
    });

    it('участник роли не меняет', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const response = await patch(
        `/api/projects/${created.json().slug}/members/${admin.id}`,
        member.headers,
        { role: 'reader' },
      );
      expect(response.statusCode).toBe(403);
    });

    it('исключение участника оставляет задачи, очищает исполнителя и пишет историю (D-31)', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      const projectId: string = created.json().id;
      await addProjectMember(db, projectId, member.id, 'member');

      const queue = await seedQueueInProject(db, projectId, 'DEV', admin.id);
      const issue = await seedIssue(db, {
        queueId: queue.queueId,
        queueKey: 'DEV',
        number: 1,
        title: 'Задача Бориса',
        statusId: queue.statusIds.open!,
        authorId: admin.id,
        assigneeId: member.id,
      });

      const response = await del(
        `/api/projects/${created.json().slug}/members/${member.id}`,
        admin.headers,
      );

      expect(response.statusCode).toBe(200);
      expect(response.json().unassignedIssues).toBe(1);

      const [after] = await db
        .select({ assigneeId: schema.issues.assigneeId, title: schema.issues.title })
        .from(schema.issues)
        .where(eq(schema.issues.id, issue.id));
      expect(after).toMatchObject({ assigneeId: null, title: 'Задача Бориса' });

      const history = await db
        .select()
        .from(schema.issueHistory)
        .where(eq(schema.issueHistory.issueId, issue.id));
      expect(history).toHaveLength(1);
      expect(history[0]).toMatchObject({
        kind: 'assignee_changed',
        // Исполнителя снял не человек, а следствие исключения.
        actorId: null,
        oldRefId: member.id,
        oldValue: 'Борис',
        newRefId: null,
      });

      // Доступ потерян немедленно.
      expect((await get(`/api/projects/${created.json().slug}`, member.headers)).statusCode).toBe(
        404,
      );
    });

    it('участник выходит из проекта сам', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const response = await del(
        `/api/projects/${created.json().slug}/members/${member.id}`,
        member.headers,
      );

      expect(response.statusCode).toBe(200);
      expect((await get('/api/projects', member.headers)).json().total).toBe(0);
    });

    it('последний администратор не может ни выйти, ни быть исключённым', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');

      const leaving = await del(
        `/api/projects/${created.json().slug}/members/${admin.id}`,
        admin.headers,
      );
      expect(leaving.statusCode).toBe(409);
      expect(leaving.json().code).toBe('last_project_admin');
    });

    it('участник не может исключить другого участника', async () => {
      const admin = await signIn('Анна');
      const member = await signIn('Борис');
      const reader = await signIn('Вера');
      const created = await post('/api/projects', admin.headers, { name: 'Проект' });
      await addProjectMember(db, created.json().id, member.id, 'member');
      await addProjectMember(db, created.json().id, reader.id, 'reader');

      const response = await del(
        `/api/projects/${created.json().slug}/members/${reader.id}`,
        member.headers,
      );
      expect(response.statusCode).toBe(403);
    });
  });

  describe('Сквозной идентификатор запроса', () => {
    it('каждый ответ несёт заголовок x-request-id', async () => {
      const anna = await signIn('Анна');
      const response = await get('/api/projects', anna.headers);

      expect(response.headers['x-request-id']).toBeDefined();
      expect(String(response.headers['x-request-id']).length).toBeGreaterThan(10);
    });

    it('присланный клиентом идентификатор возвращается тем же', async () => {
      const anna = await signIn('Анна');
      const response = await get('/api/projects', {
        ...anna.headers,
        'x-request-id': 'client-42',
      });

      expect(response.headers['x-request-id']).toBe('client-42');
    });

    it('мусорный идентификатор наружу не переносится', async () => {
      const anna = await signIn('Анна');
      const response = await get('/api/projects', {
        ...anna.headers,
        'x-request-id': 'плохой заголовок с пробелами',
      });

      expect(response.headers['x-request-id']).not.toBe('плохой заголовок с пробелами');
    });
  });

  describe('Хранилище коротких имён', () => {
    it('прежние короткие имена остаются в реестре и после удаления проекта', async () => {
      const admin = await signIn('Анна');
      await seedProject(db, { name: 'Ручной', slug: 'ruchnoy', adminId: admin.id });

      await put('/api/projects/ruchnoy/slug', admin.headers, { slug: 'ruchnoy-2' });
      await del('/api/projects/ruchnoy-2', admin.headers);

      const reserved = await db
        .select({ slug: schema.projectSlugs.slug, projectId: schema.projectSlugs.projectId })
        .from(schema.projectSlugs)
        .orderBy(sql`${schema.projectSlugs.slug}`);

      expect(reserved.map((row) => row.slug)).toEqual(['ruchnoy', 'ruchnoy-2']);
      // Проекта уже нет, но имена заняты и повторно не выдаются.
      expect(reserved.every((row) => row.projectId === null)).toBe(true);
    });
  });
});
