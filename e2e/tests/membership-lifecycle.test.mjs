import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { createProject, createQueue, inviteAndAccept, signIn } from '../lib/actors.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Жизненный цикл участия в проекте — от приглашения до исключения.
 *
 * Это ровно тот класс ошибок, который модульные тесты не ловят: каждый шаг по
 * отдельности корректен, ломается **состояние между шагами**. Исключённый участник
 * должен исчезнуть сразу отовсюду: из состава, из исполнителей, из своего сайдбара,
 * из подписки на уведомления, из видимости проекта, — и при этом его задачи,
 * комментарии и авторство обязаны остаться (D-31, Q9).
 */
test('приглашение → участие → назначение → исключение: состояние согласовано на каждом шаге', async (t) => {
  const admin = await signIn({ displayName: 'Анна Администратор' });
  const worker = await signIn({ displayName: 'Виктор Исполнитель', grantAccess: false });

  const project = await createProject(admin, 'Проект жизненного цикла');
  const queue = await createQueue(admin, project.slug);
  let issue;
  let secondIssue;

  await t.test('до принятия приглашения проект для человека не существует', async () => {
    const response = await worker.api.get(`/projects/${project.slug}`);
    assert.equal(response.status, 404, 'не-участник не должен узнать о существовании проекта');
  });

  await t.test('принял приглашение — появился в участниках с выданной ролью', async () => {
    const { accepted } = await inviteAndAccept(admin, project.slug, worker, 'member');
    assert.equal(accepted.role, 'member');

    const members = await admin.api
      .get(`/projects/${project.slug}/members`)
      .then((r) => r.expect(200));
    const row = members.items.find((m) => m.userId === worker.id);
    assert.ok(row, 'приглашённый есть в составе');
    assert.equal(row.role, 'member');

    const asWorker = await worker.api.get(`/projects/${project.slug}`).then((r) => r.expect(200));
    assert.equal(asWorker.role, 'member', 'проект открылся у приглашённого');
  });

  await t.test('повторное принятие того же приглашения не создаёт второго членства', async () => {
    const invitation = await admin.api
      .post(`/projects/${project.slug}/invitations`, { role: 'reader' })
      .then((r) => r.expect(201));
    const token = new URL(invitation.url).pathname.split('/').filter(Boolean).at(-1);

    const again = await worker.api.post(`/invitations/${token}/accept`).then((r) => r.expect(200));
    assert.equal(again.alreadyMember, true, 'сервер сообщает, что человек уже в проекте');

    const members = await admin.api
      .get(`/projects/${project.slug}/members`)
      .then((r) => r.expect(200));
    assert.equal(members.total, 2, 'состав не удвоился');

    const row = members.items.find((m) => m.userId === worker.id);
    assert.equal(row.role, 'member', 'принятие приглашения не понижает уже выданную роль');
  });

  await t.test('назначен исполнителем — задача появилась в его сайдбаре', async () => {
    issue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Починить вход' })
      .then((r) => r.expect(201));
    secondIssue = await admin.api
      .post(`/queues/${queue.key}/issues`, { title: 'Обновить документацию' })
      .then((r) => r.expect(201));

    for (const key of [issue.key, secondIssue.key]) {
      await admin.api.patch(`/issues/${key}`, { assigneeId: worker.id }).then((r) => r.expect(200));
    }

    const sidebar = await worker.api.get('/issues/my-active').then((r) => r.expect(200));
    assert.deepEqual(
      sidebar.items.map((i) => i.key).sort(),
      [issue.key, secondIssue.key].sort(),
      'обе назначенные задачи видны в сайдбаре исполнителя',
    );
  });

  await t.test('исполнителю пришло уведомление о назначении', async () => {
    const feed = await worker.api.get('/notifications').then((r) => r.expect(200));
    const assigned = feed.items.filter((n) => n.type === 'issue_assigned');
    assert.equal(assigned.length, 2, 'по уведомлению на каждое назначение');
    assert.equal(assigned[0].actor.id, admin.id, 'в уведомлении назван тот, кто назначил');
  });

  await t.test('исполнитель комментирует — комментарий появляется в ленте', async () => {
    await worker.api
      .post(`/issues/${issue.key}/comments`, { body: 'Взял в работу, вопросов нет.' })
      .then((r) => r.expect(201));

    const thread = await admin.api.get(`/issues/${issue.key}/comments`).then((r) => r.expect(200));
    assert.equal(thread.total, 1);
    assert.equal(thread.items[0].author.id, worker.id);
  });

  await t.test('исключение из проекта возвращает число обнулённых задач', async () => {
    const result = await admin.api
      .delete(`/projects/${project.slug}/members/${worker.id}`)
      .then((r) => r.expect(200));
    assert.equal(result.unassignedIssues, 2, 'обе задачи исключённого освобождены');
  });

  await t.test('задача осталась, исполнитель обнулён (D-31)', async () => {
    const after = await admin.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.equal(after.key, issue.key, 'задача не удалена вместе с участником');
    assert.equal(after.assignee, null, 'исполнитель очищен');
    assert.equal(after.title, 'Починить вход', 'остальные поля не тронуты');
  });

  await t.test('в историю задачи записано обнуление исполнителя', async () => {
    const history = await admin.api
      .get(`/issues/${issue.key}/history`, { query: { limit: 50 } })
      .then((r) => r.expect(200));

    const changes = history.items.flatMap((entry) => entry.changes);
    const cleared = changes.filter((c) => c.kind === 'assignee_changed' && c.newValue === null);
    assert.equal(
      cleared.length,
      1,
      'обнуление исполнителя при исключении — отдельная запись истории ' +
        `(записи assignee_changed: ${JSON.stringify(
          changes.filter((c) => c.kind === 'assignee_changed'),
        )})`,
    );
  });

  await t.test('комментарии и авторство исключённого остались (Q9)', async () => {
    const thread = await admin.api.get(`/issues/${issue.key}/comments`).then((r) => r.expect(200));
    assert.equal(thread.total, 1, 'комментарий не удалён вместе с участником');
    assert.equal(thread.items[0].author.id, worker.id, 'авторство сохранено');
    assert.equal(thread.items[0].author.displayName, worker.displayName, 'имя автора читается');
  });

  await t.test('исключённый больше не видит ни проект, ни очередь, ни задачу', async () => {
    for (const path of [
      `/projects/${project.slug}`,
      `/queues/${queue.key}`,
      `/issues/${issue.key}`,
      `/issues/${issue.key}/comments`,
      `/issues/${issue.key}/history`,
    ]) {
      const response = await worker.api.get(path);
      assert.equal(response.status, 404, `${path} для исключённого — 404, а не 403 (permissions §5)`);
    }
  });

  await t.test('сайдбар исключённого опустел', async () => {
    const sidebar = await worker.api.get('/issues/my-active').then((r) => r.expect(200));
    assert.equal(sidebar.total, 0, 'задачи чужого проекта из сайдбара ушли');
  });

  await t.test('исключённый не может ни комментировать, ни менять задачу', async () => {
    const comment = await worker.api.post(`/issues/${issue.key}/comments`, { body: 'Ещё тут?' });
    assert.equal(comment.status, 404);

    const patch = await worker.api.patch(`/issues/${issue.key}`, { title: 'Перехват' });
    assert.equal(patch.status, 404);
  });

  await t.test('новых уведомлений исключённому не приходит', async () => {
    const before = await worker.api.get('/notifications').then((r) => r.expect(200));

    // Событие, которое раньше его касалось: комментарий в задаче, где он комментировал.
    await admin.api
      .post(`/issues/${issue.key}/comments`, { body: 'Продолжаем без него.' })
      .then((r) => r.expect(201));
    // И смена статуса — второй повод для уведомления.
    const statuses = await admin.api
      .get(`/queues/${queue.key}/statuses`)
      .then((r) => r.expect(200));
    await admin.api
      .patch(`/issues/${issue.key}`, { statusId: statuses.items[1].id })
      .then((r) => r.expect(200));

    const after = await worker.api.get('/notifications').then((r) => r.expect(200));
    assert.equal(after.total, before.total, 'подписка на задачу прекратилась вместе с участием');
  });

  await t.test('старые уведомления исключённого не ломают ленту и открываются', async () => {
    const feed = await worker.api.get('/notifications').then((r) => r.expect(200));
    assert.ok(feed.items.length > 0, 'история уведомлений не стёрта');
    // Помечать прочитанным по-прежнему можно: строка своя, даже если проект уже чужой.
    const response = await worker.api.post(`/notifications/${feed.items[0].id}/read`);
    assert.ok([200, 201].includes(response.status), `неожиданный код ${response.status}`);
  });
});

