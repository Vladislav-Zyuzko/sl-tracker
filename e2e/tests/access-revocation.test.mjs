import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb, grantTrackerAccess, issueSession, sessionRow } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { ApiClient } from '../lib/api.mjs';
import { anotherSession, createProject, createQueue, signIn } from '../lib/actors.mjs';
import { realtimeHandshake } from '../lib/ws.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Отзыв доступа при открытой вкладке — US-09, D-40, ADR-0006.
 *
 * Требование сформулировано как «немедленно»: удаление записи закрывает вход и гасит
 * активные сессии, а открытая вкладка перестаёт показывать данные. Проверять это
 * можно только на живом сервере с настоящим сокетом: внутри Jest ни одной открытой
 * вкладки нет.
 *
 * «Немедленно» здесь измеряется и печатается. Если сокет закрывается только по такту
 * сердцебиения (30 секунд), формально требование выполнено, а по существу — нет,
 * и число в выводе покажет это без спора.
 */
const IMMEDIATE_BUDGET_MS = 10_000;

/** Владелец трекера, способный удалять записи списка доступа. */
async function instanceOwner() {
  const owner = await signIn({ displayName: `Владелец ${Date.now()}`, owner: true });
  return owner;
}

/** Запись списка доступа для адреса пользователя. */
async function accessEntryFor(owner, email) {
  const list = await owner.api
    .get('/access-entries', { query: { q: email, limit: 10 } })
    .then((r) => r.expect(200));
  const entry = list.items.find((item) => item.email === email.toLowerCase());
  assert.ok(entry, `в списке доступа нет записи для ${email}`);
  return entry;
}

test('отзыв доступа при открытой вкладке: сессия гаснет, сокет закрывается', async (t) => {
  const owner = await instanceOwner();
  const leaver = await signIn({ displayName: 'Уходящий сотрудник' });

  const project = await createProject(leaver, 'Проект уходящего');
  const queue = await createQueue(leaver, project.slug);
  const issue = await leaver.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача уходящего' })
    .then((r) => r.expect(201));

  // Две вкладки: обе должны погаснуть, а не только та, через которую шёл отзыв.
  const firstTab = await leaver.openSocket('вкладка 1');
  const secondTab = await leaver.openSocket('вкладка 2');
  await firstTab.subscribe(`issue:${issue.key}`);

  const otherTab = await anotherSession(leaver);
  t.after(() => leaver.closeSockets());

  await t.test('до отзыва всё работает', async () => {
    await leaver.api.get('/me').then((r) => r.expect(200));
    await otherTab.api.get('/me').then((r) => r.expect(200));
    assert.equal(firstTab.closed, null);
    assert.equal(secondTab.closed, null);
  });

  let revokedAt;
  let revokedSessions;

  await t.test('владелец удаляет запись списка доступа', async () => {
    const entry = await accessEntryFor(owner, leaver.email);
    revokedAt = Date.now();
    const result = await owner.api.delete(`/access-entries/${entry.id}`).then((r) => r.expect(200));
    revokedSessions = result.revokedSessions;
    assert.ok(revokedSessions >= 2, `погашены все сессии человека, а не одна (${revokedSessions})`);
  });

  await t.test('обе открытые вкладки перестали показывать данные', async () => {
    for (const [label, client] of [
      ['первая сессия', leaver.api],
      ['вторая сессия', otherTab.api],
    ]) {
      const response = await client.get('/me');
      assert.equal(response.status, 401, `${label} должна быть погашена`);
      assert.equal(response.code, 'session_expired');
    }

    const projectResponse = await leaver.api.get(`/projects/${project.slug}`);
    assert.equal(projectResponse.status, 401, 'данные проекта тоже закрыты');
  });

  await t.test('открытые сокеты закрыты, и код закрытия — окончательный', async () => {
    const first = await firstTab.waitForClose(IMMEDIATE_BUDGET_MS);
    const second = await secondTab.waitForClose(IMMEDIATE_BUDGET_MS);

    console.log(`  сокет 1 закрыт через ${first.at - revokedAt} мс, код ${first.code}`);
    console.log(`  сокет 2 закрыт через ${second.at - revokedAt} мс, код ${second.code}`);

    for (const closed of [first, second]) {
      assert.ok(
        [4401, 4403].includes(closed.code),
        `ожидался окончательный код 4401 или 4403, получен ${closed.code}: ` +
          'на любом другом клиент начнёт переподключаться и будет молотить сервер',
      );
      assert.ok(
        closed.at - revokedAt < IMMEDIATE_BUDGET_MS,
        `сокет закрылся через ${closed.at - revokedAt} мс — это не «немедленно» (US-09)`,
      );
    }
  });

  await t.test('заново открыть сокет с погашенной сессией нельзя', async () => {
    const result = await realtimeHandshake({
      token: leaver.session.token,
      label: 'после отзыва',
    });
    assert.equal(result.opened, false, 'рукопожатие с погашенной сессией должно отклоняться');
  });

  await t.test('сессии помечены погашенными в базе, а не только в кэше', async () => {
    for (const id of [leaver.session.id, otherTab.session.id]) {
      const row = await sessionRow(id);
      assert.ok(row.revoked_at, `сессия ${id} не помечена отозванной в PostgreSQL`);
    }
  });

  await t.test('возврат адреса в список доступа не воскрешает старую сессию', async () => {
    await owner.api.post('/access-entries', { email: leaver.email }).then((r) => r.expect(201));

    const response = await leaver.api.get('/me');
    assert.equal(response.status, 401, 'вернувшийся обязан войти заново, а не продолжить сессию');
  });

  await t.test('данные и членство в проектах отзыв не трогает (D-40)', async () => {
    const restored = await issueSession(leaver.id, 'cookie');
    const client = new ApiClient({ token: restored.token, label: 'вернувшийся' });

    const asOwner = await client.get(`/projects/${project.slug}`).then((r) => r.expect(200));
    assert.equal(asOwner.role, 'admin', 'членство в проекте сохранилось');

    const restoredIssue = await client.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.equal(restoredIssue.key, issue.key, 'задачи на месте');
  });
});

