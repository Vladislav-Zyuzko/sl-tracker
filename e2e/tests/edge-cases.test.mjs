import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { createProject, createQueue, inviteAndAccept, signIn } from '../lib/actors.mjs';

after(async () => {
  await closeDb();
});

/** Пределы полей — из `docs/api/openapi.json` и `apps/api/src/issues/issue-fields.ts`. */
const LIMITS = {
  issueTitle: 255,
  issueDescription: 100_000,
  commentBody: 10_000,
  projectName: 100,
  linkUrl: 2048,
  linkTitle: 100,
};

/** Строки, которые ломают то, что собрано конкатенацией, а не параметрами. */
const NASTY_STRINGS = {
  'кавычка и точка с запятой': `'; drop table issues; --`,
  'тег script': '<script>alert("xss")</script>',
  'закрывающий тег и HTML': '</div><img src=x onerror=alert(1)>',
  'подстановка шаблона': '${process.env.SESSION_SECRET}',
  'подстановка SQL-параметра': '$1 $2 %s %d',
  'обратный слеш и кавычки': 'C:\\path\\"quoted"\\\'single\'',
  'символ процента и подчёркивание': '100% _like_ %like%',
  'перевод строки и возврат каретки': 'первая\nвторая\r\nтретья',
  'юникод-эмодзи': 'Готово 🚀 ✅ 👨‍👩‍👧‍👦',
  'RTL-текст': 'مرحبا بالعالم שלום עולם',
  'комбинирующие диакритики': 'е\u0301е\u0308а\u030A',
  'китайский и японский': '任务已完成 タスク完了',
  'математические символы': '∑ ∫ ≠ ≤ ∞ √2',
  'нулевой ширины и BiDi-управляющие': 'a\u200Bb\u202Ec\u2066d',
};

async function scene(name = 'Проект граничных случаев') {
  const admin = await signIn({ displayName: 'Испытатель границ' });
  const project = await createProject(admin, name);
  const queue = await createQueue(admin, project.slug);
  const statuses = await admin.api.get(`/queues/${queue.key}/statuses`).then((r) => r.expect(200));
  return { admin, project, queue, statuses: statuses.items };
}

test('границы длины полей: последний допустимый символ проходит, следующий — нет', async (t) => {
  const { admin, queue } = await scene();

  await t.test(`название задачи ровно ${LIMITS.issueTitle} символов принимается`, async () => {
    const title = 'я'.repeat(LIMITS.issueTitle);
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title })
      .then((r) => r.expect(201));
    assert.equal(issue.title.length, LIMITS.issueTitle, 'название не обрезано молча');
  });

  await t.test(`название на ${LIMITS.issueTitle + 1} символ отклоняется`, async () => {
    const response = await admin.api.post(`/queues/${queue.key}/issues`, {
      title: 'я'.repeat(LIMITS.issueTitle + 1),
    });
    assert.equal(response.status, 400);
  });

  await t.test('пустое название и название из пробелов отклоняются', async () => {
    for (const title of ['', '   ', '\n\t ', '\u00A0']) {
      const response = await admin.api.post(`/queues/${queue.key}/issues`, { title });
      assert.equal(response.status, 400, `название ${JSON.stringify(title)} должно отклоняться`);
    }
  });

  await t.test('название с пробелами по краям обрезается, а не отклоняется', async () => {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: '   Задача с пробелами   ' })
      .then((r) => r.expect(201));
    assert.equal(issue.title, 'Задача с пробелами');
  });

  await t.test(`комментарий ровно ${LIMITS.commentBody} символов принимается`, async () => {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Задача для длинного комментария' })
      .then((r) => r.expect(201));

    const body = 'т'.repeat(LIMITS.commentBody);
    const comment = await admin.api
      .post(`/issues/${issue.key}/comments`, { body })
      .then((r) => r.expect(201));
    assert.equal(comment.body.length, LIMITS.commentBody);

    const tooLong = await admin.api.post(`/issues/${issue.key}/comments`, {
      body: 'т'.repeat(LIMITS.commentBody + 1),
    });
    assert.equal(tooLong.status, 400);
  });

  await t.test('комментарий на 50 КБ отклоняется, а не роняет сервер', async () => {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Задача для очень длинного комментария' })
      .then((r) => r.expect(201));

    const response = await admin.api.post(`/issues/${issue.key}/comments`, {
      body: 'x'.repeat(50 * 1024),
    });
    assert.equal(response.status, 400, `получено ${response.status}: ${JSON.stringify(response.body)}`);
  });

  await t.test(`описание задачи в ${LIMITS.issueDescription} символов принимается`, async () => {
    const description = 'о'.repeat(LIMITS.issueDescription);
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Задача с огромным описанием', description })
      .then((r) => r.expect(201));
    assert.equal(issue.description.length, LIMITS.issueDescription);

    const readBack = await admin.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.equal(readBack.description.length, LIMITS.issueDescription, 'описание читается целиком');
  });

  await t.test('описание сверх предела отклоняется', async () => {
    const response = await admin.api.post(`/queues/${queue.key}/issues`, {
      title: 'Слишком длинное описание',
      description: 'о'.repeat(LIMITS.issueDescription + 1),
    });
    assert.equal(response.status, 400);
  });
});