test('последнего администратора нельзя ни разжаловать, ни исключить', async (t) => {
  const admin = await signIn({ displayName: 'Единственный администратор' });
  const project = await createProject(admin);

  await t.test('разжалование последнего администратора — 409', async () => {
    const response = await admin.api.patch(`/projects/${project.slug}/members/${admin.id}`, {
      role: 'member',
    });
    assert.equal(response.status, 409);
    assert.equal(response.code, 'last_project_admin');
  });

  await t.test('исключение последнего администратора — 409', async () => {
    const response = await admin.api.delete(`/projects/${project.slug}/members/${admin.id}`);
    assert.equal(response.status, 409);
    assert.equal(response.code, 'last_project_admin');
  });

  await t.test('после появления второго администратора первый может уйти', async () => {
    const second = await signIn({ displayName: 'Второй администратор', grantAccess: false });
    await inviteAndAccept(admin, project.slug, second, 'member');
    await admin.api
      .patch(`/projects/${project.slug}/members/${second.id}`, { role: 'admin' })
      .then((r) => r.expect(200));

    await admin.api.delete(`/projects/${project.slug}/members/${admin.id}`).then((r) => r.expect(200));

    const members = await second.api
      .get(`/projects/${project.slug}/members`)
      .then((r) => r.expect(200));
    assert.deepEqual(members.items.map((m) => m.userId), [second.id]);

    const gone = await admin.api.get(`/projects/${project.slug}`);
    assert.equal(gone.status, 404, 'ушедший администратор проект больше не видит');
  });
});

