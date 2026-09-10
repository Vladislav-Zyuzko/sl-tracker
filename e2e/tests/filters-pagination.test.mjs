import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { createProject, createQueue, inviteAndAccept, signIn } from '../lib/actors.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

const VOLUME = 120;

/**
 * Проходит список постранично и возвращает все элементы.
 *
 * Заодно ловит две типовые ошибки курсорной пагинации: бесконечную страницу
 * (курсор не двигается) и элементы, попавшие на две страницы сразу.
 */
async function drain(client, path, { limit = 10, query = {} } = {}) {
  const items = [];
  const seenCursors = new Set();
  let cursor;
  let pages = 0;

  do {
    const page = await client
      .get(path, { query: { ...query, limit, cursor } })
      .then((r) => r.expect(200));
    pages += 1;
    assert.ok(pages <= 200, 'пагинация не завершилась за 200 страниц — похоже на зацикливание');
    assert.ok(
      page.items.length <= limit,
      `страница вернула ${page.items.length} элементов при limit=${limit}`,
    );
    items.push(...page.items);

    cursor = page.nextCursor;
    if (cursor) {
      assert.ok(!seenCursors.has(cursor), `курсор ${cursor} выдан повторно — страницы зациклились`);
      seenCursors.add(cursor);
      assert.equal(
        page.items.length,
        limit,
        'непоследняя страница должна быть полной, иначе клиент решит, что данные кончились',
      );
    }
  } while (cursor);

  return { items, pages };
}

async function bigQueue() {
  const admin = await signIn({ displayName: 'Хозяин большой очереди' });
  const worker = await signIn({ displayName: 'Исполнитель большой очереди', grantAccess: false });
  const project = await createProject(admin, 'Проект с объёмом');
  const queue = await createQueue(admin, project.slug);
  await inviteAndAccept(admin, project.slug, worker, 'member');
  const statuses = await admin.api
    .get(`/queues/${queue.key}/statuses`)
    .then((r) => r.expect(200))
    .then((body) => body.items);

  const priorities = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
  const created = [];

  for (let i = 0; i < VOLUME; i += 1) {
    const issue = await admin.api
      .post(`/queues/${queue.key}/issues`, {
        title: `Задача объёма ${i}`,
        priority: priorities[i % priorities.length],
        statusId: statuses[i % statuses.length].id,
        assigneeId: i % 3 === 0 ? worker.id : undefined,
      })
      .then((r) => r.expect(201));
    created.push(issue);
  }

  return { admin, worker, project, queue, statuses, created };
}

test('пагинация большого списка задач не теряет и не дублирует элементы', async (t) => {
  const { admin, queue } = await bigQueue();

  await t.test(`${VOLUME} задач вычитываются постранично целиком`, async () => {
    const { items, pages } = await drain(admin.api, `/queues/${queue.key}/issues`, { limit: 10 });

    assert.equal(items.length, VOLUME, 'вычитаны все задачи');
    assert.equal(new Set(items.map((i) => i.key)).size, VOLUME, 'без повторов между страницами');
    assert.ok(pages >= VOLUME / 10, `страниц ${pages} — пагинация действительно постраничная`);
  });

  await t.test('размер страницы соблюдается для разных limit', async () => {
    for (const limit of [1, 7, 50, 100]) {
      const page = await admin.api
        .get(`/queues/${queue.key}/issues`, { query: { limit } })
        .then((r) => r.expect(200));
      assert.equal(page.items.length, Math.min(limit, VOLUME), `limit=${limit}`);
      assert.equal(page.total, VOLUME, 'total не зависит от размера страницы');
    }
  });

  await t.test('limit сверх предела не отдаёт больше предела', async () => {
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 1000 } })
      .then((r) => r.expect(200));
    assert.ok(page.items.length <= 100, `отдано ${page.items.length} при пределе 100`);
  });

  await t.test('нулевой и отрицательный limit не роняют запрос', async () => {
    for (const limit of [0, -1]) {
      const response = await admin.api.get(`/queues/${queue.key}/issues`, { query: { limit } });
      assert.ok(
        [200, 400].includes(response.status),
        `limit=${limit}: ожидался 200 или 400, получено ${response.status}`,
      );
      if (response.status === 200) {
        assert.ok(response.body.items.length > 0, 'пустая страница без курсора — тупик для клиента');
      }
    }
  });

  await t.test('нечисловой limit не роняет запрос', async () => {
    const response = await admin.api.get(`/queues/${queue.key}/issues`, { query: { limit: 'много' } });
    assert.ok([200, 400].includes(response.status), `получено ${response.status}`);
  });

  await t.test('испорченный курсор отклоняется кодом invalid_cursor', async () => {
    for (const cursor of ['ерунда', '!!!', 'MTIzNDU2', '../../etc/passwd']) {
      const response = await admin.api.get(`/queues/${queue.key}/issues`, { query: { cursor } });
      assert.equal(response.status, 400, `курсор ${JSON.stringify(cursor)}`);
      assert.equal(response.code, 'invalid_cursor');
    }
  });

  await t.test('последняя страница возвращает nextCursor = null', async () => {
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 100 } })
      .then((r) => r.expect(200));
    const last = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 100, cursor: page.nextCursor } })
      .then((r) => r.expect(200));
    assert.equal(last.nextCursor, null, 'на последней странице курсора нет');
  });
});

