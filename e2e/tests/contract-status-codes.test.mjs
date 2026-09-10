import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { closeDb } from '../lib/db.mjs';
import { closeRedis } from '../lib/redis.mjs';
import { REPO_ROOT } from '../lib/config.mjs';
import { createProject, createQueue, signIn, tokenFromInvitationUrl } from '../lib/actors.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Соответствие живых ответов опубликованному контракту `docs/api/openapi.json`.
 *
 * Проверка появилась здесь, а не в e2e бэкенда, по существу: там ожидаемый код
 * пишется рядом с кодом контроллера и повторяет его реализацию. Расхождение с
 * **опубликованным** контрактом так не ловится, а платит за него генерируемый
 * клиент Flutter: он разбирает ответ по описанию из OpenAPI.
 */
const spec = JSON.parse(readFileSync(resolve(REPO_ROOT, 'docs/api/openapi.json'), 'utf8'));

/** Коды успеха, объявленные в контракте для метода и пути. */
function declaredSuccess(path, method) {
  const operation = spec.paths[path]?.[method.toLowerCase()];
  assert.ok(operation, `в openapi.json нет ${method} ${path}`);
  const codes = Object.keys(operation.responses)
    .map(Number)
    .filter((code) => code >= 200 && code < 300);
  assert.ok(codes.length > 0, `${method} ${path}: в контракте нет ни одного успешного кода`);
  return codes;
}

test('меняющие состояние эндпоинты отвечают тем кодом, который объявлен в OpenAPI', async (t) => {
  const admin = await signIn({ displayName: 'Автор контрактной проверки' });
  const project = await createProject(admin);
  const queue = await createQueue(admin, project.slug);
  const guest = await signIn({ displayName: 'Гость контрактной проверки', grantAccess: false });

  const issue = await admin.api
    .post(`/queues/${queue.key}/issues`, { title: 'Задача для проверки кодов' })
    .then((r) => r.expect(201));

  // Уведомление, которое можно пометить прочитанным: назначение исполнителем.
  const invitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'member' })
    .then((r) => r.expect(201));
  await guest.api
    .post(`/invitations/${tokenFromInvitationUrl(invitation.url)}/accept`)
    .then((r) => r.expect(200));
  await admin.api.patch(`/issues/${issue.key}`, { assigneeId: guest.id }).then((r) => r.expect(200));

  const feed = await guest.api.get('/notifications').then((r) => r.expect(200));
  const notificationId = feed.items[0]?.id;
  assert.ok(notificationId, 'подготовка: уведомление о назначении должно существовать');

  const secondInvitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'reader' })
    .then((r) => r.expect(201));

  const cases = [
    {
      name: 'POST /api/notifications/{id}/read',
      path: '/api/notifications/{id}/read',
      method: 'POST',
      call: () => guest.api.post(`/notifications/${notificationId}/read`),
    },
    {
      name: 'POST /api/notifications/read-all',
      path: '/api/notifications/read-all',
      method: 'POST',
      call: () => guest.api.post('/notifications/read-all'),
    },
    {
      name: 'POST /api/invitations/{token}/accept',
      path: '/api/invitations/{token}/accept',
      method: 'POST',
      call: () => guest.api.post(`/invitations/${tokenFromInvitationUrl(invitation.url)}/accept`),
    },
    {
      name: 'POST /api/projects/{slug}/invitations/{id}/revoke',
      path: '/api/projects/{slug}/invitations/{id}/revoke',
      method: 'POST',
      call: () =>
        admin.api.post(`/projects/${project.slug}/invitations/${secondInvitation.id}/revoke`),
    },
    {
      name: 'PUT /api/notifications/settings',
      path: '/api/notifications/settings',
      method: 'PUT',
      call: () =>
        admin.api.put('/notifications/settings', {
          items: [{ type: 'issue_assigned', channel: 'in_app', enabled: true }],
        }),
    },
    {
      name: 'PUT /api/projects/{slug}/slug',
      path: '/api/projects/{slug}/slug',
      method: 'PUT',
      call: () => admin.api.put(`/projects/${project.slug}/slug`, { slug: `pereimenovan-${Date.now()}` }),
    },
  ];

  for (const testCase of cases) {
    await t.test(testCase.name, async () => {
      const declared = declaredSuccess(testCase.path, testCase.method);
      const response = await testCase.call();
      assert.ok(
        declared.includes(response.status),
        `контракт обещает ${declared.join('/')}, сервер ответил ${response.status}. ` +
          `Тело: ${JSON.stringify(response.body)}`,
      );
    });
  }
});

test('удаление участника и записи доступа отвечает объявленным кодом', async (t) => {
  const admin = await signIn({ displayName: 'Администратор удаления' });
  const project = await createProject(admin);
  const guest = await signIn({ displayName: 'Исключаемый', grantAccess: false });

  const invitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'member' })
    .then((r) => r.expect(201));
  await guest.api
    .post(`/invitations/${tokenFromInvitationUrl(invitation.url)}/accept`)
    .then((r) => r.expect(200));

  await t.test('DELETE /api/projects/{slug}/members/{userId}', async () => {
    const declared = declaredSuccess('/api/projects/{slug}/members/{userId}', 'DELETE');
    const response = await admin.api.delete(`/projects/${project.slug}/members/${guest.id}`);
    assert.ok(
      declared.includes(response.status),
      `контракт обещает ${declared.join('/')}, сервер ответил ${response.status}`,
    );
  });

  await t.test('DELETE /api/projects/{slug}', async () => {
    const declared = declaredSuccess('/api/projects/{slug}', 'DELETE');
    const response = await admin.api.delete(`/projects/${project.slug}`);
    assert.ok(
      declared.includes(response.status),
      `контракт обещает ${declared.join('/')}, сервер ответил ${response.status}`,
    );
  });
});
