import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb, sql } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import {
  createProject,
  createQueue,
  freshQueueKey,
  inviteAndAccept,
  signIn,
  tokenFromInvitationUrl,
} from '../lib/actors.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Гонки — на уровне HTTP, а не сервиса.
 *
 * В `apps/api/test/issue-key.concurrency.e2e-spec.ts` то же свойство проверяется вызовами
 * сервиса напрямую. Здесь запросы идут через настоящий HTTP: в игру вступают разбор тела,
 * пул соединений Fastify и транзакция запроса целиком. Ошибка выдачи ключа, спрятанная
 * за уровнем сервиса, видна именно отсюда.
 */

const PARALLEL = 30;

test('параллельное создание задач в одной очереди даёт разные ключи', async (t) => {
  const author = await signIn({ displayName: 'Автор гонки' });
  const project = await createProject(author, 'Проект гонок');
  const queue = await createQueue(author, project.slug, { key: freshQueueKey('RACE') });

  let responses;

  await t.test(`${PARALLEL} одновременных запросов создания`, async () => {
    responses = await Promise.all(
      Array.from({ length: PARALLEL }, (_, i) =>
        author.api.post(`/queues/${queue.key}/issues`, { title: `Одновременная задача ${i}` }),
      ),
    );

    const failed = responses.filter((r) => r.status !== 201);
    assert.equal(
      failed.length,
      0,
      `все запросы должны завершиться успехом, упало ${failed.length}: ` +
        JSON.stringify(failed.map((r) => ({ status: r.status, body: r.body }))),
    );
  });

  await t.test('ключи не повторяются', async () => {
    const keys = responses.map((r) => r.body.key);
    const unique = new Set(keys);
    assert.equal(
      unique.size,
      PARALLEL,
      `выдано ${unique.size} различных ключей из ${PARALLEL}. Дубликаты: ` +
        JSON.stringify(keys.filter((key, i) => keys.indexOf(key) !== i)),
    );
  });

  await t.test('номера идут подряд, без дыр', async () => {
    const numbers = responses.map((r) => Number(r.body.key.split('-')[1])).sort((a, b) => a - b);
    assert.deepEqual(
      numbers,
      Array.from({ length: PARALLEL }, (_, i) => i + 1),
      'номера задач в очереди должны быть 1..N без пропусков',
    );
  });

  await t.test('в базе ровно столько задач, сколько создано', async () => {
    const rows = await sql(
      `select count(*)::int as total, count(distinct i.key)::int as unique_keys
       from issues i join queues q on q.id = i.queue_id where q.key = $1`,
      [queue.key],
    );
    assert.equal(rows[0].total, PARALLEL);
    assert.equal(rows[0].unique_keys, PARALLEL, 'уникальность ключа держится и на уровне данных');
  });

  await t.test('список задач видит все созданные', async () => {
    const list = await author.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 100 } })
      .then((r) => r.expect(200));
    assert.equal(list.total, PARALLEL);
  });
});

test('параллельное создание в двух очередях не смешивает нумерацию', async () => {
  const author = await signIn({ displayName: 'Автор двух очередей' });
  const project = await createProject(author);
  const first = await createQueue(author, project.slug, { key: freshQueueKey('AAA') });
  const second = await createQueue(author, project.slug, { key: freshQueueKey('BBB') });

  const responses = await Promise.all([
    ...Array.from({ length: 10 }, (_, i) =>
      author.api.post(`/queues/${first.key}/issues`, { title: `Первая ${i}` }),
    ),
    ...Array.from({ length: 10 }, (_, i) =>
      author.api.post(`/queues/${second.key}/issues`, { title: `Вторая ${i}` }),
    ),
  ]);

  assert.ok(
    responses.every((r) => r.status === 201),
    'все запросы успешны',
  );

  for (const queue of [first, second]) {
    const numbers = responses
      .filter((r) => r.body.key.startsWith(`${queue.key}-`))
      .map((r) => Number(r.body.key.split('-')[1]))
      .sort((a, b) => a - b);
    assert.deepEqual(
      numbers,
      Array.from({ length: 10 }, (_, i) => i + 1),
      `нумерация очереди ${queue.key} независима`,
    );
  }
});