test('фильтры списка задач отбирают ровно то, что просили', async (t) => {
  const { admin, worker, queue, statuses, created } = await bigQueue();

  await t.test('фильтр по статусу', async () => {
    for (const status of statuses) {
      const expected = created.filter((i) => i.status.id === status.id).length;
      const { items } = await drain(admin.api, `/queues/${queue.key}/issues`, {
        limit: 50,
        query: { status: status.key },
      });
      assert.equal(items.length, expected, `статус ${status.key}`);
      assert.ok(
        items.every((i) => i.status.key === status.key),
        `в выборке по ${status.key} есть чужие статусы`,
      );
    }
  });

  await t.test('фильтр по исполнителю', async () => {
    const expected = created.filter((_, i) => i % 3 === 0).length;
    const { items } = await drain(admin.api, `/queues/${queue.key}/issues`, {
      limit: 50,
      query: { assignee: worker.id },
    });
    assert.equal(items.length, expected);
    assert.ok(items.every((i) => i.assignee?.id === worker.id));
  });

  await t.test('фильтр по автору', async () => {
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { author: admin.id, limit: 100 } })
      .then((r) => r.expect(200));
    assert.equal(page.total, VOLUME, 'все задачи заведены одним автором');
  });

  await t.test('границы приоритета включительны', async () => {
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, {
        query: { priorityMin: 70, priorityMax: 90, limit: 100 },
      })
      .then((r) => r.expect(200));

    assert.ok(page.items.length > 0, 'выборка не пуста');
    assert.ok(
      page.items.every((i) => i.priority >= 70 && i.priority <= 90),
      'в выборку попали приоритеты вне границ',
    );

    const expected = created.filter((i) => i.priority >= 70 && i.priority <= 90).length;
    assert.equal(page.total, expected, 'границы включают сами значения 70 и 90');
  });

  await t.test('перевёрнутые границы приоритета дают пустой список, а не ошибку', async () => {
    const response = await admin.api.get(`/queues/${queue.key}/issues`, {
      query: { priorityMin: 90, priorityMax: 10, limit: 100 },
    });
    assert.ok([200, 400].includes(response.status), `получено ${response.status}`);
    if (response.status === 200) {
      assert.equal(response.body.total, 0);
      assert.deepEqual(response.body.items, []);
    }
  });

  await t.test('фильтр, под который ничего не подходит, отдаёт пустой список', async () => {
    const stranger = await signIn({ displayName: 'Никому не исполнитель' });
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { assignee: stranger.id, limit: 100 } })
      .then((r) => r.expect(200));
    assert.deepEqual(page.items, []);
    assert.equal(page.total, 0);
    assert.equal(page.nextCursor, null);
  });

  await t.test('несколько фильтров сужают выборку совместно', async () => {
    const status = statuses[0];
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, {
        query: { status: status.key, assignee: worker.id, limit: 100 },
      })
      .then((r) => r.expect(200));

    assert.ok(
      page.items.every((i) => i.status.key === status.key && i.assignee?.id === worker.id),
      'фильтры должны применяться вместе, а не по отдельности',
    );
  });

  await t.test('сортировка по приоритету идёт от высокого к низкому', async () => {
    const page = await admin.api
      .get(`/queues/${queue.key}/issues`, { query: { sort: 'priority', limit: 100 } })
      .then((r) => r.expect(200));

    const priorities = page.items.map((i) => i.priority);
    const sorted = [...priorities].sort((a, b) => b - a);
    assert.deepEqual(priorities, sorted, 'порядок по приоритету нарушен');
  });

  await t.test('сортировка сохраняется между страницами', async () => {
    const { items } = await drain(admin.api, `/queues/${queue.key}/issues`, {
      limit: 10,
      query: { sort: 'priority' },
    });
    const priorities = items.map((i) => i.priority);
    const sorted = [...priorities].sort((a, b) => b - a);
    assert.deepEqual(priorities, sorted, 'на границе страниц порядок сбился');
    assert.equal(new Set(items.map((i) => i.key)).size, VOLUME, 'без повторов при сортировке');
  });

  await t.test('неизвестное значение сортировки не роняет запрос', async () => {
    const response = await admin.api.get(`/queues/${queue.key}/issues`, {
      query: { sort: 'как-нибудь' },
    });
    assert.ok([200, 400].includes(response.status), `получено ${response.status}`);
  });

  await t.test('несуществующий статус в фильтре не выдаёт чужие задачи', async () => {
    const response = await admin.api.get(`/queues/${queue.key}/issues`, {
      query: { status: 'net-takogo-statusa', limit: 100 },
    });
    assert.ok([200, 400].includes(response.status), `получено ${response.status}`);
    if (response.status === 200) {
      assert.equal(response.body.total, 0, 'неизвестный статус не должен снимать фильтр');
    }
  });
});

