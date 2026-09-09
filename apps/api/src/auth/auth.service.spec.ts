import { beforeEach, describe, expect, it } from '@jest/globals';
import type { AccessListService } from '../access/index.js';
import type { RealtimePublisher } from '../realtime/realtime.publisher.js';
import type { IssuedSession, SessionService } from '../sessions/index.js';
import type { AccessDeniedTicketStore } from './access-denied-ticket.store.js';
import type { AuthRepository, ProviderProfile } from './auth.repository.js';
import { AuthService, safeNextPath } from './auth.service.js';
import type { AuthenticatedUser } from './auth.types.js';
import type { OauthStateStore, OauthStatePayload } from './oauth-state.store.js';
import {
  type YandexOAuthPort,
  YandexOAuthError,
  type YandexProfile,
} from './yandex/yandex-oauth.port.js';

/**
 * Поток входа проверяется целиком, без обращений к Яндексу: обмен с провайдером
 * вынесен за интерфейс (`YandexOAuthPort`) именно ради этого — боевых `client_id`
 * и `client_secret` у нас пока нет, а поведение потока проверять надо сейчас.
 */

const PROFILE: YandexProfile = {
  externalId: 'yandex-1',
  displayName: 'Иван Петров',
  email: 'Ivan@Yandex.RU',
  avatarUrl: 'https://avatars.yandex.net/get-yapic/a/islands-200',
};

/** Подделка провайдера: помнит выданные коды и не даёт использовать код дважды. */
class FakeYandex implements YandexOAuthPort {
  configured = true;
  profile: YandexProfile = PROFILE;
  failure: YandexOAuthError | null = null;
  readonly usedCodes = new Set<string>();

  isConfigured(): boolean {
    return this.configured;
  }

  buildAuthorizeUrl(state: string): string {
    return `https://oauth.yandex.ru/authorize?state=${state}`;
  }

  exchangeCode(code: string): Promise<string> {
    if (this.failure) {
      return Promise.reject(this.failure);
    }
    if (this.usedCodes.has(code)) {
      // Так ведёт себя Яндекс: код одноразовый, повторный обмен — invalid_grant.
      return Promise.reject(
        new YandexOAuthError(
          'provider_unavailable',
          'обмен кода отклонён провайдером (invalid_grant)',
        ),
      );
    }
    this.usedCodes.add(code);
    return Promise.resolve(`access-token-for-${code}`);
  }

  fetchProfile(): Promise<YandexProfile> {
    return Promise.resolve(this.profile);
  }
}

/** Хранилище `state` в памяти — с тем же одноразовым поведением, что и в Redis. */
class FakeStateStore {
  private readonly states = new Map<string, OauthStatePayload>();
  private counter = 0;

  issue(payload: OauthStatePayload): Promise<string> {
    const state = `state-${(this.counter += 1)}`;
    this.states.set(state, payload);
    return Promise.resolve(state);
  }

  consume(state: string): Promise<OauthStatePayload | null> {
    const payload = this.states.get(state) ?? null;
    this.states.delete(state);
    return Promise.resolve(payload);
  }
}

/** Одноразовые тикеты экрана отказа — в памяти, с тем же поведением, что и в Redis. */
class FakeTicketStore {
  private readonly tickets = new Map<string, string>();
  private counter = 0;

  issue(email: string): Promise<string> {
    const ticket = `ticket-${(this.counter += 1)}`;
    this.tickets.set(ticket, email);
    return Promise.resolve(ticket);
  }

  consume(ticket: string): Promise<string | null> {
    const email = this.tickets.get(ticket) ?? null;
    this.tickets.delete(ticket);
    return Promise.resolve(email);
  }
}

class FakeAccessList {
  allowed = new Set<string>();

  isEmailAllowed(email: string): Promise<boolean> {
    return Promise.resolve(this.allowed.has(email));
  }
}

class FakeAuthRepository {
  readonly logins: ProviderProfile[] = [];
  usableInvitations = new Set<string>();