test('одновременная попытка занять один ключ очереди: побеждает ровно один', async () => {
  const author = await signIn({ displayName: 'Претендент на ключ' });
  const project = await createProject(author);
  const contested = freshQueueKey('ONE');

  const responses = await Promise.all(
    Array.from({ length: 5 }, () =>
      author.api.post(`/projects/${project.slug}/queues`, { key: contested, name: 'Спорная' }),
    ),
  );

  const created = responses.filter((r) => r.status === 201);
  const conflicts = responses.filter((r) => r.status === 409);

  assert.equal(created.length, 1, 'ключ очереди глобально уникален — создаться должна одна');
  assert.equal(conflicts.length, 4, 'остальные получают 409, а не 500');
  for (const conflict of conflicts) {
    assert.equal(conflict.code, 'queue_key_taken');
  }
});

test('одновременная правка одной задачи двумя людьми не теряет историю', async (t) => {
  const admin = await signIn({ displayName: 'Первый редактор' });
  const mate = await signIn({ displayName: 'Второй редактор', grantAccess: false });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  await inviteAndAccept(admin, project.slug, mate, 'member');

  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Спорная задача', priority: 50 })
    .then((r) => r.expect(201));
  const statuses = await admin.api.get(`/queues/${queue.key}/statuses`).then((r) => r.expect(200));

  await t.test('оба изменения приняты', async () => {
    const [byAdmin, byMate] = await Promise.all([
      admin.api.patch(`/issues/${issue.key}`, { title: 'Название от первого' }),
      mate.api.patch(`/issues/${issue.key}`, { priority: 90 }),
    ]);

    assert.equal(byAdmin.status, 200);
    assert.equal(byMate.status, 200);
  });

  await t.test('оба изменения видны в итоговой задаче: правки разных полей не затирают друг друга', async () => {
    const current = await admin.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.equal(current.title, 'Название от первого');
    assert.equal(current.priority, 90, 'правка второго поля не потеряна при одновременной записи');
  });

  await t.test('в истории есть обе записи с разными авторами', async () => {
    const history = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 50 } })
      .then((r) => r.expect(200));

    const kinds = history.items.flatMap((e) => e.changes.map((c) => c.kind));
    assert.ok(kinds.includes('title_changed'), 'смена названия записана');
    assert.ok(kinds.includes('priority_changed'), 'смена приоритета записана');

    const actors = new Set(history.items.map((e) => e.actor?.id));
    assert.ok(actors.has(admin.id) && actors.has(mate.id), 'оба автора названы в истории');
  });

  await t.test('одновременная смена статуса двумя: побеждает один, история не двоится', async () => {
    const [first, second] = await Promise.all([
      admin.api.patch(`/issues/${issue.key}`, { statusId: statuses.items[1].id }),
      mate.api.patch(`/issues/${issue.key}`, { statusId: statuses.items[2].id }),
    ]);
    assert.equal(first.status, 200);
    assert.equal(second.status, 200);

    const current = await admin.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.ok(
      [statuses.items[1].id, statuses.items[2].id].includes(current.status.id),
      'итоговый статус — один из двух запрошенных',
    );

    const history = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 50 } })
      .then((r) => r.expect(200));
    const statusChanges = history.items
      .flatMap((e) => e.changes)
      .filter((c) => c.kind === 'status_changed');

    for (const change of statusChanges) {
      assert.notEqual(
        change.oldValue,
        change.newValue,
        `в историю попал переход «сам в себя»: ${JSON.stringify(change)}`,
      );
    }
  });
});

test('двойная отправка комментария создаёт два комментария, а не ломает ленту', async () => {
  const author = await signIn({ displayName: 'Быстро кликающий' });
  const project = await createProject(author);
  const queue = await createQueue(author, project.slug);
  const issue = await author.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача с двойным кликом' })
    .then((r) => r.expect(201));

  const body = 'Один и тот же текст, отправленный дважды подряд';
  const [first, second] = await Promise.all([
    author.api.post(`/issues/${issue.key}/comments`, { body }),
    author.api.post(`/issues/${issue.key}/comments`, { body }),
  ]);

  assert.equal(first.status, 201);
  assert.equal(second.status, 201);
  assert.notEqual(first.body.id, second.body.id, 'это два разных комментария');

  const thread = await author.api.get(`/issues/${issue.key}/comments`).then((r) => r.expect(200));
  assert.equal(thread.total, 2, 'лента показывает ровно два — без потерь и без дублей сверх');
  // Защиты от двойной отправки в MVP нет по замыслу: ключа идемпотентности в контракте
  // не объявлено. Тест фиксирует наблюдаемое поведение, чтобы оно не изменилось молча.
});

