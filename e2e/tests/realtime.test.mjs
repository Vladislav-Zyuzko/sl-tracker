import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { createProject, createQueue, inviteAndAccept, signIn } from '../lib/actors.mjs';
import { realtimeHandshake } from '../lib/ws.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Требование D-26: изменение задачи, новый комментарий и счётчик непрочитанных
 * появляются у другого пользователя **не позднее чем через 5 секунд** и без
 * перезагрузки страницы.
 *
 * Проверить это можно только двумя настоящими соединениями к живому серверу:
 * ни модульный тест, ни виджет-тест второго клиента не имеют. Задержка измеряется
 * от отправки HTTP-запроса до получения кадра — так, как её видит человек.
 */
const D26_BUDGET_MS = 5000;

/** Проект с очередью, задачей и двумя участниками. */
async function scene() {
  const alice = await signIn({ displayName: 'Алиса (вкладка 1)' });
  const bob = await signIn({ displayName: 'Боб (вкладка 2)', grantAccess: false });
  const project = await createProject(alice, 'Проект живых обновлений');
  const queue = await createQueue(alice, project.slug);
  await inviteAndAccept(alice, project.slug, bob, 'member');
  const issue = await alice.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача для двух вкладок' })
    .then((r) => r.expect(201));
  const statuses = await alice.api.get(`/queues/${queue.key}/statuses`).then((r) => r.expect(200));
  return { alice, bob, project, queue, issue, statuses: statuses.items };
}

test('два клиента одновременно: комментарий и смена статуса доходят за 5 секунд (D-26)', async (t) => {
  const { alice, bob, issue, statuses } = await scene();
  const watcher = await bob.openSocket('вкладка Боба');

  t.after(() => {
    alice.closeSockets();
    bob.closeSockets();
  });

  await t.test('после открытия сервер сам подписывает на свои уведомления', async () => {
    const ready = watcher.frames.find((frame) => frame.type === 'ready');
    assert.ok(ready, 'кадр ready получен');
    assert.deepEqual(ready.topics, ['user:me'], 'подписка на свои уведомления выдана без запроса');
    assert.equal(ready.heartbeatSeconds, 30);
    assert.equal(ready.maxTopics, 20);
  });

  let canonicalTopic;

  await t.test('подписка на задачу возвращает канонический ярлык темы', async () => {
    // Клиент подписывается по ключу в нижнем регистре — ключ регистронезависим (ADR-0004).
    canonicalTopic = await watcher.subscribe(`issue:${issue.key.toLowerCase()}`);
    assert.equal(canonicalTopic, `issue:${issue.key}`, 'сервер вернул канонический вид темы');
  });

  await t.test('чужой комментарий доходит до второй вкладки за 5 секунд', async () => {
    watcher.clear();
    const sentAt = Date.now();

    const comment = await alice.api
      .post(`/issues/${issue.key}/comments`, { body: 'Первый комментарий из другой вкладки' })
      .then((r) => r.expect(201));

    const frame = await watcher.waitForEvent('comment.created', {
      topic: canonicalTopic,
      timeoutMs: D26_BUDGET_MS,
    });

    const latency = frame.receivedAt - sentAt;
    console.log(`  задержка comment.created: ${latency} мс`);
    assert.ok(latency < D26_BUDGET_MS, `${latency} мс не укладывается в бюджет D-26`);
    assert.equal(frame.data.id, comment.id, 'событие указывает на созданный комментарий');
    assert.equal(frame.data.issueKey, issue.key);
    assert.equal(frame.actorId, alice.id, 'назван тот, кто вызвал событие');
  });

  await t.test('смена статуса доходит до второй вкладки за 5 секунд', async () => {
    watcher.clear();
    const sentAt = Date.now();

    await alice.api
      .patch(`/issues/${issue.key}`, { statusId: statuses[1].id })
      .then((r) => r.expect(200));

    const frame = await watcher.waitForEvent('issue.updated', {
      topic: canonicalTopic,
      timeoutMs: D26_BUDGET_MS,
    });

    const latency = frame.receivedAt - sentAt;
    console.log(`  задержка issue.updated: ${latency} мс`);
    assert.ok(latency < D26_BUDGET_MS, `${latency} мс не укладывается в бюджет D-26`);
    assert.deepEqual(frame.data.changedFields, ['status'], 'названо изменившееся поле');
    assert.equal(frame.data.key, issue.key);
  });

  await t.test('счётчик непрочитанных приходит в теме своих уведомлений', async () => {
    watcher.clear();
    const sentAt = Date.now();

    await alice.api.patch(`/issues/${issue.key}`, { assigneeId: bob.id }).then((r) => r.expect(200));

    const frame = await watcher.waitForEvent('notification.created', {
      topic: 'user:me',
      timeoutMs: D26_BUDGET_MS,
    });

    const latency = frame.receivedAt - sentAt;
    console.log(`  задержка notification.created: ${latency} мс`);
    assert.ok(latency < D26_BUDGET_MS, `${latency} мс не укладывается в бюджет D-26`);
    assert.equal(frame.data.type, 'issue_assigned');
    assert.ok(frame.data.unreadCount > 0, 'счётчик пришёл вместе с событием');

    const http = await bob.api.get('/notifications/unread-count').then((r) => r.expect(200));
    assert.equal(
      frame.data.unreadCount,
      http.unreadCount,
      'счётчик из события совпадает с тем, что отдаёт HTTP',
    );
  });

  await t.test('своё действие возвращается инициатору с его же actorId', async () => {
    const own = await alice.openSocket('вкладка Алисы');
    await own.subscribe(`issue:${issue.key}`);
    own.clear();

    await alice.api
      .post(`/issues/${issue.key}/comments`, { body: 'Свой комментарий' })
      .then((r) => r.expect(201));

    const frame = await own.waitForEvent('comment.created', { timeoutMs: D26_BUDGET_MS });
    assert.equal(frame.actorId, alice.id, 'по actorId клиент отличает своё действие от чужого');
  });

  await t.test('прочтение в другой вкладке гасит счётчик в первой', async () => {
    const secondTab = await bob.openSocket('вторая вкладка Боба');
    secondTab.clear();

    await bob.api.post('/notifications/read-all');

    const frame = await secondTab.waitForEvent('notification.read', {
      topic: 'user:me',
      timeoutMs: D26_BUDGET_MS,
    });
    assert.equal(frame.data.unreadCount, 0, 'счётчик обнулился во всех вкладках');
  });
});