  completeLogin(profile: ProviderProfile): Promise<AuthenticatedUser> {
    this.logins.push(profile);
    return Promise.resolve({
      id: 'user-1',
      displayName: profile.displayName,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      isInstanceOwner: false,
    });
  }

  hasUsableInvitation(token: string): Promise<boolean> {
    return Promise.resolve(this.usableInvitations.has(token));
  }
}

class FakeSessions {
  readonly created: string[] = [];
  readonly destroyed: string[] = [];

  destroy(sessionId: string): Promise<void> {
    this.destroyed.push(sessionId);
    return Promise.resolve();
  }

  create(userId: string): Promise<IssuedSession> {
    this.created.push(userId);
    return Promise.resolve({
      id: `session-${this.created.length}`,
      token: `session-${this.created.length}.verifier`,
      expiresAt: new Date(Date.now() + 1000),
    });
  }
}

/** Выход закрывает не только сессию, но и открытый под ней сокет. */
class FakeRealtime {
  readonly closedSessions: string[] = [];

  revokeSession(sessionId: string): Promise<void> {
    this.closedSessions.push(sessionId);
    return Promise.resolve();
  }
}

describe('AuthService: поток входа через Яндекс ID', () => {
  let yandex: FakeYandex;
  let states: FakeStateStore;
  let tickets: FakeTicketStore;
  let accessList: FakeAccessList;
  let repository: FakeAuthRepository;
  let sessions: FakeSessions;
  let realtime: FakeRealtime;
  let service: AuthService;

  beforeEach(() => {
    yandex = new FakeYandex();
    states = new FakeStateStore();
    tickets = new FakeTicketStore();
    accessList = new FakeAccessList();
    repository = new FakeAuthRepository();
    sessions = new FakeSessions();
    realtime = new FakeRealtime();
    service = new AuthService(
      yandex,
      states as unknown as OauthStateStore,
      tickets as unknown as AccessDeniedTicketStore,
      repository as unknown as AuthRepository,
      accessList as unknown as AccessListService,
      sessions as unknown as SessionService,
      realtime as unknown as RealtimePublisher,
    );
  });

  /** Проходит весь путь: старт → колбэк с выданным `state`. */
  async function login(options: { code?: string; next?: string; invite?: string } = {}) {
    const started = await service.start({ next: options.next, invite: options.invite });
    if ('error' in started) {
      throw new Error(`старт входа не удался: ${started.error}`);
    }
    const state = new URL(started.authorizeUrl).searchParams.get('state');
    return service.complete({ code: options.code ?? 'code-1', state: state ?? undefined });
  }

  it('пускает человека из списка доступа: заводит пользователя и сессию', async () => {
    accessList.allowed.add('ivan@yandex.ru');

    const result = await login({ next: '/issues/DEV-42' });

    expect(result.outcome).toBe('success');
    if (result.outcome !== 'success') {
      return;
    }
    expect(result.redirectPath).toBe('/issues/DEV-42');
    expect(sessions.created).toEqual(['user-1']);
    // Email нормализован к нижнему регистру: сравнение в списке доступа без учёта регистра.
    expect(repository.logins[0]?.email).toBe('ivan@yandex.ru');
    expect(repository.logins[0]?.provider).toBe('yandex');
  });

  it('без адреса назначения возвращает на экран проектов', async () => {
    accessList.allowed.add('ivan@yandex.ru');
    const result = await login();
    expect(result.outcome === 'success' && result.redirectPath).toBe('/projects');
  });

  it('нет параметра state — это не возврат из браузера: 400, ничего не делаем', async () => {
    accessList.allowed.add('ivan@yandex.ru');

    const result = await service.complete({ code: 'code-1' });

    expect(result).toEqual({ outcome: 'bad-request' });
    expect(sessions.created).toHaveLength(0);
  });

  it('чужой или протухший state — экран входа с invalid_state, а не 400', async () => {
    accessList.allowed.add('ivan@yandex.ru');
    await service.start({});

    const result = await service.complete({ code: 'code-1', state: 'подобранный-state' });

    expect(result).toEqual({ outcome: 'error', code: 'invalid_state' });
    expect(sessions.created).toHaveLength(0);
  });

  it('повторное использование code второй сессии не создаёт', async () => {
    accessList.allowed.add('ivan@yandex.ru');
    const started = await service.start({});
    if ('error' in started) {
      throw new Error('старт входа не удался');
    }
    const state = new URL(started.authorizeUrl).searchParams.get('state') ?? '';

    const first = await service.complete({ code: 'code-1', state });
    const second = await service.complete({ code: 'code-1', state });

    expect(first.outcome).toBe('success');
    // `state` одноразовый, поэтому до повторного обмена кода дело даже не доходит.
    expect(second).toEqual({ outcome: 'error', code: 'invalid_state' });
    expect(sessions.created).toHaveLength(1);
  });

  it('нет в списке доступа — ни сессии, ни пользователя в базе', async () => {
    const result = await login();

    expect(result.outcome).toBe('access-denied');
    expect(repository.logins).toHaveLength(0);
    expect(sessions.created).toHaveLength(0);
  });

  it('отказ выдаёт одноразовый тикет: адрес не уходит в адресную строку', async () => {
    const result = await login();

    expect(result.outcome).toBe('access-denied');
    if (result.outcome !== 'access-denied' || !result.ticket) {
      throw new Error('тикет не выдан');
    }

    // Экран отказа обменивает тикет ровно один раз.
    await expect(service.resolveAccessDeniedTicket(result.ticket)).resolves.toBe('ivan@yandex.ru');
    await expect(service.resolveAccessDeniedTicket(result.ticket)).resolves.toBeNull();
  });

  it('действующее приглашение пускает в обход списка доступа', async () => {
    repository.usableInvitations.add('invite-token');

    const result = await login({ invite: 'invite-token' });

    expect(result.outcome).toBe('success');
    expect(sessions.created).toEqual(['user-1']);
  });

  it('просроченное приглашение не пускает', async () => {
    const result = await login({ invite: 'expired-token' });

    expect(result.outcome).toBe('access-denied');
    expect(sessions.created).toHaveLength(0);
  });

  it('профиль без email — отказ, экран отказа обходится без адреса', async () => {
    accessList.allowed.add('ivan@yandex.ru');
    yandex.profile = { ...PROFILE, email: null };

    const result = await login();

    expect(result).toEqual({ outcome: 'access-denied', ticket: null });
  });

  it('unauthorized_client (приложение на модерации) — осмысленный код, а не 500', async () => {
    accessList.allowed.add('ivan@yandex.ru');
    yandex.failure = new YandexOAuthError('unauthorized_client', 'приложение не прошло модерацию');

    const result = await login();

    expect(result).toEqual({ outcome: 'error', code: 'unauthorized_client' });
  });

  it('отказ пользователя на стороне Яндекса — код access_denied', async () => {
    const result = await service.complete({ error: 'access_denied', state: 'state-1' });
    expect(result).toEqual({ outcome: 'error', code: 'access_denied' });
  });

  it('неизвестная ошибка провайдера — provider_unavailable', async () => {
    const result = await service.complete({ error: 'invalid_scope', state: 'state-1' });
    expect(result).toEqual({ outcome: 'error', code: 'provider_unavailable' });
  });

  it('без настроенного приложения Яндекса вход не начинается', async () => {
    yandex.configured = false;
    const started = await service.start({});
    expect(started).toEqual({ error: 'oauth_not_configured' });
  });

  it('выход гасит сессию на сервере и закрывает открытый под ней сокет (US-03)', async () => {
    await service.logout('session-1');
    expect(sessions.destroyed).toEqual(['session-1']);
    expect(realtime.closedSessions).toEqual(['session-1']);
  });
});

describe('safeNextPath', () => {
  it('пропускает путь внутри приложения', () => {
    expect(safeNextPath('/issues/DEV-42?tab=history')).toBe('/issues/DEV-42?tab=history');
  });

  it.each([
    '//evil.example',
    'https://evil.example',
    '/\\evil.example',
    'issues/DEV-42',
    undefined,
  ])('отбрасывает %s — открытый редирект недопустим', (value) => {
    expect(safeNextPath(value)).toBeNull();
  });
});
