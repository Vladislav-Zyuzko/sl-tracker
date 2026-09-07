import type { AuthErrorCode } from '../auth.constants.js';

/** Профиль из `https://login.yandex.ru/info`, приведённый к нужному нам виду. */
export interface YandexProfile {
  /** `id` в ответе Яндекса — он же `identities.external_id`. */
  externalId: string;
  displayName: string;
  /** Может отсутствовать: пользователь мог не выдать право `login:email`. */
  email: string | null;
  avatarUrl: string | null;
}

/**
 * Обращения к Яндекс ID вынесены за интерфейс намеренно.
 *
 * Во-первых, тесты подставляют подделку и проверяют поток целиком, не имея боевых
 * `client_id`/`client_secret`. Во-вторых, доменный код не обязан знать, что провайдер
 * ровно один: второй провайдер входа — это ещё одна реализация, а не переписывание
 * потока (ADR-0002).
 */
export interface YandexOAuthPort {
  /** Настроены ли `YANDEX_CLIENT_ID`, `YANDEX_CLIENT_SECRET`, `YANDEX_REDIRECT_URI`. */
  isConfigured(): boolean;

  /** Адрес страницы согласия. `state` передаётся без изменений и возвращается назад. */
  buildAuthorizeUrl(state: string): string;

  /**
   * Меняет код на токен. Здесь и только здесь используется `client_secret`.
   * Бросает `YandexOAuthError` — в том числе `unauthorized_client`, пока приложение
   * не прошло модерацию (CLAUDE.md, решение 7).
   */
  exchangeCode(code: string): Promise<string>;

  /** Запрашивает профиль по access-токену. Токен после этого не сохраняется. */
  fetchProfile(accessToken: string): Promise<YandexProfile>;
}

/** Ошибка обмена с провайдером, уже переведённая в код для экрана входа. */
export class YandexOAuthError extends Error {
  constructor(
    readonly authCode: AuthErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'YandexOAuthError';
  }
}

/** DI-токен реализации. */
export const YANDEX_OAUTH = Symbol('YANDEX_OAUTH');