test('смена роли на «читатель» немедленно закрывает право создавать', async (t) => {
  const admin = await signIn({ displayName: 'Администратор ролей' });
  const worker = await signIn({ displayName: 'Понижаемый', grantAccess: false });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  await inviteAndAccept(admin, project.slug, worker, 'member');

  const issue = await worker.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача до понижения' })
    .then((r) => r.expect(201));

  await t.test('понижение до читателя', async () => {
    const updated = await admin.api
      .patch(`/projects/${project.slug}/members/${worker.id}`, { role: 'reader' })
      .then((r) => r.expect(200));
    assert.equal(updated.role, 'reader');
  });

  await t.test('читатель видит задачу, но ничего не создаёт и не меняет (D-29)', async () => {
    const visible = await worker.api.get(`/issues/${issue.key}`).then((r) => r.expect(200));
    assert.equal(visible.role, 'reader');
    assert.equal(visible.permissions.canEdit, false, 'клиенту сказано, что править нельзя');

    const created = await worker.api.post(`/queues/${queue.key}/issues`, { title: 'Нельзя' });
    assert.equal(created.status, 403, 'читатель не создаёт задачи');
    assert.equal(created.code, 'issue_forbidden');

    const patched = await worker.api.patch(`/issues/${issue.key}`, { title: 'Тоже нельзя' });
    assert.equal(patched.status, 403);

    const commented = await worker.api.post(`/issues/${issue.key}/comments`, { body: 'Нельзя' });
    assert.equal(commented.status, 403, 'читатель не комментирует (Q7)');
    assert.equal(commented.code, 'comment_forbidden');

    const suggestions = await worker.api.get(`/issues/${issue.key}/mention-suggestions`);
    assert.equal(suggestions.status, 403, 'читатель никого не упоминает');
  });

  await t.test('участник не приглашает и не заводит очередь (D-30)', async () => {
    const promoted = await signIn({ displayName: 'Обычный участник', grantAccess: false });
    await inviteAndAccept(admin, project.slug, promoted, 'member');

    const invitation = await promoted.api.post(`/projects/${project.slug}/invitations`, {
      role: 'member',
    });
    assert.equal(invitation.status, 403);
    assert.equal(invitation.code, 'project_forbidden');

    const queueAttempt = await promoted.api.post(`/projects/${project.slug}/queues`, {
      key: 'NELZYA',
      name: 'Нельзя',
    });
    assert.equal(queueAttempt.status, 403);

    const deletion = await promoted.api.delete(`/projects/${project.slug}`);
    assert.equal(deletion.status, 403);
  });
});
