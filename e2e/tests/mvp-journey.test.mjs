import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { anonymous } from '../lib/api.mjs';
import { closeDb, grantTrackerAccess, sessionRow } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import {
  createProject,
  createQueue,
  freshQueueKey,
  inviteAndAccept,
  signIn,
  tokenFromInvitationUrl,
} from '../lib/actors.mjs';
import { OWNER_EMAIL } from '../lib/config.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/** Токен упоминания из `apps/api/src/mentions/mention-token.ts`. */
const mention = (user) => `@[${user.displayName}](user:${user.id})`;

/**
 * Критерий готовности MVP из `docs/product/vision.md`, раздел 4, целиком и по порядку.
 *
 * Это не набор независимых проверок, а одна история: каждый шаг работает с состоянием,
 * которое оставил предыдущий. Именно поэтому он живёт здесь, а не в e2e бэкенда —
 * там каждый тест поднимает своё состояние сам, и разрыв между шагами не виден.
 *
 * Шаги — подтесты: падение на шаге 6 не превращается в «упало всё», а прямо называет,
 * где сценарий разошёлся с ожиданием.
 */
test('критерий готовности MVP: команда из трёх человек проходит сценарий целиком', async (t) => {
  let owner;
  let boris;
  let vera;
  let project;
  let queue;
  let statuses = [];
  let issueKeys = [];
  let heroKey;

  await t.test('1. владелец из списка доступа входит в трекер', async () => {
    owner = await signIn({ displayName: 'Ольга Владелец', email: OWNER_EMAIL, owner: true });
    const me = await owner.api.get('/me').then((r) => r.expect(200));

    assert.equal(me.id, owner.id);
    assert.equal(me.isInstanceOwner, true, 'адрес из ACCESS_LIST_BOOTSTRAP_EMAILS — владелец трекера');
    assert.equal(me.canManageAccessList, true);
  });

  await t.test('2. создаёт проект и становится его администратором', async () => {
    project = await createProject(owner, 'Запуск SL Tracker');

    assert.equal(project.role, 'admin');
    assert.equal(project.memberCount, 1);
    assert.match(project.slug, /^[a-z0-9-]+$/, 'короткое имя пригодно для адреса /projects/<slug>');
  });

  await t.test('3. приглашает двоих по ссылке, и их нет в списке доступа', async () => {
    // Приглашённых в списке доступа нет намеренно: приглашение работает в обход него
    // (ADR-0006, п. 3), иначе нанять человека было бы невозможно.
    boris = await signIn({ displayName: 'Борис Разработчик', grantAccess: false });
    vera = await signIn({ displayName: 'Вера Дизайнер', grantAccess: false });

    const forBoris = await inviteAndAccept(owner, project.slug, boris, 'member');
    assert.equal(forBoris.accepted.projectSlug, project.slug);
    assert.equal(forBoris.accepted.role, 'member');
    assert.equal(forBoris.accepted.alreadyMember, false);

    const forVera = await inviteAndAccept(owner, project.slug, vera, 'member');
    assert.equal(forVera.accepted.role, 'member');

    const members = await owner.api
      .get(`/projects/${project.slug}/members`)
      .then((r) => r.expect(200));
    assert.equal(members.total, 3, 'в проекте владелец и двое приглашённых');
    assert.deepEqual(
      members.items.map((m) => m.role).sort(),
      ['admin', 'member', 'member'],
    );
  });

  await t.test('4. создаёт очередь с пятью статусами из коробки', async () => {
    queue = await createQueue(owner, project.slug, {
      key: freshQueueKey('DEV'),
      name: 'Разработка',
    });
    statuses = [...queue.statuses].sort((a, b) => a.position - b.position);

    assert.equal(statuses.length, 5, 'пять статусов создаются данными при создании очереди');
    assert.equal(statuses[0].category, 'open');
    assert.equal(statuses.at(-1).category, 'done');
  });

  await t.test('5. команда заводит 20 задач, ключи идут подряд и не повторяются', async () => {
    const created = [];
    for (let i = 1; i <= 20; i += 1) {
      const author = [owner, boris, vera][i % 3];
      const issue = await author.api
        .post(`/queues/${queue.key}/issues`, {
          title: `Задача номер ${i}`,
          description: `Описание задачи ${i} в **Markdown**`,
          priority: [0, 30, 50, 70, 100][i % 5],
        })
        .then((r) => r.expect(201));
      created.push(issue);
    }

    issueKeys = created.map((issue) => issue.key);
    heroKey = issueKeys[0];

    assert.equal(new Set(issueKeys).size, 20, 'все ключи различны');
    assert.deepEqual(
      created.map((issue) => Number(issue.key.split('-')[1])),
      Array.from({ length: 20 }, (_, i) => i + 1),
      'номера идут подряд с единицы',
    );

    const list = await boris.api
      .get(`/queues/${queue.key}/issues`, { query: { limit: 50 } })
      .then((r) => r.expect(200));
    assert.equal(list.total, 20);
  });

  await t.test('6. владелец назначает исполнителей', async () => {
    for (const [index, key] of issueKeys.entries()) {
      const assignee = index % 2 === 0 ? boris : vera;
      const updated = await owner.api
        .patch(`/issues/${key}`, { assigneeId: assignee.id })
        .then((r) => r.expect(200));
      assert.equal(updated.assignee.id, assignee.id, `исполнитель ${key}`);
    }

    const borisIssues = await owner.api
      .get(`/queues/${queue.key}/issues`, { query: { assignee: boris.id, limit: 50 } })
      .then((r) => r.expect(200));
    assert.equal(borisIssues.total, 10, 'фильтр по исполнителю отдаёт ровно его задачи');
  });

  await t.test('7. задача проходит все пять статусов, и каждый переход разрешён', async () => {
    for (const status of statuses.slice(1)) {
      const updated = await boris.api
        .patch(`/issues/${heroKey}`, { statusId: status.id })
        .then((r) => r.expect(200));
      assert.equal(updated.status.id, status.id, `переход в статус ${status.key}`);
    }

    const issue = await boris.api.get(`/issues/${heroKey}`).then((r) => r.expect(200));
    assert.equal(issue.status.category, 'done');
  });

  await t.test('8. обсуждение в комментариях с упоминанием коллеги', async () => {
    const comment = await boris.api
      .post(`/issues/${heroKey}/comments`, {
        body: `Готово, посмотри ${mention(vera)} — вопрос по макету.`,
      })
      .then((r) => r.expect(201));

    assert.equal(comment.author.id, boris.id);
    assert.deepEqual(
      comment.mentions.map((m) => m.id),
      [vera.id],
      'упомянутый разобран из токена упоминания',
    );

    const answer = await vera.api
      .post(`/issues/${heroKey}/comments`, { body: 'Смотрю, вернусь с ответом сегодня.' })
      .then((r) => r.expect(201));
    assert.equal(answer.author.id, vera.id);

    const thread = await owner.api.get(`/issues/${heroKey}/comments`).then((r) => r.expect(200));
    assert.equal(thread.total, 2);
    assert.equal(thread.canComment, true);
  });

  await t.test('9. подсказка упоминания предлагает только участников проекта (D-41)', async () => {
    const outsider = await signIn({ displayName: 'Посторонний Пётр' });
    const suggestions = await boris.api
      .get(`/issues/${heroKey}/mention-suggestions`)
      .then((r) => r.expect(200));

    const ids = suggestions.items.map((item) => item.id);
    assert.ok(ids.includes(vera.id), 'участник проекта предлагается');
    assert.ok(!ids.includes(outsider.id), 'состав организации наружу не раскрывается');
  });

  await t.test('10. исполнитель видит активные задачи в сайдбаре и находит их поиском', async () => {
    const sidebar = await boris.api
      .get('/issues/my-active', { query: { limit: 50 } })
      .then((r) => r.expect(200));

    // Задача-герой доведена до «Закрыт» — активной она быть перестала.
    assert.equal(sidebar.total, 9, 'в сайдбаре только активные задачи исполнителя');
    assert.ok(
      !sidebar.items.some((item) => item.key === heroKey),
      'закрытая задача ушла из сайдбара',
    );

    const byTitle = await boris.api
      .get('/issues/my-active', { query: { q: 'номер 3' } })
      .then((r) => r.expect(200));
    assert.ok(byTitle.total >= 1, 'поиск по названию находит задачу');

    const someKey = sidebar.items[0].key;
    const byKey = await boris.api
      .get('/issues/my-active', { query: { q: someKey } })
      .then((r) => r.expect(200));
    assert.deepEqual(
      byKey.items.map((i) => i.key),
      [someKey],
      'поиск по ключу находит ровно её',
    );
  });

  await t.test('11. приходят уведомления о назначении и об упоминании', async () => {
    const borisFeed = await boris.api
      .get('/notifications', { query: { limit: 50 } })
      .then((r) => r.expect(200));
    const borisTypes = new Set(borisFeed.items.map((n) => n.type));
    assert.ok(borisTypes.has('issue_assigned'), 'исполнителю пришло уведомление о назначении');

    const veraFeed = await vera.api
      .get('/notifications', { query: { limit: 50 } })
      .then((r) => r.expect(200));
    const mentionNote = veraFeed.items.find((n) => n.type === 'issue_mentioned');
    assert.ok(mentionNote, 'упомянутому пришло уведомление об упоминании');
    assert.equal(mentionNote.issueKey, heroKey);
    assert.equal(mentionNote.actor.id, boris.id);

    const counter = await vera.api.get('/notifications/unread-count').then((r) => r.expect(200));
    assert.equal(counter.unreadCount, veraFeed.unreadCount);
    assert.ok(counter.unreadCount > 0);

    // Код ответа здесь намеренно не проверяется: расхождение с контрактом (200 против 201)
    // закрыто отдельным тестом в contract-status-codes.test.mjs — DEF-01. Этот шаг
    // проверяет счётчик, и падать он должен только из-за счётчика.
    await vera.api.post(`/notifications/${mentionNote.id}/read`).then((r) => r.expect(200, 201, 204));
    const afterRead = await vera.api.get('/notifications/unread-count').then((r) => r.expect(200));
    assert.equal(
      afterRead.unreadCount,
      counter.unreadCount - 1,
      'счётчик уменьшился ровно на одно',
    );
  });

  await t.test('12. история задачи показывает, кто что и с чего на что менял', async () => {
    const history = await vera.api
      .get(`/issues/${heroKey}/history`, { query: { limit: 50 } })
      .then((r) => r.expect(200));

    const kinds = history.items.flatMap((entry) => entry.changes.map((c) => c.kind));
    assert.ok(kinds.includes('issue_created'), 'создание задачи записано');
    assert.ok(kinds.includes('assignee_changed'), 'смена исполнителя записана');

    const statusChanges = history.items
      .flatMap((entry) => entry.changes)
      .filter((c) => c.kind === 'status_changed');
    assert.equal(statusChanges.length, 4, 'четыре перехода из пяти статусов записаны');
    for (const change of statusChanges) {
      assert.ok(change.oldValue, 'в записи есть значение «с чего»');
      assert.ok(change.newValue, 'в записи есть значение «на что»');
    }

    const actors = new Set(history.items.map((entry) => entry.actor?.id));
    assert.ok(actors.has(owner.id) && actors.has(boris.id), 'автор изменения назван');
  });

  await t.test('13. адрес проекта и ссылка на задачу открываются у коллеги', async () => {
    const asVera = await vera.api.get(`/projects/${project.slug}`).then((r) => r.expect(200));
    assert.equal(asVera.slug, project.slug);
    assert.equal(asVera.role, 'member');

    const issue = await vera.api.get(`/issues/${heroKey}`).then((r) => r.expect(200));
    assert.equal(issue.key, heroKey);
    assert.equal(issue.project.slug, project.slug);

    // Ключ задачи регистронезависим (ADR-0004): ссылка из письма не должна ломаться.
    const lowered = await vera.api
      .get(`/issues/${heroKey.toLowerCase()}`)
      .then((r) => r.expect(200));
    assert.equal(lowered.key, heroKey);
  });

  await t.test('14. владелец добавляет человека в список доступа', async () => {
    const newcomerEmail = `novichok-${Date.now()}@sl-tracker.test`;
    const entry = await owner.api
      .post('/access-entries', { email: newcomerEmail })
      .then((r) => r.expect(201));

    assert.equal(entry.email, newcomerEmail.toLowerCase());
    assert.equal(entry.source, 'manual');
    assert.equal(entry.firstLoginAt, null, 'человек ещё не входил');

    const list = await owner.api
      .get('/access-entries', { query: { q: 'novichok', limit: 20 } })
      .then((r) => r.expect(200));
    assert.ok(list.items.some((item) => item.email === newcomerEmail.toLowerCase()));

    // Повторное добавление того же адреса — 409, а не вторая запись (US-07).
    const again = await owner.api.post('/access-entries', { email: newcomerEmail.toUpperCase() });
    assert.equal(again.status, 409);
    assert.equal(again.code, 'access_entry_exists');
  });

  await t.test('15. отзыв доступа гасит открытую вкладку уходящего', async () => {
    // Вера уходит из компании. До отзыва её вкладка работает.
    await vera.api.get('/me').then((r) => r.expect(200));

    await grantTrackerAccess(vera.email, 'invitation');
    const entries = await owner.api
      .get('/access-entries', { query: { q: vera.email, limit: 10 } })
      .then((r) => r.expect(200));
    const veraEntry = entries.items.find((item) => item.email === vera.email);
    assert.ok(veraEntry, 'адрес уходящего есть в списке доступа');

    const result = await owner.api
      .delete(`/access-entries/${veraEntry.id}`)
      .then((r) => r.expect(200));
    assert.ok(result.revokedSessions >= 1, 'отзыв погасил хотя бы одну живую сессию');

    const afterRevoke = await vera.api.get('/me');
    assert.equal(afterRevoke.status, 401, 'открытая вкладка перестала показывать данные');
    assert.equal(afterRevoke.code, 'session_expired');

    const row = await sessionRow(vera.session.id);
    assert.ok(row.revoked_at, 'сессия помечена погашенной и в базе, а не только в кэше');

    // Данные ушедшего остаются: комментарии и авторство не пропадают (D-40).
    const thread = await owner.api.get(`/issues/${heroKey}/comments`).then((r) => r.expect(200));
    assert.ok(
      thread.items.some((c) => c.author.id === vera.id),
      'комментарии ушедшего остались на месте',
    );
  });
});