test('опасные на вид строки сохраняются как текст и ничего не ломают', async (t) => {
  const { admin, queue } = await scene('Проект опасных строк');
  const created = [];

  for (const [name, value] of Object.entries(NASTY_STRINGS)) {
    await t.test(`название задачи: ${name}`, async () => {
      const response = await admin.api.post(`/queues/${queue.key}/issues`, {
        title: `Задача ${value}`,
        description: `Описание ${value}`,
      });

      assert.ok(
        [201, 400].includes(response.status),
        `ожидался 201 или осмысленный 400, получено ${response.status}: ` +
          JSON.stringify(response.body),
      );

      if (response.status === 201) {
        created.push({ name, value, key: response.body.key });
        const readBack = await admin.api
          .get(`/issues/${response.body.key}`)
          .then((r) => r.expect(200));
        assert.equal(
          readBack.title,
          response.body.title,
          'при повторном чтении строка не изменилась',
        );
      }
    });
  }

  await t.test('после всех опасных строк база жива и список задач читается', async () => {
    const list = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 100 } })
      .then((r) => r.expect(200));
    assert.equal(list.total, created.length, 'все сохранённые задачи на месте');
  });

  await t.test('поиск по опасной строке не ломает запрос', async () => {
    for (const value of ["'; drop table issues; --", '100%', '_like_', '\\', '<script>']) {
      const response = await admin.api.get('/issues/my-active', { query: { q: value } });
      assert.equal(response.status, 200, `поиск по ${JSON.stringify(value)} должен отвечать 200`);
    }
  });

  await t.test('комментарий с опасной строкой сохраняется дословно', async () => {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Задача для опасного комментария' })
      .then((r) => r.expect(201));

    const body = `Смотри: ${NASTY_STRINGS['тег script']} и ${NASTY_STRINGS['кавычка и точка с запятой']}`;
    const comment = await admin.api
      .post(`/issues/${issue.key}/comments`, { body })
      .then((r) => r.expect(201));

    assert.equal(comment.body, body, 'сервер не экранирует и не режет текст — это дело клиента (D-22)');

    const thread = await admin.api.get(`/issues/${issue.key}/comments`).then((r) => r.expect(200));
    assert.equal(thread.items[0].body, body);
  });
});