test('сайдбар: объём, поиск и пагинация', async (t) => {
  const { worker, queue, created, admin, statuses } = await bigQueue();

  await t.test('в сайдбаре только активные задачи исполнителя', async () => {
    const doneStatus = statuses.find((s) => s.category === 'done');
    const assigned = created.filter((_, i) => i % 3 === 0);

    const { items } = await drain(worker.api, '/issues/my-active', { limit: 25 });
    const active = assigned.filter((i) => i.status.id !== doneStatus.id);

    assert.equal(items.length, active.length, 'закрытые задачи в сайдбар не попадают');
    assert.ok(
      items.every((i) => i.status.category !== 'done'),
      'в сайдбаре оказалась закрытая задача',
    );
  });

  await t.test('поиск по подстроке названия', async () => {
    const page = await worker.api
      .get('/issues/my-active', { query: { q: 'объёма 3', limit: 50 } })
      .then((r) => r.expect(200));
    assert.ok(
      page.items.every((i) => i.title.includes('объёма 3')),
      `в выдаче есть чужие названия: ${JSON.stringify(page.items.map((i) => i.title))}`,
    );
  });

  await t.test('поиск без совпадений отдаёт пустой список', async () => {
    const page = await worker.api
      .get('/issues/my-active', { query: { q: 'такоготочнонет' } })
      .then((r) => r.expect(200));
    assert.deepEqual(page.items, []);
  });

  await t.test('total сайдбара учитывает поиск, а не только назначение', async () => {
    // total — то, что интерфейс показывает рядом со списком. Если он считает
    // без учёта поиска, экран говорит «ничего не найдено» и «найдено 32» одновременно.
    const all = await worker.api
      .get('/issues/my-active', { query: { limit: 100 } })
      .then((r) => r.expect(200));

    const empty = await worker.api
      .get('/issues/my-active', { query: { q: 'такоготочнонет' } })
      .then((r) => r.expect(200));
    assert.equal(empty.total, 0, `поиск без совпадений: items пуст, а total = ${empty.total}`);

    const narrowed = await worker.api
      .get('/issues/my-active', { query: { q: 'объёма 3', limit: 100 } })
      .then((r) => r.expect(200));
    assert.equal(
      narrowed.total,
      narrowed.items.length,
      'при поиске total должен совпасть с числом найденного',
    );
    assert.ok(narrowed.total < all.total, 'поиск обязан сужать выборку');
  });

  await t.test('поиск по ключу задачи регистронезависим', async () => {
    const some = await worker.api
      .get('/issues/my-active', { query: { limit: 1 } })
      .then((r) => r.expect(200));
    const key = some.items[0].key;

    for (const query of [key, key.toLowerCase(), key.toUpperCase()]) {
      const page = await worker.api
        .get('/issues/my-active', { query: { q: query } })
        .then((r) => r.expect(200));
      assert.ok(
        page.items.some((i) => i.key === key),
        `поиск по «${query}» не нашёл задачу ${key}`,
      );
    }
  });

  await t.test('чужие задачи в сайдбар не попадают', async () => {
    const { items } = await drain(admin.api, '/issues/my-active', { limit: 50 });
    assert.deepEqual(items, [], 'администратор ничего себе не назначал — сайдбар пуст');
  });
});