test('приглашение отзывается, и по отозванной ссылке в проект не войти', async () => {
  const admin = await signIn({ displayName: 'Администратор проекта' });
  const project = await createProject(admin);
  const guest = await signIn({ displayName: 'Опоздавший гость', grantAccess: false });

  const invitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'member' })
    .then((r) => r.expect(201));
  const token = tokenFromInvitationUrl(invitation.url);

  await admin.api
    .post(`/projects/${project.slug}/invitations/${invitation.id}/revoke`)
    .then((r) => r.expect(200, 204));

  const preview = await guest.api.get(`/invitations/${token}`);
  assert.equal(preview.status, 410);
  assert.equal(preview.code, 'invitation_inactive');

  const accept = await guest.api.post(`/invitations/${token}/accept`);
  assert.equal(accept.status, 410);

  const members = await admin.api
    .get(`/projects/${project.slug}/members`)
    .then((r) => r.expect(200));
  assert.equal(members.total, 1, 'в проекте остался только администратор');
});

test('несуществующее приглашение отвечает 404 без подробностей', async () => {
  const guest = await signIn({ displayName: 'Любопытный' });
  const response = await guest.api.get('/invitations/00000000000000000000000000000000');
  assert.equal(response.status, 404);
  assert.equal(response.code, 'invitation_not_found');
});

test('анонимный запрос не открывает ни проект, ни очередь, ни задачу', async () => {
  const admin = await signIn({ displayName: 'Владелец закрытого проекта' });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Секрет' })
    .then((r) => r.expect(201));

  const client = anonymous();
  for (const path of [`/projects/${project.slug}`, `/queues/${queue.key}`, `/issues/${issue.key}`]) {
    const response = await client.get(path);
    assert.equal(response.status, 401, `${path} без сессии`);
  }
});