test('юникод в названиях проектов: короткое имя выдаётся и остаётся пригодным для адреса', async (t) => {
  const admin = await signIn({ displayName: 'Именующий проекты' });

  const names = {
    'только кириллица': 'Сладкий лимит',
    'эмодзи в названии': '🚀 Запуск 🎉',
    'только эмодзи': '🚀🎉✅',
    'китайские иероглифы': '任务跟踪器',
    'спецсимволы': 'Проект / с \\ разделителями',
    'дефисы по краям': '---Проект---',
    'много пробелов': 'Проект     с     пробелами',
  };

  const slugs = new Set();

  for (const [label, name] of Object.entries(names)) {
    await t.test(label, async () => {
      const response = await admin.api.post('/projects', { name });
      assert.ok(
        [201, 400].includes(response.status),
        `ожидался 201 или осмысленный 400, получено ${response.status}: ${JSON.stringify(response.body)}`,
      );
      if (response.status !== 201) return;

      const { slug } = response.body;
      assert.match(
        slug,
        /^[a-z0-9][a-z0-9-]*$/,
        `короткое имя «${slug}» должно годиться для адреса /projects/<slug>`,
      );
      assert.ok(!slugs.has(slug), `короткое имя ${slug} выдано дважды`);
      slugs.add(slug);

      const opened = await admin.api.get(`/projects/${slug}`).then((r) => r.expect(200));
      assert.equal(opened.name, name, 'название сохранено как есть');
    });
  }
});

test('пустые состояния отдают пустые списки, а не ошибки', async (t) => {
  const newcomer = await signIn({ displayName: 'Новичок без ничего' });

  await t.test('у нового пользователя нет проектов', async () => {
    const projects = await newcomer.api.get('/projects').then((r) => r.expect(200));
    assert.deepEqual(projects.items, []);
    assert.equal(projects.total, 0);
    assert.equal(projects.nextCursor, null);
  });

  await t.test('у нового пользователя пустой сайдбар и нет уведомлений', async () => {
    const sidebar = await newcomer.api.get('/issues/my-active').then((r) => r.expect(200));
    assert.deepEqual(sidebar.items, []);
    assert.equal(sidebar.total, 0);

    const notifications = await newcomer.api.get('/notifications').then((r) => r.expect(200));
    assert.deepEqual(notifications.items, []);
    assert.equal(notifications.unreadCount, 0);

    const counter = await newcomer.api.get('/notifications/unread-count').then((r) => r.expect(200));
    assert.equal(counter.unreadCount, 0);
  });

  await t.test('в новом проекте нет очередей', async () => {
    const project = await createProject(newcomer, 'Совсем пустой проект');
    const queues = await newcomer.api
      .get(`/projects/${project.slug}/queues`)
      .then((r) => r.expect(200));
    assert.deepEqual(queues.items, []);
  });

  await t.test('в новой очереди нет задач, а поиск по ней даёт пустой список', async () => {
    const project = await createProject(newcomer, 'Проект с пустой очередью');
    const queue = await createQueue(newcomer, project.slug);

    const issues = await newcomer.api.get(`/queues/${queue.key}/issues`).then((r) => r.expect(200));
    assert.deepEqual(issues.items, []);
    assert.equal(issues.total, 0);
    assert.equal(issues.nextCursor, null);
  });

  await t.test('у новой задачи нет комментариев и вложений, но история уже есть', async () => {
    const project = await createProject(newcomer, 'Проект новой задачи');
    const queue = await createQueue(newcomer, project.slug);
    const issue = await newcomer.api
      .post(`/queues/${queue.key}/issues`, { title: 'Только что заведена' })
      .then((r) => r.expect(201));

    const comments = await newcomer.api
      .get(`/issues/${issue.key}/comments`)
      .then((r) => r.expect(200));
    assert.deepEqual(comments.items, []);
    assert.equal(comments.total, 0);

    const attachments = await newcomer.api
      .get(`/issues/${issue.key}/attachments`)
      .then((r) => r.expect(200));
    assert.deepEqual(attachments.items, []);

    const history = await newcomer.api
      .get(`/issues/${issue.key}/history`)
      .then((r) => r.expect(200));
    assert.equal(history.total, 1, 'создание задачи — уже событие истории (US-90)');
    assert.equal(history.items[0].changes[0].kind, 'issue_created');
  });

  await t.test('в новом проекте один участник и нет приглашений', async () => {
    const project = await createProject(newcomer, 'Проект без приглашений');
    const invitations = await newcomer.api
      .get(`/projects/${project.slug}/invitations`)
      .then((r) => r.expect(200));
    assert.deepEqual(invitations.items, []);
    assert.equal(invitations.total, 0);
  });
});