test('пагинация комментариев, истории, участников и уведомлений', async (t) => {
  const admin = await signIn({ displayName: 'Многословный' });
  const project = await createProject(admin, 'Проект многих записей');
  const queue = await createQueue(admin, project.slug);
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача с длинной лентой' })
    .then((r) => r.expect(201));

  const COMMENTS = 35;
  for (let i = 0; i < COMMENTS; i += 1) {
    await admin.api
      .post(`/issues/${issue.key}/comments`, { body: `Комментарий номер ${i}` })
      .then((r) => r.expect(201));
  }

  await t.test('лента комментариев вычитывается целиком и без повторов', async () => {
    const { items } = await drain(admin.api, `/issues/${issue.key}/comments`, { limit: 10 });
    assert.equal(items.length, COMMENTS);
    assert.equal(new Set(items.map((c) => c.id)).size, COMMENTS);
  });

  await t.test('внутри страницы комментарии идут от старых к новым', async () => {
    // Пагинация ленты идёт назад по времени («Показать более ранние»), а внутри страницы
    // порядок хронологический — так объявлено в контракте `GET /api/issues/{key}/comments`.
    const page = await admin.api
      .get(`/issues/${issue.key}/comments`, { query: { limit: 10 } })
      .then((r) => r.expect(200));
    const times = page.items.map((c) => Date.parse(c.createdAt));
    assert.deepEqual([...times].sort((a, b) => a - b), times, 'сначала старые (US-70)');
  });

  await t.test('каждая следующая страница ленты старше предыдущей', async () => {
    let cursor;
    let previousOldest = Infinity;
    let pages = 0;

    do {
      const page = await admin.api
        .get(`/issues/${issue.key}/comments`, { query: { limit: 10, cursor } })
        .then((r) => r.expect(200));
      pages += 1;

      const times = page.items.map((c) => Date.parse(c.createdAt));
      assert.deepEqual([...times].sort((a, b) => a - b), times, `страница ${pages}: порядок внутри`);
      assert.ok(
        Math.max(...times) < previousOldest,
        `страница ${pages} пересекается по времени с предыдущей`,
      );
      previousOldest = Math.min(...times);
      cursor = page.nextCursor;
    } while (cursor);

    assert.ok(pages >= 4, `лента из ${COMMENTS} комментариев должна занять несколько страниц`);
  });

  await t.test('история задачи вычитывается постранично', async () => {
    const HISTORY_CHANGES = 25;
    for (let i = 0; i < HISTORY_CHANGES; i += 1) {
      await admin.api
        .patch(`/issues/${issue.key}`, { title: `Название версия ${i}` })
        .then((r) => r.expect(200));
    }

    const { items } = await drain(admin.api, `/issues/${issue.key}/history`, { limit: 10 });
    assert.ok(items.length >= HISTORY_CHANGES, `записей истории ${items.length}`);
    assert.equal(new Set(items.map((e) => e.id)).size, items.length, 'без повторов');
  });

  await t.test('история идёт от новых к старым', async () => {
    const page = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 50 } })
      .then((r) => r.expect(200));
    const times = page.items.map((e) => Date.parse(e.createdAt));
    const sorted = [...times].sort((a, b) => b - a);
    assert.deepEqual(times, sorted, 'сначала новые (US-90)');
  });

  await t.test('список участников вычитывается постранично', async () => {
    const guests = [];
    for (let i = 0; i < 12; i += 1) {
      const guest = await signIn({ displayName: `Участник ${i}`, grantAccess: false });
      await inviteAndAccept(admin, project.slug, guest, 'member');
      guests.push(guest);
    }

    const { items } = await drain(admin.api, `/projects/${project.slug}/members`, { limit: 5 });
    assert.equal(items.length, guests.length + 1, 'все участники и администратор');
    assert.equal(new Set(items.map((m) => m.userId)).size, items.length, 'без повторов');
  });

  await t.test('уведомления вычитываются постранично, счётчик не зависит от страницы', async () => {
    const worker = await signIn({ displayName: 'Получатель уведомлений', grantAccess: false });
    await inviteAndAccept(admin, project.slug, worker, 'member');

    const keys = [];
    for (let i = 0; i < 15; i += 1) {
      const created = await admin.api
        .post(`/queues/${queue.key}/issues`, { title: `Назначение ${i}` })
        .then((r) => r.expect(201));
      keys.push(created.key);
      await admin.api
        .patch(`/issues/${created.key}`, { assigneeId: worker.id })
        .then((r) => r.expect(200));
    }

    const first = await worker.api
      .get('/notifications', { query: { limit: 5 } })
      .then((r) => r.expect(200));
    const second = await worker.api
      .get('/notifications', { query: { limit: 5, cursor: first.nextCursor } })
      .then((r) => r.expect(200));

    assert.equal(
      first.unreadCount,
      second.unreadCount,
      'счётчик непрочитанных одинаков на всех страницах',
    );
    const ids = new Set([...first.items, ...second.items].map((n) => n.id));
    assert.equal(ids.size, first.items.length + second.items.length, 'страницы не пересекаются');
  });
});

