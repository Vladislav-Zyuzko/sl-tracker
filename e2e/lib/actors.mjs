import { ApiClient } from './api.mjs';
import { createUser, issueSession, makeInstanceOwner, unique } from './db.mjs';
import { openRealtime } from './ws.mjs';
import { resetRateLimits } from './redis.mjs';

/**
 * Действующее лицо сценария: пользователь трекера с живой сессией и своим HTTP-клиентом.
 *
 * Каждый актёр — отдельная сессия, как отдельная вкладка браузера. Это принципиально
 * для сценариев «два клиента одновременно»: общий клиент на всех спрятал бы ровно те
 * ошибки, ради которых сквозные тесты и пишутся.
 */
export class Actor {
  constructor({ user, session, api }) {
    this.id = user.id;
    this.displayName = user.displayName;
    this.email = user.email;
    this.session = session;
    this.api = api;
    this.sockets = [];
  }

  /** Открывает вкладку с живыми обновлениями. Закрывается через `closeSockets`. */
  async openSocket(label = this.displayName) {
    const socket = await openRealtime({ token: this.session.token, label });
    this.sockets.push(socket);
    return socket;
  }

  closeSockets() {
    for (const socket of this.sockets) {
      socket.close();
    }
    this.sockets = [];
  }
}

/** Пользователь + сессия + клиент. `owner: true` даёт глобальную роль владельца трекера. */
export async function signIn({ displayName, email, owner = false, grantAccess = true } = {}) {
  const user = await createUser({ displayName, email, grantAccess });
  if (owner) {
    await makeInstanceOwner(user.email);
  }
  const session = await issueSession(user.id, 'cookie');
  const api = new ApiClient({ token: session.token, label: user.displayName });
  return new Actor({ user, session, api });
}

/** Ещё одна сессия того же человека — вторая вкладка или второе устройство. */
export async function anotherSession(actor, { presentAs = 'cookie' } = {}) {
  const session = await issueSession(actor.id, presentAs === 'bearer' ? 'bearer' : 'cookie');
  return {
    session,
    api: new ApiClient({ token: session.token, label: `${actor.displayName} (2)`, presentAs }),
  };
}

// --- Быстрая сборка сцены ---------------------------------------------------

/** Проект, созданный самим API: короткое имя и роль администратора приходят от сервера. */
export async function createProject(actor, name = `Проект ${unique('p')}`) {
  const project = await actor.api.post('/projects', { name }).then((r) => r.expect(201));
  return project;
}

/** Очередь с пятью статусами по умолчанию. Ключ уникален глобально (ADR-0004). */
export async function createQueue(actor, projectSlug, { key, name } = {}) {
  const queueKey = key ?? freshQueueKey();
  const queue = await actor.api
    .post(`/projects/${projectSlug}/queues`, { key: queueKey, name: name ?? `Очередь ${queueKey}` })
    .then((r) => r.expect(201));
  return queue;
}

/** Ключ очереди, гарантированно свободный: только буквы, до 6 символов. */
export function freshQueueKey(prefix = 'Q') {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let key = prefix.toUpperCase().replace(/[^A-Z]/g, '');
  while (key.length < 6) {
    key += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return key.slice(0, 6);
}

/** Приглашение → принятие. Возвращает результат принятия как его видит сервер. */
export async function inviteAndAccept(admin, projectSlug, guest, role = 'member') {
  // Приём приглашения ограничен 20 запросами в минуту на адрес клиента, а весь прогон
  // идёт с одного адреса. Счётчик сбрасывается, как если бы прошла минута; что само
  // ограничение работает, проверяет tests/rate-limit.test.mjs.
  await resetRateLimits('invitation-accept');
  await resetRateLimits('invitation-preview');

  const invitation = await admin.api
    .post(`/projects/${projectSlug}/invitations`, { role })
    .then((r) => r.expect(201));
  const token = tokenFromInvitationUrl(invitation.url);
  const accepted = await guest.api
    .post(`/invitations/${token}/accept`)
    .then((r) => r.expect(200));
  return { invitation, token, accepted };
}

/** Токен приглашения из выданного сервером адреса `/invite/<token>`. */
export function tokenFromInvitationUrl(url) {
  const parts = new URL(url).pathname.split('/').filter(Boolean);
  return parts[parts.length - 1];
}