test('значения полей вне шкалы отклоняются', async (t) => {
  const { admin, queue, statuses } = await scene('Проект неверных значений');
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача для неверных значений' })
    .then((r) => r.expect(201));

  await t.test('приоритет не кратен десяти', async () => {
    for (const priority of [5, 55, 99, -10, 110, 1.5]) {
      const response = await admin.api.patch(`/issues/${issue.key}`, { priority });
      assert.equal(response.status, 400, `приоритет ${priority} должен отклоняться`);
    }
  });

  await t.test('сложность вне шкалы Фибоначчи', async () => {
    for (const storyPoints of [4, 6, 7, 0, -1, 21]) {
      const response = await admin.api.patch(`/issues/${issue.key}`, { storyPoints });
      assert.equal(response.status, 400, `сложность ${storyPoints} должна отклоняться`);
    }
  });

  await t.test('сложность null снимает оценку (US-51)', async () => {
    await admin.api.patch(`/issues/${issue.key}`, { storyPoints: 8 }).then((r) => r.expect(200));
    const cleared = await admin.api
      .patch(`/issues/${issue.key}`, { storyPoints: null })
      .then((r) => r.expect(200));
    assert.equal(cleared.storyPoints, null);
  });

  await t.test('статус из чужой очереди отклоняется', async () => {
    const other = await scene('Проект чужих статусов');
    const response = await admin.api.patch(`/issues/${issue.key}`, {
      statusId: other.statuses[0].id,
    });
    assert.equal(response.status, 400, 'статус чужой очереди недопустим');
  });

  await t.test('несуществующий статус отклоняется', async () => {
    const response = await admin.api.patch(`/issues/${issue.key}`, {
      statusId: '00000000-0000-4000-8000-000000000000',
    });
    assert.ok([400, 404].includes(response.status), `получено ${response.status}`);
  });

  await t.test('переход в текущий статус не создаёт пустую запись истории', async () => {
    const before = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 100 } })
      .then((r) => r.expect(200));

    const current = await admin.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    await admin.api
      .patch(`/issues/${issue.key}`, { statusId: current.status.id })
      .then((r) => r.expect(200));

    const after = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 100 } })
      .then((r) => r.expect(200));
    assert.equal(after.total, before.total, 'изменение «сам в себя» в историю не пишется (US-92)');
  });

  await t.test('исполнитель не из проекта отклоняется', async () => {
    const outsider = await signIn({ displayName: 'Посторонний исполнитель' });
    const response = await admin.api.patch(`/issues/${issue.key}`, { assigneeId: outsider.id });
    assert.ok(
      [400, 404].includes(response.status),
      `назначить постороннего нельзя, получено ${response.status}`,
    );
  });

  await t.test('ключ очереди не по формату отклоняется', async () => {
    const project = await createProject(admin, 'Проект неверных ключей');
    for (const key of ['a', 'ОЧЕРЕДЬ', '1DEV', 'DEV-1', 'СЛИШКОМДЛИННЫЙКЛЮЧ', '', 'DE V']) {
      const response = await admin.api.post(`/projects/${project.slug}/queues`, {
        key,
        name: 'Очередь',
      });
      assert.equal(response.status, 400, `ключ ${JSON.stringify(key)} должен отклоняться`);
    }
  });

  await t.test('внешняя ссылка допускает только http и https (US-47)', async () => {
    for (const url of [
      'javascript:alert(1)',
      'data:text/html,<script>alert(1)</script>',
      'file:///etc/passwd',
      'ftp://example.com',
      'не ссылка вовсе',
    ]) {
      const response = await admin.api.post(`/issues/${issue.key}/links`, { url });
      assert.equal(response.status, 400, `схема ${url} должна отклоняться`);
    }

    // В ответе — задача целиком с обновлённым списком ссылок (так объявлено в контракте).
    const withLink = await admin.api
      .post(`/issues/${issue.key}/links`, { url: 'https://example.com/спека', title: 'Спека' })
      .then((r) => r.expect(201));
    const added = withLink.links.find((link) => link.url === 'https://example.com/спека');
    assert.ok(added, `ссылка не появилась в задаче: ${JSON.stringify(withLink.links)}`);
    assert.equal(added.title, 'Спека');
  });
});

