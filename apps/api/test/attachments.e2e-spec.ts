import { randomUUID } from 'node:crypto';
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
import { REDIS } from '../src/redis/index.js';
import { SessionService } from '../src/sessions/index.js';
import { addProjectMember, seedProject, seedUser, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Вложения к задачам (US-46). Всё настоящее: PostgreSQL и MinIO, подделок нет —
 * проверяется в том числе то, что прямая ссылка на файл без подписи ничего не отдаёт.
 */
describe('Вложения', () => {
  let app: NestFastifyApplication;
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  let redis: Redis;
  let sessions: SessionService;

  const PNG = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    Buffer.from('содержимое картинки', 'utf8'),
  ]);
  const PDF = Buffer.from('%PDF-1.7 отчёт за февраль', 'utf8');

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
    headers: Headers;
  }

  async function signIn(displayName: string): Promise<Actor> {
    const user = await seedUser(db, displayName);
    const session = await sessions.create(user.id, 'bearer');
    return { id: user.id, headers: { authorization: `Bearer ${session.token}` } };
  }

  const get = (url: string, headers: Headers) => app.inject({ method: 'GET', url, headers });
  const post = (url: string, headers: Headers, body?: object) =>
    app.inject({ method: 'POST', url, headers, payload: body });
  const del = (url: string, headers: Headers) => app.inject({ method: 'DELETE', url, headers });

  /** Тело multipart с одним файлом: `app.inject` формы сам не собирает. */
  function upload(
    issueKey: string,
    headers: Headers,
    content: Buffer,
    filename = 'screenshot.png',
    contentType = 'image/png',
  ) {
    const boundary = `----sl${randomUUID().replace(/-/g, '')}`;
    const head = Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\n` +
        `Content-Type: ${contentType}\r\n\r\n`,
      'utf8',
    );
    const tail = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');

    return app.inject({
      method: 'POST',
      url: `/api/issues/${issueKey}/attachments`,
      headers: { ...headers, 'content-type': `multipart/form-data; boundary=${boundary}` },
      payload: Buffer.concat([head, content, tail]),
    });
  }

  interface Workspace {
    admin: Actor;
    member: Actor;
    other: Actor;
    reader: Actor;
    outsider: Actor;
    issueKey: string;
    issueId: string;
  }

  async function seedWorkspace(): Promise<Workspace> {
    const admin = await signIn('Анна Админова');
    const member = await signIn('Борис Участников');
    const other = await signIn('Дарья Участникова');
    const reader = await signIn('Вера Читателева');
    const outsider = await signIn('Гриша Посторонний');

    const project = await seedProject(db, {
      name: 'Сладкий Лимит',
      slug: 'sladkiy-limit',
      adminId: admin.id,
    });
    await addProjectMember(db, project.id, member.id, 'member');
    await addProjectMember(db, project.id, other.id, 'member');
    await addProjectMember(db, project.id, reader.id, 'reader');

    await post('/api/projects/sladkiy-limit/queues', admin.headers, {
      key: 'DEV',
      name: 'Разработка',
    });
    const issue = await post('/api/queues/DEV/issues', admin.headers, { title: 'Задача' });

    return {
      admin,
      member,
      other,
      reader,
      outsider,
      issueKey: issue.json().key,
      issueId: issue.json().id ?? '',
    };
  }

  describe('US-46: загрузка', () => {
    it('участник прикладывает файл; содержимое отдаётся только по подписанной ссылке', async () => {
      const space = await seedWorkspace();

      const response = await upload(space.issueKey, space.member.headers, PNG);

      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        fileName: 'screenshot.png',
        contentType: 'image/png',
        sizeBytes: PNG.byteLength,
        isImage: true,
        uploadedBy: { id: space.member.id },
        canDelete: true,
      });

      const url: string = response.json().url;
      expect(url).toContain('X-Amz-Signature');

      const signed = await fetch(url);
      expect(signed.status).toBe(200);
      expect(Buffer.from(await signed.arrayBuffer()).equals(PNG)).toBe(true);

      // Та же ссылка без подписи: бакет не публичный, содержимое не отдаётся.
      const withoutSignature = await fetch(url.split('?')[0]!);
      expect(withoutSignature.status).toBe(403);
      expect(await withoutSignature.text()).not.toContain('содержимое картинки');
    });

    it('прямая ссылка на файл не отдаёт содержимое человеку без доступа к проекту', async () => {
      const space = await seedWorkspace();
      const uploaded = await upload(space.issueKey, space.member.headers, PNG);
      const objectUrl: string = uploaded.json().url.split('?')[0];

      // Посторонний не получит ни подписанной ссылки (задачи для него нет)…
      const list = await get(`/api/issues/${space.issueKey}/attachments`, space.outsider.headers);
      expect(list.statusCode).toBe(404);
      expect(list.body).not.toContain('screenshot.png');

      // …ни содержимого по прямой ссылке на объект, даже зная её.
      const direct = await fetch(objectUrl);
      expect(direct.status).toBe(403);
      const anonymous = await fetch(objectUrl, { headers: { cookie: 'sl_session=nonsense' } });
      expect(anonymous.status).toBe(403);
    });

    it('тип определяется по содержимому, а не по имени и заголовку', async () => {
      const space = await seedWorkspace();

      // Файл назван картинкой и заявлен картинкой, внутри — PDF.
      const response = await upload(
        space.issueKey,
        space.member.headers,
        PDF,
        'картинка.png',
        'image/png',
      );

      expect(response.statusCode).toBe(201);
      expect(response.json().contentType).toBe('application/pdf');
      expect(response.json().isImage).toBe(false);
      // Имя файла сохраняется как есть — оно только для показа и скачивания.
      expect(response.json().fileName).toBe('картинка.png');
    });

    it('имя объекта в хранилище генерирует сервер, а не имя файла пользователя', async () => {
      const space = await seedWorkspace();

      const response = await upload(
        space.issueKey,
        space.member.headers,
        PNG,
        '../../etc/passwd.png',
      );

      const [row] = await db
        .select({ objectKey: schema.attachments.objectKey, fileName: schema.attachments.fileName })
        .from(schema.attachments)
        .where(eq(schema.attachments.id, response.json().id));

      expect(row!.objectKey).toMatch(/^issues\/[0-9a-f-]{36}\/attachments\/[0-9a-f-]{36}\.png$/);
      expect(row!.fileName).toBe('passwd.png');
    });

    it('файл больше 25 МБ отклоняется и в списке не появляется', async () => {
      const space = await seedWorkspace();
      const huge = Buffer.concat([PNG, Buffer.alloc(26 * 1024 * 1024, 1)]);

      const response = await upload(space.issueKey, space.member.headers, huge, 'дамп.bin');

      expect(response.statusCode).toBe(413);
      expect(response.json().code).toBe('attachment_too_large');

      const list = await get(`/api/issues/${space.issueKey}/attachments`, space.member.headers);
      expect(list.json().items).toEqual([]);
    });

    it('читатель файлы не прикладывает: 403', async () => {
      const space = await seedWorkspace();

      const response = await upload(space.issueKey, space.reader.headers, PNG);

      expect(response.statusCode).toBe(403);
      expect(response.json().code).toBe('attachment_forbidden');
      expect(await db.select().from(schema.attachments)).toHaveLength(0);
    });

    it('посторонний получает 404 и ничего не узнаёт о задаче', async () => {
      const space = await seedWorkspace();

      const response = await upload(space.issueKey, space.outsider.headers, PNG);

      expect(response.statusCode).toBe(404);
    });

    it('добавление вложения попадает в историю задачи', async () => {
      const space = await seedWorkspace();
      await upload(space.issueKey, space.member.headers, PNG, 'отчёт.png');

      const history = await get(`/api/issues/${space.issueKey}/history`, space.member.headers);
      const changes = (history.json().items as { changes: { kind: string; newValue: string }[] }[])
        .flatMap((group) => group.changes)
        .filter((change) => change.kind === 'attachment_added');

      expect(changes).toHaveLength(1);
      expect(changes[0]!.newValue).toBe('отчёт.png');
    });
  });

  describe('US-46: список и скачивание', () => {
    it('список виден всем участникам, включая читателя, со ссылкой на скачивание', async () => {
      const space = await seedWorkspace();
      await upload(space.issueKey, space.member.headers, PDF, 'отчёт.pdf', 'application/pdf');

      const response = await get(`/api/issues/${space.issueKey}/attachments`, space.reader.headers);

      expect(response.statusCode).toBe(200);
      expect(response.json().total).toBe(1);
      expect(response.json().canUpload).toBe(false);
      const item = response.json().items[0];
      expect(item.downloadUrl).toContain('response-content-disposition');

      const downloaded = await fetch(item.downloadUrl);
      expect(downloaded.status).toBe(200);
      expect(downloaded.headers.get('content-disposition')).toContain('attachment');
    });
  });

  describe('US-46: удаление', () => {
    it('приложивший удаляет своё вложение, и файл исчезает из хранилища', async () => {
      const space = await seedWorkspace();
      const uploaded = await upload(space.issueKey, space.member.headers, PNG);
      const url: string = uploaded.json().url;

      const response = await del(
        `/api/issues/${space.issueKey}/attachments/${uploaded.json().id}`,
        space.member.headers,
      );

      expect(response.statusCode).toBe(204);
      expect(await db.select().from(schema.attachments)).toHaveLength(0);

      const gone = await fetch(url);
      expect(gone.status).toBe(404);
    });

    it('участник чужое вложение не удаляет, администратор — удаляет', async () => {
      const space = await seedWorkspace();
      const uploaded = await upload(space.issueKey, space.member.headers, PNG);

      const byOther = await del(
        `/api/issues/${space.issueKey}/attachments/${uploaded.json().id}`,
        space.other.headers,
      );
      expect(byOther.statusCode).toBe(403);
      expect(byOther.json().code).toBe('attachment_forbidden');

      const byAdmin = await del(
        `/api/issues/${space.issueKey}/attachments/${uploaded.json().id}`,
        space.admin.headers,
      );
      expect(byAdmin.statusCode).toBe(204);
    });

    it('в списке видно, кому удаление доступно', async () => {
      const space = await seedWorkspace();
      await upload(space.issueKey, space.member.headers, PNG);

      const forOther = await get(`/api/issues/${space.issueKey}/attachments`, space.other.headers);
      const forAdmin = await get(`/api/issues/${space.issueKey}/attachments`, space.admin.headers);
      const forReader = await get(
        `/api/issues/${space.issueKey}/attachments`,
        space.reader.headers,
      );

      expect(forOther.json().items[0].canDelete).toBe(false);
      expect(forAdmin.json().items[0].canDelete).toBe(true);
      expect(forReader.json().items[0].canDelete).toBe(false);
    });

    it('удаление попадает в историю задачи', async () => {
      const space = await seedWorkspace();
      const uploaded = await upload(space.issueKey, space.member.headers, PNG, 'схема.png');
      await del(
        `/api/issues/${space.issueKey}/attachments/${uploaded.json().id}`,
        space.member.headers,
      );

      const history = await get(`/api/issues/${space.issueKey}/history`, space.member.headers);
      const removed = (history.json().items as { changes: { kind: string; oldValue: string }[] }[])
        .flatMap((group) => group.changes)
        .filter((change) => change.kind === 'attachment_removed');

      expect(removed).toHaveLength(1);
      expect(removed[0]!.oldValue).toBe('схема.png');
    });
  });
});
