import Redis from 'ioredis';
import { config } from './config.mjs';

/**
 * Доступ к тестовой логической базе Redis.
 *
 * Нужен ровно для одного: сбрасывать счётчики ограничения частоты между сценариями.
 *
 * Зачем это вообще. `POST /api/invitations/{token}/accept` ограничен двадцатью
 * запросами в минуту **на адрес клиента**. Весь прогон идёт с одного адреса (127.0.0.1),
 * и на десятке сценариев подряд лимит срабатывает — не потому, что продукт неисправен,
 * а потому, что харнесс выглядит как один очень активный человек.
 *
 * Ограничение при этом не «обходится вслепую»: то, что лимит работает, проверяется
 * отдельным тестом (`tests/rate-limit.test.mjs`). Здесь счётчик именно сбрасывается
 * между сценариями, как если бы прошла минута.
 */

let client;

export function redis() {
  client ??= new Redis({
    host: config.redis.host,
    port: config.redis.port,
    password: config.redis.password,
    db: config.redis.db,
    maxRetriesPerRequest: 2,
  });
  return client;
}

export async function closeRedis() {
  if (client) {
    const closing = client;
    client = undefined;
    await closing.quit().catch(() => {});
  }
}

/** Убирает счётчики ограничения частоты. Без имени — все. */
export async function resetRateLimits(name) {
  const pattern = name ? `sl:ratelimit:${name}:*` : 'sl:ratelimit:*';
  const keys = await redis().keys(pattern);
  if (keys.length > 0) {
    await redis().del(...keys);
  }
  return keys.length;
}