test('вложения: пустой файл, длинное имя и превышение лимита', async (t) => {
  const { admin, queue } = await scene('Проект вложений');
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача с вложениями' })
    .then((r) => r.expect(201));

  await t.test('обычный файл прикладывается и виден в списке', async () => {
    const attachment = await admin.api
      .upload(`/issues/${issue.key}/attachments`, {
        filename: 'спецификация.txt',
        contentType: 'text/plain',
        bytes: Buffer.from('содержимое файла', 'utf8'),
      })
      .then((r) => r.expect(201));

    assert.ok(attachment.sizeBytes > 0);
    const list = await admin.api
      .get(`/issues/${issue.key}/attachments`)
      .then((r) => r.expect(200));
    assert.equal(list.total, 1);
    assert.equal(list.canUpload, true);
  });

  await t.test('пустой файл отклоняется', async () => {
    const response = await admin.api.upload(`/issues/${issue.key}/attachments`, {
      filename: 'pusto.txt',
      contentType: 'text/plain',
      bytes: Buffer.alloc(0),
    });
    assert.equal(response.status, 400);
    assert.equal(response.code, 'attachment_empty');
  });

  await t.test('очень длинное имя файла не роняет запрос', async () => {
    const response = await admin.api.upload(`/issues/${issue.key}/attachments`, {
      filename: `${'имя'.repeat(200)}.txt`,
      contentType: 'text/plain',
      bytes: Buffer.from('содержимое', 'utf8'),
    });
    assert.ok(
      [201, 400].includes(response.status),
      `ожидался 201 или осмысленный 400, получено ${response.status}: ${JSON.stringify(response.body)}`,
    );
    if (response.status === 201) {
      assert.ok(response.body.fileName.length > 0, 'имя файла не потеряно целиком');
    }
  });

  await t.test('имя файла с обходом каталога обезврежено', async () => {
    const response = await admin.api.upload(`/issues/${issue.key}/attachments`, {
      filename: '../../../etc/passwd',
      contentType: 'text/plain',
      bytes: Buffer.from('содержимое', 'utf8'),
    });
    if (response.status === 201) {
      assert.ok(
        !response.body.fileName.includes('..') && !response.body.fileName.includes('/'),
        `имя файла должно быть обезврежено, получено «${response.body.fileName}»`,
      );
    } else {
      assert.equal(response.status, 400);
    }
  });

  await t.test('файл больше 25 МБ отклоняется кодом 413', async () => {
    const tooBig = Buffer.alloc(25 * 1024 * 1024 + 1024, 0x41);
    const response = await admin.api.upload(`/issues/${issue.key}/attachments`, {
      filename: 'ogromny.bin',
      contentType: 'application/octet-stream',
      bytes: tooBig,
    });
    assert.equal(
      response.status,
      413,
      `ожидался 413, получено ${response.status}: ${JSON.stringify(response.body)}`,
    );
    assert.equal(response.code, 'attachment_too_large');
  });
});

test('CSRF: небезопасный метод без совпадающего Origin отклоняется', async (t) => {
  const { admin, queue } = await scene('Проект проверки Origin');

  await t.test('без заголовка Origin', async () => {
    const response = await admin.api
      .withoutOrigin()
      .post(`/queues/${queue.key}/issues`, { title: 'С чужого сайта' });
    assert.equal(response.status, 403);
    assert.equal(response.code, 'csrf_origin_mismatch');
  });

  await t.test('с чужим Origin', async () => {
    const response = await admin.api
      .withOrigin('https://evil.example')
      .post(`/queues/${queue.key}/issues`, { title: 'С чужого сайта' });
    assert.equal(response.status, 403);
    assert.equal(response.code, 'csrf_origin_mismatch');
  });

  await t.test('чтение без Origin разрешено: GET состояние не меняет', async () => {
    await admin.api.withoutOrigin().get(`/queues/${queue.key}/issues`).then((r) => r.expect(200));
  });

  await t.test('DELETE и PATCH тоже требуют Origin', async () => {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Задача для проверки Origin' })
      .then((r) => r.expect(201));

    const patched = await admin.api.withoutOrigin().patch(`/issues/${issue.key}`, { title: 'Нет' });
    assert.equal(patched.status, 403);

    const deleted = await admin.api.withoutOrigin().delete(`/issues/${issue.key}`);
    assert.equal(deleted.status, 403);
  });
});

