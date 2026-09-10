import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import { closeDb } from '../lib/db.mjs';
import { closeRedis, resetRateLimits } from '../lib/redis.mjs';
import { createProject, signIn, tokenFromInvitationUrl } from '../lib/actors.mjs';

after(async () => {
  await closeDb();
  await closeRedis();
});

/**
 * Ограничение частоты запросов.
 *
 * Харнесс сбрасывает эти счётчики между сценариями (`lib/redis.mjs`), иначе прогон
 * с одного адреса упирается в лимит. Поэтому проверка того, что ограничение вообще
 * работает, обязана существовать отдельно — иначе его можно было бы выключить совсем,
 * и ни один тест этого бы не заметил.
 */

test('приём приглашений ограничен по частоте и сообщает, когда повторить', async (t) => {
  const admin = await signIn({ displayName: 'Администратор лимита' });
  const guest = await signIn({ displayName: 'Слишком настойчивый', grantAccess: false });
  const project = await createProject(admin, 'Проект ограничения частоты');

  const invitation = await admin.api
    .post(`/projects/${project.slug}/invitations`, { role: 'member' })
    .then((r) => r.expect(201));
  const token = tokenFromInvitationUrl(invitation.url);

  await resetRateLimits('invitation-accept');

  let limited;
  let accepted = 0;

  await t.test('после серии запросов подряд приходит 429', async () => {
    // Предел — 20 запросов в минуту на адрес (invitations.controller.ts).
    for (let i = 0; i < 40; i += 1) {
      const response = await guest.api.post(`/invitations/${token}/accept`);
      if (response.status === 429) {
        limited = response;
        break;
      }
      accepted += 1;
    }

    assert.ok(limited, `ограничение не сработало за 40 запросов подряд (принято ${accepted})`);
    assert.equal(limited.code, 'rate_limited');
    console.log(`  429 пришёл после ${accepted} успешных запросов`);
  });

  await t.test('в ответе есть заголовок retry-after', async () => {
    const retryAfter = limited.headers.get('retry-after');
    assert.ok(retryAfter, 'без retry-after клиент не знает, когда повторять');
    assert.ok(Number(retryAfter) > 0, `retry-after = ${retryAfter}`);
  });

  await t.test('ограничение не выбрасывает из трекера: остальные запросы работают', async () => {
    const me = await guest.api.get('/me').then((r) => r.expect(200));
    assert.equal(me.id, guest.id, 'лимит одного маршрута не должен закрывать приложение целиком');
  });

  await t.test('после сброса счётчика запросы снова проходят', async () => {
    await resetRateLimits('invitation-accept');
    const response = await guest.api.post(`/invitations/${token}/accept`);
    assert.equal(response.status, 200, 'счётчик окном, а не навсегда');
  });
});

test('поиск в сайдбаре ограничен по частоте', async (t) => {
  const actor = await signIn({ displayName: 'Ищущий часто' });
  await resetRateLimits('my-active-issues');

  await t.test('предел в 120 запросов в минуту срабатывает', async () => {
    let limited = null;
    for (let i = 0; i < 200; i += 1) {
      const response = await actor.api.get('/issues/my-active', { query: { q: `поиск ${i}` } });
      if (response.status === 429) {
        limited = { response, at: i };
        break;
      }
    }

    assert.ok(limited, 'ограничение поиска не сработало за 200 запросов');
    assert.equal(limited.response.code, 'rate_limited');
    console.log(`  429 на поиске пришёл после ${limited.at} запросов`);
  });

  await t.test('после сброса счётчика поиск снова работает', async () => {
    await resetRateLimits('my-active-issues');
    await actor.api.get('/issues/my-active').then((r) => r.expect(200));
  });
});