test('одновременное принятие одного приглашения не двоит членство', async () => {
  const admin = await signIn({ displayName: 'Приглашающий' });
  const guest = await signIn({ displayName: 'Спешащий гость', grantAccess: false });
  const project = await createProject(admin);

  const invitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'member' })
    .then((r) => r.expect(201));
  const token = tokenFromInvitationUrl(invitation.url);

  const responses = await Promise.all(
    Array.from({ length: 5 }, () => guest.api.post(`/invitations/${token}/accept`)),
  );

  const codes = responses.map((r) => r.status);
  assert.ok(
    codes.every((code) => code === 200),
    `все попытки должны отвечать 200, получено ${JSON.stringify(codes)}`,
  );

  const members = await admin.api
    .get(`/projects/${project.slug}/members`)
    .then((r) => r.expect(200));
  assert.equal(members.total, 2, 'администратор и гость, без дублей');

  const rows = await sql(
    `select count(*)::int as total from project_members pm
     join projects p on p.id = pm.project_id
     where p.slug = $1 and pm.user_id = $2`,
    [project.slug, guest.id],
  );
  assert.equal(rows[0].total, 1, 'в данных ровно одна строка членства');
});

/**
 * Запись в задачу, которую в этот момент удаляют.
 *
 * Ожидание: либо запись успела (201), либо задачи уже нет (404). Ответ 500 недопустим:
 * это не «редкий случай», а необработанное нарушение внешнего ключа, вылезающее наружу.
 *
 * Попыток несколько намеренно. Одна попытка сделала бы тест неустойчивым в обе стороны:
 * и пропускала бы дефект, и падала бы случайно. Несколько попыток дают устойчивый ответ
 * на вопрос «бывает ли 500 вообще».
 */
const RACE_ATTEMPTS = 10;

test('запись в удаляемую задачу отвечает 404, а не 500', async (t) => {
  const admin = await signIn({ displayName: 'Удаляющий' });
  const mate = await signIn({ displayName: 'Пишущий', grantAccess: false });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  await inviteAndAccept(admin, project.slug, mate, 'member');
  const statuses = await admin.api.get(`/queues/${queue.key}/statuses`).then((r) => r.expect(200));

  const writers = {
    'комментарий': (key, i) => mate.api.post(`/issues/${key}/comments`, { body: `Успею ли ${i}?` }),
    'внешняя ссылка': (key, i) =>
      mate.api.post(`/issues/${key}/links`, {
        url: `https://example.com/${i}`,
        title: `Ссылка ${i}`,
      }),
    'вложение': (key, i) =>
      mate.api.upload(`/issues/${key}/attachments`, {
        filename: `file-${i}.txt`,
        contentType: 'text/plain',
        bytes: Buffer.from(`содержимое ${i}`, 'utf8'),
      }),
    'смена статуса': (key) => mate.api.patch(`/issues/${key}`, { statusId: statuses.items[1].id }),
  };

  for (const [name, write] of Object.entries(writers)) {
    await t.test(name, async () => {
      const tally = {};
      for (let i = 0; i < RACE_ATTEMPTS; i += 1) {
        const issue = await admin.api
          .post(`/queues/${queue.key}/issues`, { title: `Гонка ${name} ${i}` })
          .then((r) => r.expect(201));

        const [, written] = await Promise.all([
          admin.api.delete(`/issues/${issue.key}`),
          write(issue.key, i),
        ]);
        tally[written.status] = (tally[written.status] ?? 0) + 1;
      }

      const unexpected = Object.keys(tally)
        .map(Number)
        .filter((code) => ![200, 201, 204, 404].includes(code));

      assert.deepEqual(
        unexpected,
        [],
        `${name}: недопустимые коды ответа ${JSON.stringify(tally)} за ${RACE_ATTEMPTS} попыток. ` +
          'Ожидались только 201 (успел) и 404 (задачи уже нет)',
      );
    });
  }

  await t.test('в базе не осталось записей без задачи', async () => {
    const orphans = await sql(
      `select
         (select count(*) from comments c left join issues i on i.id = c.issue_id where i.id is null)::int as comments,
         (select count(*) from attachments a left join issues i on i.id = a.issue_id where i.id is null)::int as attachments,
         (select count(*) from issue_links l left join issues i on i.id = l.issue_id where i.id is null)::int as links`,
    );
    assert.deepEqual(orphans[0], { comments: 0, attachments: 0, links: 0 });
  });
});
