import { Inject, Injectable, Logger } from '@nestjs/common';
import { ENV, type Env } from '../../config/index.js';
import { type YandexOAuthPort, YandexOAuthError, type YandexProfile } from './yandex-oauth.port.js';

/** Адреса Яндекс ID (CLAUDE.md, решение 2; docs: yandex.ru/dev/id). */
const AUTHORIZE_URL = 'https://oauth.yandex.ru/authorize';
const TOKEN_URL = 'https://oauth.yandex.ru/token';
const PROFILE_URL = 'https://login.yandex.ru/info?format=json';

/**
 * Права приложения. Тип приложения и права выбираются один раз при регистрации
 * (CLAUDE.md, решение 7). В документации Яндекса значения перечислены через запятую.
 */
const SCOPE = ['login:info', 'login:email', 'login:avatar'].join(',');

/** Провайдер не должен уметь подвесить наш запрос: обрываем по таймауту. */
const REQUEST_TIMEOUT_MS = 10_000;

/** Размер аватара из `default_avatar_id` (документация Яндекс ID). */
const AVATAR_SIZE = 'islands-200';

interface TokenResponse {
  access_token?: unknown;
  error?: unknown;
  error_description?: unknown;
}

interface ProfileResponse {
  id?: unknown;
  login?: unknown;
  display_name?: unknown;
  real_name?: unknown;
  default_email?: unknown;
  emails?: unknown;
  default_avatar_id?: unknown;
  is_avatar_empty?: unknown;
}

/**
 * Реальный клиент Яндекс ID.
 *
 * Про логи: пишется только факт обмена и код ошибки провайдера. Ни `client_secret`,
 * ни `code`, ни access-токен, ни тело ответа в лог не попадают — иначе секрет утечёт
 * в первый же собранный лог.
 *
 * Access-токен Яндекса нигде не сохраняется: после получения профиля он не нужен
 * (ADR-0002, «Последствия»).
 */
@Injectable()
export class YandexOAuthClient implements YandexOAuthPort {
  private readonly logger = new Logger(YandexOAuthClient.name);

  constructor(@Inject(ENV) private readonly env: Env) {}

  isConfigured(): boolean {
    return Boolean(
      this.env.YANDEX_CLIENT_ID && this.env.YANDEX_CLIENT_SECRET && this.env.YANDEX_REDIRECT_URI,
    );
  }

  buildAuthorizeUrl(state: string): string {
    const url = new URL(AUTHORIZE_URL);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('client_id', this.env.YANDEX_CLIENT_ID ?? '');
    url.searchParams.set('redirect_uri', this.env.YANDEX_REDIRECT_URI ?? '');
    url.searchParams.set('scope', SCOPE);
    url.searchParams.set('state', state);
    return url.toString();
  }

  async exchangeCode(code: string): Promise<string> {
    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      client_id: this.env.YANDEX_CLIENT_ID ?? '',
      client_secret: this.env.YANDEX_CLIENT_SECRET ?? '',
      redirect_uri: this.env.YANDEX_REDIRECT_URI ?? '',
    });

    const payload = await this.request<TokenResponse>(TOKEN_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    });

    if (typeof payload.error === 'string') {
      this.logger.warn(`Яндекс ID отказал в обмене кода: ${payload.error}`);
      throw new YandexOAuthError(
        payload.error === 'unauthorized_client' ? 'unauthorized_client' : 'provider_unavailable',
        `обмен кода отклонён провайдером (${payload.error})`,
      );
    }

    if (typeof payload.access_token !== 'string' || payload.access_token.length === 0) {
      throw new YandexOAuthError('provider_unavailable', 'в ответе провайдера нет access_token');
    }

    this.logger.log('Код обменян на токен Яндекс ID');
    return payload.access_token;
  }

  async fetchProfile(accessToken: string): Promise<YandexProfile> {
    const payload = await this.request<ProfileResponse>(PROFILE_URL, {
      method: 'GET',
      headers: { authorization: `OAuth ${accessToken}` },
    });

    // Яндекс отдаёт `id` строкой; число тоже принимаем — приводить объект к строке
    // нельзя, это дало бы бессмысленный идентификатор.
    const externalId =
      typeof payload.id === 'string'
        ? payload.id
        : typeof payload.id === 'number'
          ? String(payload.id)
          : '';
    if (!externalId) {
      throw new YandexOAuthError('provider_unavailable', 'в профиле провайдера нет идентификатора');
    }

    return {
      externalId,
      displayName: pickDisplayName(payload) ?? externalId,
      email: pickEmail(payload),
      avatarUrl: pickAvatarUrl(payload),
    };
  }

  private async request<T>(url: string, init: RequestInit): Promise<T> {
    let response: Response;
    try {
      response = await fetch(url, { ...init, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
    } catch (error) {
      throw new YandexOAuthError(
        'provider_unavailable',
        `провайдер недоступен: ${error instanceof Error ? error.name : 'ошибка сети'}`,
      );
    }

    // 400 на обмене кода несёт полезное тело с `error` — его нужно разобрать,
    // а не превращать в общую ошибку.
    let payload: unknown;
    try {
      payload = await response.json();
    } catch {
      throw new YandexOAuthError(
        'provider_unavailable',
        `провайдер ответил ${response.status} без разбираемого тела`,
      );
    }

    if (!response.ok && !isRecord(payload)) {
      throw new YandexOAuthError('provider_unavailable', `провайдер ответил ${response.status}`);
    }
    if (!isRecord(payload)) {
      throw new YandexOAuthError('provider_unavailable', 'провайдер ответил не объектом');
    }

    return payload as T;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function pickDisplayName(payload: ProfileResponse): string | null {
  for (const candidate of [payload.display_name, payload.real_name, payload.login]) {
    if (typeof candidate === 'string' && candidate.trim().length > 0) {
      return candidate.trim();
    }
  }
  return null;
}

function pickEmail(payload: ProfileResponse): string | null {
  if (typeof payload.default_email === 'string' && payload.default_email.includes('@')) {
    return payload.default_email;
  }
  if (Array.isArray(payload.emails)) {
    const first = payload.emails.find(
      (item): item is string => typeof item === 'string' && item.includes('@'),
    );
    return first ?? null;
  }
  return null;
}

function pickAvatarUrl(payload: ProfileResponse): string | null {
  if (payload.is_avatar_empty === true) {
    return null;
  }
  if (typeof payload.default_avatar_id !== 'string' || payload.default_avatar_id.length === 0) {
    return null;
  }
  return `https://avatars.yandex.net/get-yapic/${encodeURIComponent(payload.default_avatar_id)}/${AVATAR_SIZE}`;
}