test('чужие объекты отвечают 404, а не 403: о существовании узнать нельзя', async (t) => {
  const owner = await signIn({ displayName: 'Владелец чужого' });
  const stranger = await signIn({ displayName: 'Совсем посторонний' });

  const project = await createProject(owner, 'Чужой проект');
  const queue = await createQueue(owner, project.slug);
  const issue = await owner.api
    .post(`/queues/${queue.key}/issues`, { title: 'Чужая задача' })
    .then((r) => r.expect(201));
  const comment = await owner.api
    .post(`/issues/${issue.key}/comments`, { body: 'Чужой комментарий' })
    .then((r) => r.expect(201));

  const existing = [
    ['GET', `/projects/${project.slug}`],
    ['GET', `/projects/${project.slug}/members`],
    ['GET', `/projects/${project.slug}/queues`],
    ['GET', `/projects/${project.slug}/invitations`],
    ['GET', `/queues/${queue.key}`],
    ['GET', `/queues/${queue.key}/statuses`],
    ['GET', `/queues/${queue.key}/issues`],
    ['GET', `/issues/${issue.key}`],
    ['GET', `/issues/${issue.key}/comments`],
    ['GET', `/issues/${issue.key}/history`],
    ['GET', `/issues/${issue.key}/attachments`],
    ['GET', `/issues/${issue.key}/mention-suggestions`],
  ];

  for (const [method, path] of existing) {
    await t.test(`${method} ${path}`, async () => {
      const response = await stranger.api.request(method, path);
      assert.equal(
        response.status,
        404,
        `посторонний должен получить 404, а не ${response.status} (permissions §5)`,
      );
    });
  }

  await t.test('изменение чужого — тоже 404', async () => {
    const cases = [
      () => stranger.api.patch(`/issues/${issue.key}`, { title: 'Перехват' }),
      () => stranger.api.delete(`/issues/${issue.key}`),
      () => stranger.api.post(`/issues/${issue.key}/comments`, { body: 'Влезаю' }),
      () => stranger.api.patch(`/issues/${issue.key}/comments/${comment.id}`, { body: 'Правлю' }),
      () => stranger.api.delete(`/issues/${issue.key}/comments/${comment.id}`),
      () => stranger.api.post(`/projects/${project.slug}/queues`, { key: 'CHUZH', name: 'Чужая' }),
      () => stranger.api.patch(`/projects/${project.slug}`, { name: 'Мой теперь' }),
      () => stranger.api.delete(`/projects/${project.slug}`),
    ];

    for (const [index, call] of cases.entries()) {
      const response = await call();
      assert.equal(response.status, 404, `случай ${index}: получено ${response.status}`);
    }
  });

  await t.test('несуществующий объект отвечает так же, как чужой', async () => {
    const missing = await stranger.api.get('/issues/NETU-99999');
    assert.equal(missing.status, 404);

    const missingProject = await stranger.api.get('/projects/net-takogo-proekta');
    assert.equal(missingProject.status, 404);
  });
});

test('чужой комментарий правит только его автор — это 403, а не 404', async () => {
  const admin = await signIn({ displayName: 'Администратор комментариев' });
  const mate = await signIn({ displayName: 'Автор комментария', grantAccess: false });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  await inviteAndAccept(admin, project.slug, mate, 'member');

  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача с чужим комментарием' })
    .then((r) => r.expect(201));
  const comment = await mate.api
    .post(`/issues/${issue.key}/comments`, { body: 'Мой комментарий' })
    .then((r) => r.expect(201));

  // Администратор комментарий видит — значит отказ должен быть 403, а не 404.
  const edited = await admin.api.patch(`/issues/${issue.key}/comments/${comment.id}`, {
    body: 'Правлю чужое',
  });
  assert.equal(edited.status, 403, `получено ${edited.status}: ${JSON.stringify(edited.body)}`);

  const own = await mate.api
    .patch(`/issues/${issue.key}/comments/${comment.id}`, { body: 'Правлю своё' })
    .then((r) => r.expect(200));
  assert.equal(own.body, 'Правлю своё');
  assert.ok(own.editedAt, 'отметка о правке проставлена');
});