test('выход из трекера гасит сессию и закрывает её сокет', async (t) => {
  const actor = await signIn({ displayName: 'Выходящий' });
  const other = await anotherSession(actor);

  const socket = await actor.openSocket('вкладка выходящего');
  t.after(() => actor.closeSockets());

  let loggedOutAt;

  await t.test('выход отвечает объявленным кодом', async () => {
    loggedOutAt = Date.now();
    const response = await actor.api.post('/auth/logout');
    assert.equal(response.status, 204, `выход должен отвечать 204, получено ${response.status}`);
  });

  await t.test('вышедшая сессия больше не действует', async () => {
    const response = await actor.api.get('/me');
    assert.equal(response.status, 401);
    assert.equal(response.code, 'session_expired');
  });

  await t.test('сокет вышедшей сессии закрыт окончательным кодом', async () => {
    const closed = await socket.waitForClose(IMMEDIATE_BUDGET_MS);
    console.log(`  сокет закрыт через ${closed.at - loggedOutAt} мс, код ${closed.code}`);
    assert.ok(
      [4401, 4403].includes(closed.code),
      `ожидался 4401 или 4403, получен ${closed.code}`,
    );
  });

  await t.test('выход гасит только свою сессию, другие вкладки живут', async () => {
    // Выход — это выход из одной сессии (US-03), а не отзыв доступа (US-09).
    const response = await other.api.get('/me');
    assert.equal(
      response.status,
      200,
      'вторая вкладка того же человека не должна гаснуть при выходе из первой',
    );
  });
});

test('истёкшая сессия не пускает ни в HTTP, ни в сокет', async (t) => {
  const actor = await signIn({ displayName: 'Просроченный' });
  const expired = await issueSession(actor.id, 'cookie', { ttlSeconds: -60 });
  const client = new ApiClient({ token: expired.token, label: 'просроченная сессия' });

  await t.test('HTTP отвечает 401', async () => {
    const response = await client.get('/me');
    assert.equal(response.status, 401);
    assert.equal(response.code, 'session_expired');
  });

  await t.test('рукопожатие сокета отклоняется', async () => {
    const result = await realtimeHandshake({ token: expired.token, label: 'просроченная' });
    assert.equal(result.opened, false);
  });
});

test('подделка секрета сессии не проходит', async (t) => {
  const actor = await signIn({ displayName: 'Жертва подделки' });
  const [id, verifier] = actor.session.token.split('.');

  const cases = [
    ['чужой верификатор при верном идентификаторе', `${id}.${'A'.repeat(43)}`],
    ['верный верификатор при чужом идентификаторе', `00000000-0000-4000-8000-000000000000.${verifier}`],
    ['мусор вместо токена', 'complete-nonsense'],
    ['пустая строка', ''],
    ['верификатор без идентификатора', verifier],
    // Кириллица в cookie передаётся только процентным кодированием — так её отправил бы
    // и браузер. Разбор токена обязан отклонить её, а не упасть на декодировании.
    ['процентно-закодированная кириллица', encodeURIComponent('полная-ерунда')],
    ['идентификатор с инъекцией вместо uuid', `' or 1=1 --.${verifier}`],
  ];

  for (const [name, token] of cases) {
    await t.test(name, async () => {
      const client = new ApiClient({ token, label: name });
      const response = await client.get('/me');
      assert.equal(response.status, 401, `${name}: ожидался 401`);
    });
  }

  await t.test('настоящий токен по-прежнему работает', async () => {
    await actor.api.get('/me').then((r) => r.expect(200));
  });
});

test('владелец трекера не может отозвать доступ сам у себя и не может остаться никем', async (t) => {
  const owner = await instanceOwner();

  await t.test('своя запись не удаляется (иначе список доступа некому вести)', async () => {
    const entry = await accessEntryFor(owner, owner.email);
    const response = await owner.api.delete(`/access-entries/${entry.id}`);
    assert.equal(response.status, 409);
    assert.equal(response.code, 'cannot_revoke_self');
  });

  await t.test('обычный пользователь к списку доступа не допускается', async () => {
    const plain = await signIn({ displayName: 'Обычный пользователь' });

    const list = await plain.api.get('/access-entries');
    assert.equal(list.status, 403);
    assert.equal(list.code, 'access_list_forbidden');

    const created = await plain.api.post('/access-entries', { email: 'kto-to@sl-tracker.test' });
    assert.equal(created.status, 403);

    const me = await plain.api.get('/me').then((r) => r.expect(200));
    assert.equal(me.canManageAccessList, false, 'клиент заранее знает, что экрана у него нет');
  });
});

test('отзыв доступа у одного не задевает сессии других', async () => {
  const owner = await instanceOwner();
  const leaver = await signIn({ displayName: 'Уходящий из пары' });
  const stays = await signIn({ displayName: 'Остающийся из пары' });

  await grantTrackerAccess(leaver.email, 'manual');
  const entry = await accessEntryFor(owner, leaver.email);
  await owner.api.delete(`/access-entries/${entry.id}`).then((r) => r.expect(200));

  const gone = await leaver.api.get('/me');
  assert.equal(gone.status, 401);

  const alive = await stays.api.get('/me');
  assert.equal(alive.status, 200, 'сессия постороннего человека не пострадала');
});