test('курсор одного списка не открывает данные другого', async () => {
  const admin = await signIn({ displayName: 'Хозяин двух очередей' });
  const project = await createProject(admin, 'Проект двух курсоров');
  const first = await createQueue(admin, project.slug);
  const second = await createQueue(admin, project.slug);

  for (let i = 0; i < 15; i += 1) {
    await admin.api
      .post(`/queues/${first.key}/issues`, { title: `Первая очередь ${i}` })
      .then((r) => r.expect(201));
  }
  for (let i = 0; i < 3; i += 1) {
    await admin.api
      .post(`/queues/${second.key}/issues`, { title: `Вторая очередь ${i}` })
      .then((r) => r.expect(201));
  }

  const page = await admin.api
    .get(`/queues/${first.key}/issues`, { query: { limit: 10 } })
    .then((r) => r.expect(200));

  const foreign = await admin.api.get(`/queues/${second.key}/issues`, {
    query: { limit: 10, cursor: page.nextCursor },
  });

  assert.ok([200, 400].includes(foreign.status), `получено ${foreign.status}`);
  if (foreign.status === 200) {
    assert.ok(
      foreign.body.items.every((i) => i.key.startsWith(`${second.key}-`)),
      'чужой курсор не должен вытаскивать задачи другой очереди',
    );
  }
});