test('рукопожатие живых обновлений закрыто ровно так же, как HTTP', async (t) => {
  const actor = await signIn({ displayName: 'Проверяющий рукопожатие' });

  await t.test('без сессии соединение не открывается вовсе', async () => {
    const result = await realtimeHandshake({ token: undefined, label: 'без сессии' });
    assert.equal(result.opened, false, 'сокет не должен открыться');
    assert.match(result.error, /401/, `ожидался отказ 401, получено: ${result.error}`);
  });

  await t.test('с чужим Origin соединение не открывается (cross-site hijacking)', async () => {
    const result = await realtimeHandshake({
      token: actor.session.token,
      origin: 'https://evil.example',
      label: 'чужой Origin',
    });
    assert.equal(result.opened, false, 'сокет с чужого сайта не должен открыться');
    assert.match(result.error, /401|403/, `ожидался отказ, получено: ${result.error}`);
  });

  await t.test('с мусорным токеном соединение не открывается', async () => {
    const result = await realtimeHandshake({ token: 'not-a-session', label: 'мусорный токен' });
    assert.equal(result.opened, false);
  });

  await t.test('с действующей сессией соединение открывается', async () => {
    const socket = await actor.openSocket();
    assert.ok(socket, 'сокет открыт');
    actor.closeSockets();
  });
});

