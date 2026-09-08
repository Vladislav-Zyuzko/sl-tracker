import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { Logger } from '@nestjs/common';
import type { Env } from '../../config/index.js';
import { YandexOAuthClient } from './yandex-oauth.client.js';
import { YandexOAuthError } from './yandex-oauth.port.js';

/**
 * Отказ входа обязан оставлять след в логе.
 *
 * Живой случай: пользователь получил редирект на `/login?error=provider_unavailable`,
 * а в логе сервера не было ни строки — разобрать причину было нечем. Эти тесты
 * закрепляют требование: каждая ветка отказа пишет шаг, статус, длительность и причину,
 * и ни одна не пишет секретов.
 */

const SECRET = 'super-secret-client-secret';
const CODE = 'authorization-code-from-yandex';
const TOKEN = 'access-token-of-the-user';

const env = {
  YANDEX_CLIENT_ID: 'client-id',
  YANDEX_CLIENT_SECRET: SECRET,
  YANDEX_REDIRECT_URI: 'https://tracker.example.com/api/auth/yandex/callback',
} as unknown as Env;

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

describe('YandexOAuthClient: каждый отказ виден в логе', () => {
  let client: YandexOAuthClient;
  let warnings: string[];
  let logs: string[];
  const realFetch = globalThis.fetch;

  beforeEach(() => {
    client = new YandexOAuthClient(env);
    warnings = [];
    logs = [];
    jest.spyOn(Logger.prototype, 'warn').mockImplementation((message: unknown) => {
      warnings.push(String(message));
    });
    jest.spyOn(Logger.prototype, 'log').mockImplementation((message: unknown) => {
      logs.push(String(message));
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
    globalThis.fetch = realFetch;
  });

  function mockFetch(handler: () => Promise<Response>): void {
    globalThis.fetch = () => handler();
  }

  it('сеть недоступна: пишет шаг, нулевой статус, длительность и причину', async () => {
    mockFetch(() => Promise.reject(new TypeError('fetch failed')));

    await expect(client.exchangeCode(CODE)).rejects.toBeInstanceOf(YandexOAuthError);

    expect(warnings).toHaveLength(1);
    expect(warnings[0]).toContain('обмен кода на токен не удалось');
    expect(warnings[0]).toContain('статус 0');
    expect(warnings[0]).toMatch(/\d+ мс/);
    expect(warnings[0]).toContain('провайдер недоступен');
    expect(warnings[0]).toContain('TypeError');
  });

  it('провайдер отклонил обмен: в логе код ошибки и её описание', async () => {
    mockFetch(() =>
      Promise.resolve(
        jsonResponse(400, { error: 'invalid_grant', error_description: 'Code has expired' }),
      ),
    );

    await expect(client.exchangeCode(CODE)).rejects.toMatchObject({
      authCode: 'provider_unavailable',
    });

    expect(warnings[0]).toContain('invalid_grant');
    expect(warnings[0]).toContain('Code has expired');
    expect(warnings[0]).toContain('статус 400');
  });

  it('приложение не прошло модерацию: код unauthorized_client виден и в логе, и в ошибке', async () => {
    mockFetch(() => Promise.resolve(jsonResponse(401, { error: 'unauthorized_client' })));

    await expect(client.exchangeCode(CODE)).rejects.toMatchObject({
      authCode: 'unauthorized_client',
    });
    expect(warnings[0]).toContain('код unauthorized_client');
  });

  it('ответ без access_token логируется, а не проваливается молча', async () => {
    mockFetch(() => Promise.resolve(jsonResponse(200, { token_type: 'bearer' })));

    await expect(client.exchangeCode(CODE)).rejects.toBeInstanceOf(YandexOAuthError);
    expect(warnings[0]).toContain('нет access_token');
    expect(warnings[0]).toContain('статус 200');
  });

  it('неразбираемое тело логируется с реальным статусом', async () => {
    mockFetch(() => Promise.resolve(new Response('<html>502 Bad Gateway</html>', { status: 502 })));

    await expect(client.exchangeCode(CODE)).rejects.toBeInstanceOf(YandexOAuthError);
    expect(warnings[0]).toContain('не разбирается как JSON');
    expect(warnings[0]).toContain('статус 502');
  });

  it('профиль без идентификатора логируется как отказ шага «получение профиля»', async () => {
    mockFetch(() => Promise.resolve(jsonResponse(200, { login: 'ivan' })));

    await expect(client.fetchProfile(TOKEN)).rejects.toBeInstanceOf(YandexOAuthError);
    expect(warnings[0]).toContain('получение профиля не удалось');
    expect(warnings[0]).toContain('нет идентификатора');
  });

  it('отказ на получении профиля по статусу тоже логируется', async () => {
    mockFetch(() => Promise.resolve(jsonResponse(401, { error: 'invalid_token' })));

    await expect(client.fetchProfile(TOKEN)).rejects.toBeInstanceOf(YandexOAuthError);
    expect(warnings[0]).toContain('получение профиля не удалось');
    expect(warnings[0]).toContain('статус 401');
    expect(warnings[0]).toContain('invalid_token');
  });

  it('удачные шаги тоже видны в логе, но без токена и без адреса', async () => {
    mockFetch(() => Promise.resolve(jsonResponse(200, { access_token: TOKEN })));
    await expect(client.exchangeCode(CODE)).resolves.toBe(TOKEN);

    mockFetch(() =>
      Promise.resolve(
        jsonResponse(200, { id: '1000', login: 'ivan', default_email: 'ivan@yandex.ru' }),
      ),
    );
    await expect(client.fetchProfile(TOKEN)).resolves.toMatchObject({ externalId: '1000' });

    expect(logs).toHaveLength(2);
    expect(logs[0]).toContain('обмен кода на токен выполнен');
    expect(logs[1]).toContain('email получен');
    expect(logs.join(' ')).not.toContain(TOKEN);
    expect(logs.join(' ')).not.toContain('ivan@yandex.ru');
  });

  it('ни секрет, ни код, ни токен в лог не попадают ни на одной ветке', async () => {
    const branches: Array<() => Promise<Response>> = [
      () => Promise.reject(new TypeError('fetch failed')),
      () => Promise.resolve(jsonResponse(400, { error: 'invalid_grant' })),
      () => Promise.resolve(jsonResponse(200, { token_type: 'bearer' })),
      () => Promise.resolve(new Response('not json', { status: 500 })),
    ];

    for (const branch of branches) {
      mockFetch(branch);
      await expect(client.exchangeCode(CODE)).rejects.toBeInstanceOf(YandexOAuthError);
    }

    const everything = [...warnings, ...logs].join(' ');
    expect(everything).not.toContain(SECRET);
    expect(everything).not.toContain(CODE);
    expect(everything).not.toContain(TOKEN);
    expect(warnings).toHaveLength(branches.length);
  });
});