/**
 * Нулевой символ в тексте.
 *
 * PostgreSQL не хранит `\u0000` в `text`, и это надо отклонять на входе. Отдельный тест,
 * а не строка в общем переборе: поведение отличается от всех прочих «страшных» строк,
 * и в отчёте это должно быть видно по имени теста, а не по номеру случая в цикле.
 */
test('нулевой символ в тексте отклоняется, а не роняет сервер', async (t) => {
  const NUL = String.fromCharCode(0);
  const { admin, queue } = await scene('Проект нулевого символа');
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача для нулевого символа' })
    .then((r) => r.expect(201));

  const cases = {
    'название задачи': () =>
      admin.api.post(`/queues/${queue.key}/issues`, { title: `до${NUL}после` }),
    'описание задачи': () =>
      admin.api.post(`/queues/${queue.key}/issues`, {
        title: 'Задача с нулём в описании',
        description: `до${NUL}после`,
      }),
    'текст комментария': () =>
      admin.api.post(`/issues/${issue.key}/comments`, { body: `до${NUL}после` }),
    'название проекта': () => admin.api.post('/projects', { name: `Проект${NUL}ноль` }),
    'подпись внешней ссылки': () =>
      admin.api.post(`/issues/${issue.key}/links`, {
        url: 'https://example.com/nul',
        title: `до${NUL}после`,
      }),
  };

  for (const [name, call] of Object.entries(cases)) {
    await t.test(name, async () => {
      const response = await call();
      assert.ok(
        [200, 201, 400].includes(response.status),
        `ожидался 400 (или приём с очисткой), получено ${response.status}: ` +
          JSON.stringify(response.body),
      );
    });
  }
});

/**
 * Машиночитаемый код ошибки.
 *
 * Контракт обещает на 400 тело вида `{ code, message }` — по `code` клиент выбирает
 * текст для человека (`docs/design/screens/*`). Часть отказов приходит из доменного кода
 * и код несёт, часть — из проверки DTO и приходит в стандартном виде NestJS, без `code`.
 * Для клиента это два разных формата одной и той же ошибки.
 */
test('ошибка 400 несёт машиночитаемый код, как обещает контракт', async (t) => {
  const { admin, queue } = await scene('Проект кодов ошибок');
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача для кодов ошибок' })
    .then((r) => r.expect(201));

  const cases = {
    'слишком длинное название задачи': [
      () => admin.api.post(`/queues/${queue.key}/issues`, { title: 'я'.repeat(256) }),
      'invalid_issue_title',
    ],
    'пустое название задачи': [
      () => admin.api.post(`/queues/${queue.key}/issues`, { title: '   ' }),
      'invalid_issue_title',
    ],
    'слишком длинный комментарий': [
      () => admin.api.post(`/issues/${issue.key}/comments`, { body: 'т'.repeat(10_001) }),
      'invalid_comment_body',
    ],
    'пустой комментарий': [
      () => admin.api.post(`/issues/${issue.key}/comments`, { body: '   ' }),
      'invalid_comment_body',
    ],
    'приоритет вне шкалы': [
      () => admin.api.patch(`/issues/${issue.key}`, { priority: 55 }),
      undefined,
    ],
    'недопустимая схема ссылки': [
      () => admin.api.post(`/issues/${issue.key}/links`, { url: 'javascript:alert(1)' }),
      'invalid_link_url',
    ],
  };

  for (const [name, [call, expectedCode]] of Object.entries(cases)) {
    await t.test(name, async () => {
      const response = await call();
      assert.equal(response.status, 400, `ожидался 400, получено ${response.status}`);
      assert.ok(
        typeof response.code === 'string',
        `в теле нет машиночитаемого кода: ${JSON.stringify(response.body)}`,
      );
      if (expectedCode) {
        assert.equal(response.code, expectedCode);
      }
    });
  }
});
