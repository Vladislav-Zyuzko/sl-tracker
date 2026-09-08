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
// Разделитель — ПРОБЕЛ, а не запятая: «Значения в списке разделяются пробелами»
// (https://yandex.ru/dev/id/doc/ru/codes/code-url). С запятой Яндекс возвращает
// invalid_scope — поймано на живом входе, а не в тестах с подделкой провайдера.
const SCOPE = ['login:info', 'login:email', 'login:avatar'].join(' ');

/** Провайдер не должен уметь подвесить наш запрос: обрываем по таймауту. */
const REQUEST_TIMEOUT_MS = 10_000;

/** Размер аватара из `default_avatar_id` (документация Яндекс ID). */
const AVATAR_SIZE = 'islands-200';

/** Шаг обмена — он попадает в лог, чтобы отказ можно было разобрать без отладчика. */
type Step = 'exchange' | 'profile';

const STEP_NAMES: Readonly<Record<Step, string>> = {
  exchange: 'обмен кода на токен',
  profile: 'получение профиля',
};

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

/** Ответ провайдера вместе с тем, что нужно логу: статус и длительность запроса. */
interface ProviderResponse<T> {
  payload: T;
  status: number;
  durationMs: number;
}

/**
 * Реальный клиент Яндекс ID.
 *
 * Про логи: **каждый** отказ пишется одной строкой — шаг, HTTP-статус, длительность
 * и причина. Без этого редирект на `/login?error=provider_unavailable` невозможно
 * разобрать: снаружи все причины выглядят одинаково.
 *
 * Что в лог не попадает никогда: `client_secret`, `code`, access-токен и тело ответа
 * с токенами. Статус, код ошибки провайдера и `error_description` — попадают: это
 * ровно то, чем отличается «приложение не прошло модерацию» от «код уже использован».
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

    const { payload, status, durationMs } = await this.request<TokenResponse>(
      'exchange',
      TOKEN_URL,
      {
        method: 'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
      },
    );

    if (typeof payload.error === 'string') {
      const description =
        typeof payload.error_description === 'string' ? `: ${payload.error_description}` : '';
      throw this.fail(
        'exchange',
        status,
        durationMs,
        `провайдер отклонил обмен (${payload.error}${description})`,
        payload.error === 'unauthorized_client' ? 'unauthorized_client' : 'provider_unavailable',
      );
    }

    if (typeof payload.access_token !== 'string' || payload.access_token.length === 0) {
      throw this.fail('exchange', status, durationMs, 'в ответе провайдера нет access_token');
    }

    // Токен в лог не попадает — только факт удачного обмена.
    this.logger.log(
      `Яндекс ID: ${STEP_NAMES.exchange} выполнен, статус ${status}, ${durationMs} мс`,
    );
    return payload.access_token;
  }

  async fetchProfile(accessToken: string): Promise<YandexProfile> {
    const { payload, status, durationMs } = await this.request<ProfileResponse>(
      'profile',
      PROFILE_URL,
      { method: 'GET', headers: { authorization: `OAuth ${accessToken}` } },
    );

    // Яндекс отдаёт `id` строкой; число тоже принимаем — приводить объект к строке
    // нельзя, это дало бы бессмысленный идентификатор.
    const externalId =
      typeof payload.id === 'string'
        ? payload.id
        : typeof payload.id === 'number'
          ? String(payload.id)
          : '';
    if (!externalId) {
      throw this.fail('profile', status, durationMs, 'в профиле провайдера нет идентификатора');
    }

    const email = pickEmail(payload);
    // Адрес — персональные данные, в лог он не пишется: только есть он или нет.
    this.logger.log(
      `Яндекс ID: ${STEP_NAMES.profile} выполнено, статус ${status}, ${durationMs} мс, ` +
        `email ${email ? 'получен' : 'не выдан'}`,
    );

    return {
      externalId,
      displayName: pickDisplayName(payload) ?? externalId,
      email,
      avatarUrl: pickAvatarUrl(payload),
    };
  }

  private async request<T>(
    step: Step,
    url: string,
    init: RequestInit,
  ): Promise<ProviderResponse<T>> {
    const startedAt = Date.now();

    let response: Response;
    try {
      response = await fetch(url, { ...init, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
    } catch (error) {
      // Сеть, DNS, TLS, таймаут: HTTP-статуса тут нет, поэтому в лог идёт 0.
      throw this.fail(
        step,
        0,
        Date.now() - startedAt,
        `провайдер недоступен (${error instanceof Error ? `${error.name}: ${error.message}` : 'ошибка сети'})`,
      );
    }

    const durationMs = Date.now() - startedAt;
    const status = response.status;

    // 400 на обмене кода несёт полезное тело с `error` — его нужно разобрать,
    // а не превращать в общую ошибку.
    let payload: unknown;
    try {
      payload = await response.json();
    } catch {
      throw this.fail(step, status, durationMs, 'тело ответа не разбирается как JSON');
    }

    if (!isRecord(payload)) {
      throw this.fail(step, status, durationMs, 'провайдер ответил не объектом');
    }

    // Ответ с ошибкой разбирает вызывающий код только на обмене: там из кода `error`
    // получается `unauthorized_client` (приложение не прошло модерацию). На получении
    // профиля разбирать нечего — это отказ, и он логируется здесь.
    if (!response.ok && !(step === 'exchange' && typeof payload.error === 'string')) {
      const code = typeof payload.error === 'string' ? ` (${payload.error})` : '';
      throw this.fail(step, status, durationMs, `провайдер ответил ошибкой${code}`);
    }

    return { payload: payload as T, status, durationMs };
  }

  /**
   * Единственное место, где рождается отказ провайдера, — и единственное, где он
   * логируется. Возвращает исключение, а не бросает его сама, чтобы на месте вызова
   * было видно `throw` и работала проверка недостижимого кода.
   */
  private fail(
    step: Step,
    status: number,
    durationMs: number,
    reason: string,
    code: 'provider_unavailable' | 'unauthorized_client' = 'provider_unavailable',
  ): YandexOAuthError {
    this.logger.warn(
      `Яндекс ID: ${STEP_NAMES[step]} не удалось, статус ${status}, ${durationMs} мс, ` +
        `код ${code}, причина: ${reason}`,
    );
    return new YandexOAuthError(code, `${STEP_NAMES[step]}: ${reason}`);
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
