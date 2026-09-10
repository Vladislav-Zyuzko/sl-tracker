import { createHmac, randomBytes, randomUUID } from 'node:crypto';
import pg from 'pg';
import { config } from './config.mjs';

/**
 * Прямой доступ к тестовой базе.
 *
 * Нужен ровно для двух вещей, которых снаружи не сделать:
 *   1) выдать сессию в обход Яндекс ID (см. `issueSession`);
 *   2) проверить то, чего API наружу не отдаёт (например, `sessions.revoked_at`).
 *
 * Всё остальное тесты делают HTTP-запросами: сквозной тест, который лезет в базу
 * вместо эндпоинта, проверяет не продукт, а собственное представление о нём.
 */

const { Pool } = pg;

let pool;

export function db() {
  pool ??= new Pool({ ...config.postgres, max: 20 });
  return pool;
}

export async function closeDb() {
  if (pool) {
    const closing = pool;
    pool = undefined;
    await closing.end();
  }
}

export async function sql(text, params = []) {
  const result = await db().query(text, params);
  return result.rows;
}

/** Полная очистка тестовой базы. Вызывается один раз на прогон, из `run.mjs`. */
export async function truncateAll() {
  await sql(`
    truncate table
      issue_history, mentions, attachments, issue_links, comments, notifications,
      notification_settings, issues, statuses, queues, queue_keys, invitations,
      project_members, projects, project_slugs, sessions, access_entries, identities, users
    restart identity cascade
  `);
}

// --- Сессии -----------------------------------------------------------------

/**
 * Выдаёт действующую сессию, минуя вход через Яндекс ID.
 *
 * Настоящий вход автоматизировать нельзя: он требует живого согласия человека
 * в интерфейсе Яндекса. Обходной путь выбран так, чтобы **не менять продуктовый код**:
 * харнесс пишет строку в `sessions` ровно тем же способом, что и `SessionService.create`.
 *
 * Почему это работает: предъявляемый секрет имеет вид `<id>.<verifier>`, а в базе
 * лежит `HMAC-SHA256(verifier, SESSION_SECRET)` (`apps/api/src/sessions/session-token.ts`).
 * Зная секрет приложения, сессию можно выпустить снаружи. `SessionService.resolve`
 * не найдёт её в Redis, поднимет из PostgreSQL и закэширует — то есть дальше сессия
 * ничем не отличается от выданной входом, включая отзыв через `destroyAllForUser`.
 *
 * Альтернатива — тестовый эндпоинт в API — добавила бы в боевой код путь выдачи сессии
 * без аутентификации. Цена ошибки в нём слишком высока, а выигрыша нет.
 */
export async function issueSession(userId, kind = 'cookie', options = {}) {
  const id = randomUUID();
  const verifier = randomBytes(32).toString('base64url');
  const tokenHash = createHmac('sha256', config.sessionSecret).update(verifier).digest('hex');
  const ttlSeconds = options.ttlSeconds ?? 30 * 24 * 60 * 60;
  const expiresAt = new Date(Date.now() + ttlSeconds * 1000);

  await sql(
    `insert into sessions (id, user_id, kind, token_hash, expires_at, last_seen_at)
     values ($1, $2, $3, $4, $5, now())`,
    [id, userId, kind, tokenHash, expiresAt],
  );

  return { id, token: `${id}.${verifier}`, expiresAt };
}

export async function sessionRow(sessionId) {
  const [row] = await sql('select id, user_id, revoked_at, expires_at from sessions where id = $1', [
    sessionId,
  ]);
  return row ?? null;
}

// --- Пользователи и список доступа ------------------------------------------

let seq = 0;

/** Уникальный суффикс: прогон не должен зависеть от того, пуста ли база. */
export function unique(prefix = 'x') {
  seq += 1;
  return `${prefix}-${Date.now().toString(36)}-${seq}-${randomBytes(3).toString('hex')}`;
}

/**
 * Пользователь трекера, каким его создал бы вход через Яндекс ID:
 * запись в `users`, идентичность в `identities`, адрес в списке доступа.
 */
export async function createUser({ displayName, email, grantAccess = true } = {}) {
  const name = displayName ?? `Пользователь ${unique('u')}`;
  const address = (email ?? `${unique('user')}@sl-tracker.test`).toLowerCase();

  const [user] = await sql(
    `insert into users (display_name, email, avatar_url, last_login_at)
     values ($1, $2, null, now()) returning id`,
    [name, address],
  );

  await sql(
    `insert into identities (user_id, provider, external_id) values ($1, 'yandex', $2)`,
    [user.id, `yandex-${user.id}`],
  );

  if (grantAccess) {
    await grantTrackerAccess(address, 'manual', user.id);
  }

  return { id: user.id, displayName: name, email: address };
}

/** Запись списка доступа (уровень 0, ADR-0006). */
export async function grantTrackerAccess(email, source = 'manual', userId = null) {
  await sql(
    `insert into access_entries (email, source, user_id, first_login_at)
     values ($1, $2, $3, case when $3::uuid is null then null else now() end)
     on conflict (lower(email)) do update set user_id = coalesce(access_entries.user_id, excluded.user_id)`,
    [email.toLowerCase(), source, userId],
  );
}

/** Владелец трекера — единственная глобальная роль (D-39). */
export async function makeInstanceOwner(email) {
  await sql('update access_entries set is_instance_owner = true where lower(email) = lower($1)', [
    email,
  ]);
}