test('темы: чужая недоступна, своя чужая — не тема вовсе', async (t) => {
  const alice = await signIn({ displayName: 'Хозяйка темы' });
  const stranger = await signIn({ displayName: 'Посторонний подписчик' });
  const project = await createProject(alice);
  const queue = await createQueue(alice, project.slug);
  const issue = await alice.api
    .post(`/queues/${queue.key}/issues`, { title: 'Закрытая задача' })
    .then((r) => r.expect(201));

  const socket = await stranger.openSocket('посторонний');
  t.after(() => stranger.closeSockets());

  await t.test('чужая задача — topic_forbidden, а не отказ с подробностями', async () => {
    const frame = await socket.trySubscribe(`issue:${issue.key}`);
    assert.equal(frame.type, 'error');
    assert.equal(frame.code, 'topic_forbidden');
  });

  await t.test('несуществующая задача отвечает так же, как чужая', async () => {
    const frame = await socket.trySubscribe('issue:NETU-999999');
    assert.equal(frame.type, 'error');
    assert.equal(
      frame.code,
      'topic_forbidden',
      'по ответу нельзя узнать, существует ли задача (permissions §5)',
    );
  });

  await t.test('чужой проект — topic_forbidden', async () => {
    const frame = await socket.trySubscribe(`project:${project.slug}`);
    assert.equal(frame.type, 'error');
    assert.equal(frame.code, 'topic_forbidden');
  });

  await t.test('чужая тема пользователя не принимается вовсе', async () => {
    const frame = await socket.trySubscribe(`user:${alice.id}`);
    assert.equal(frame.type, 'error');
    assert.equal(frame.code, 'invalid_topic', 'это не отказ в праве, а нераспознанная тема');
  });

  await t.test('ошибка команды не закрывает соединение', async () => {
    const frame = await socket.trySubscribe('и вовсе не тема');
    assert.equal(frame.type, 'error');
    assert.equal(socket.closed, null, 'сокет остался жив после отклонённой команды');

    socket.send({ type: 'ping', id: 'жив' });
    const pong = await socket.waitFor((f) => f.type === 'pong' && f.id === 'жив');
    assert.ok(pong, 'соединение продолжает работать');
  });

  await t.test('неизвестная команда отклоняется, но не рвёт связь', async () => {
    socket.send({ type: 'сделай-хорошо', id: 'x1' });
    const frame = await socket.waitFor((f) => f.type === 'error' && f.id === 'x1');
    assert.equal(frame.code, 'unknown_command');
    assert.equal(socket.closed, null);
  });

  await t.test('не-JSON отклоняется как invalid_message', async () => {
    socket.socket.send('это не json');
    const frame = await socket.waitFor((f) => f.type === 'error' && f.code === 'invalid_message');
    assert.ok(frame);
    assert.equal(socket.closed, null);
  });
});

test('исключение из проекта отбирает подписку у уже открытого сокета', async (t) => {
  const { alice, bob, project, issue } = await scene();
  const socket = await bob.openSocket('вкладка исключаемого');
  t.after(() => bob.closeSockets());

  await socket.subscribe(`issue:${issue.key}`);

  await t.test('до исключения события приходят', async () => {
    socket.clear();
    await alice.api
      .post(`/issues/${issue.key}/comments`, { body: 'Пока ещё участник' })
      .then((r) => r.expect(201));
    await socket.waitForEvent('comment.created', { timeoutMs: D26_BUDGET_MS });
  });

  await t.test('после исключения вместо события приходит topic_forbidden', async () => {
    await alice.api
      .delete(`/projects/${project.slug}/members/${bob.id}`)
      .then((r) => r.expect(200));

    socket.clear();
    await alice.api
      .post(`/issues/${issue.key}/comments`, { body: 'Уже без него' })
      .then((r) => r.expect(201));

    const frame = await socket.waitFor(
      (f) => f.type === 'error' && f.code === 'topic_forbidden',
      { timeoutMs: D26_BUDGET_MS, what: 'снятие подписки при рассылке' },
    );
    assert.ok(frame, 'право проверяется заново при каждой рассылке');

    const leaked = socket.frames.find((f) => f.type === 'event' && f.event === 'comment.created');
    assert.equal(leaked, undefined, 'само событие до исключённого не дошло');
  });
});

test('предел тем на соединение объявлен в ready и соблюдается', async (t) => {
  const actor = await signIn({ displayName: 'Жадный до тем' });
  const project = await createProject(actor);
  const queue = await createQueue(actor, project.slug);

  const socket = await actor.openSocket('много тем');
  t.after(() => actor.closeSockets());

  const ready = socket.frames.find((f) => f.type === 'ready');
  const limit = ready.maxTopics;

  // Тема user:me выдана сервером и уже занимает место, поэтому своих тем помещается
  // на одну меньше — иначе предел означал бы разное для разных соединений.
  const keys = [];
  for (let i = 0; i < limit; i += 1) {
    const issue = await actor.api
      .post(`/queues/${queue.key}/issues`, { title: `Тема ${i}` })
      .then((r) => r.expect(201));
    keys.push(issue.key);
  }

  let accepted = 0;
  let refusal;
  for (const key of keys) {
    const frame = await socket.trySubscribe(`issue:${key}`);
    if (frame.type === 'subscribed') {
      accepted += 1;
    } else {
      refusal = frame;
      break;
    }
  }

  console.log(`  принято тем: ${accepted} при пределе ${limit}`);
  assert.ok(refusal, `сверх предела ${limit} подписка должна отклоняться`);
  assert.equal(refusal.code, 'too_many_topics');
  assert.ok(accepted <= limit, 'принято не больше объявленного предела');
});
