import { Inject, Injectable, Logger } from '@nestjs/common';
import { AccessListService } from '../access/index.js';
import { normalizeEmail } from '../common/index.js';
import { type IssuedSession, SessionService } from '../sessions/index.js';
import { AccessDeniedTicketStore } from './access-denied-ticket.store.js';
import { type AuthErrorCode, DEFAULT_AFTER_LOGIN_PATH, YANDEX_PROVIDER } from './auth.constants.js';
import { AuthRepository } from './auth.repository.js';
import type { AuthenticatedUser } from './auth.types.js';
import { OauthStateStore } from './oauth-state.store.js';
import {
  YANDEX_OAUTH,
  type YandexOAuthPort,
  YandexOAuthError,
} from './yandex/yandex-oauth.port.js';

/** Итог колбэка. Четыре исхода: три экрана фронтенда и один отказ разбирать запрос. */
export type LoginResult =
  | {
      outcome: 'success';
      user: AuthenticatedUser;
      session: IssuedSession;
      /** Куда вернуть пользователя: он мог прийти по ссылке на задачу (US-01). */
      redirectPath: string;
    }
  | {
      outcome: 'access-denied';
      /**
       * Одноразовый тикет, по которому экран отказа покажет адрес, под которым человек
       * вошёл. `null` — провайдер адреса не отдал, экран обойдётся без него.
       */
      ticket: string | null;
    }
  | { outcome: 'error'; code: AuthErrorCode }
  /**
   * Запрос не похож на возврат из браузера пользователя (нет `state` вовсе).
   * Тут не на что редиректить: отвечаем 400 и ничего не делаем.
   */
  | { outcome: 'bad-request' };

/**
 * Поток входа через Яндекс ID (ADR-0002).
 *
 * Порядок шагов здесь важен и продиктован ADR-0006: **сначала** решаем, пускать ли
 * человека, и только потом заводим пользователя. Отказ не должен оставлять следов —
 * ни строки в `users`, ни сессии (US-05).
 */
@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @Inject(YANDEX_OAUTH) private readonly yandex: YandexOAuthPort,
    private readonly states: OauthStateStore,
    private readonly tickets: AccessDeniedTicketStore,
    private readonly repository: AuthRepository,
    private readonly accessList: AccessListService,
    private readonly sessions: SessionService,
  ) {}

  /**
   * Начало входа: генерируем `state`, кладём в Redis на 10 минут и отправляем человека
   * на страницу согласия Яндекса.
   */
  async start(params: {
    next?: string;
    invite?: string;
  }): Promise<{ authorizeUrl: string } | { error: AuthErrorCode }> {
    if (!this.yandex.isConfigured()) {
      // Штатная ситуация на новом инстансе: приложение в Яндексе ещё не заведено.
      // Это не 500 — фронт показывает понятное сообщение на экране входа.
      this.logger.warn('Вход через Яндекс ID не настроен: нет client_id/client_secret');
      return { error: 'oauth_not_configured' };
    }

    const state = await this.states.issue({
      next: safeNextPath(params.next),
      invite: params.invite && params.invite.length <= 64 ? params.invite : null,
    });

    return { authorizeUrl: this.yandex.buildAuthorizeUrl(state) };
  }

  /**
   * Возврат из Яндекса.
   *
   * `state` проверяется **всегда и первым делом** после явной ошибки провайдера:
   * без этой проверки колбэк принимает чужой `code` — это CSRF на вход (ADR-0002).
   * `state` одноразовый, поэтому повторный вызов с тем же `code` даёт `invalid_state`
   * и второй сессии не создаёт.
   *
   * Отсутствие `state` и негодный `state` — разные случаи. Нет параметра вовсе —
   * это не возврат из браузера пользователя, а чей-то самодельный запрос: 400 и всё.
   * Есть, но неизвестен или истёк — человек всё-таки шёл через Яндекс, и ему нужен
   * экран входа с понятным сообщением, а не голый 400.
   */
  async complete(params: { code?: string; state?: string; error?: string }): Promise<LoginResult> {
    if (params.error) {
      if (params.state) {
        await this.states.consume(params.state);
      }
      return { outcome: 'error', code: mapProviderError(params.error) };
    }

    if (!params.state) {
      return { outcome: 'bad-request' };
    }

    const stateData = await this.states.consume(params.state);
    if (!stateData) {
      return { outcome: 'error', code: 'invalid_state' };
    }

    if (!params.code) {
      // `state` был наш, но кода нет: провайдер вернул не то, чего мы ждём.
      return { outcome: 'error', code: 'provider_unavailable' };
    }

    try {
      const accessToken = await this.yandex.exchangeCode(params.code);
      const profile = await this.yandex.fetchProfile(accessToken);
      // Дальше токен Яндекса не нужен и никуда не сохраняется (ADR-0002).

      const email = profile.email ? normalizeEmail(profile.email) : null;
      if (!email) {
        // Без адреса человек не может пройти список доступа: сравнивать не с чем.
        return { outcome: 'access-denied', ticket: null };
      }

      const allowed =
        (await this.accessList.isEmailAllowed(email)) ||
        (stateData.invite !== null &&
          (await this.repository.hasUsableInvitation(stateData.invite)));

      if (!allowed) {
        // Ни пользователя, ни сессии: отказ не оставляет следов (US-05).
        return { outcome: 'access-denied', ticket: await this.tickets.issue(email) };
      }

      const user = await this.repository.completeLogin({
        provider: YANDEX_PROVIDER,
        externalId: profile.externalId,
        displayName: profile.displayName,
        email,
        avatarUrl: profile.avatarUrl,
      });

      const session = await this.sessions.create(user.id, 'cookie');
      this.logger.log(`Вход выполнен: пользователь ${user.id}`);

      return {
        outcome: 'success',
        user,
        session,
        redirectPath: stateData.next ?? DEFAULT_AFTER_LOGIN_PATH,
      };
    } catch (error) {
      if (error instanceof YandexOAuthError) {
        this.logger.warn(`Вход не удался: ${error.message}`);
        return { outcome: 'error', code: error.authCode };
      }

      this.logger.error(
        'Непредвиденная ошибка при завершении входа',
        error instanceof Error ? error.stack : String(error),
      );
      return { outcome: 'error', code: 'server_error' };
    }
  }

  /**
   * Обменивает тикет экрана отказа на адрес, под которым человек вошёл.
   * Тикет одноразовый: повторный запрос ничего не вернёт.
   */
  async resolveAccessDeniedTicket(ticket: string): Promise<string | null> {
    return this.tickets.consume(ticket);
  }

  /** Выход: сессия уничтожается на сервере, а не только очищается cookie (US-03). */
  async logout(sessionId: string): Promise<void> {
    await this.sessions.destroy(sessionId);
  }
}

/** Коды ошибок Яндекса, которые приходят в адрес колбэка. */
function mapProviderError(raw: string): AuthErrorCode {
  switch (raw) {
    case 'access_denied':
      return 'access_denied';
    case 'unauthorized_client':
      // Приложение ещё не прошло модерацию — штатное состояние на старте (CLAUDE.md, п. 7).
      return 'unauthorized_client';
    default:
      return 'provider_unavailable';
  }
}

/**
 * Куда возвращать после входа. Принимается только относительный путь внутри приложения:
 * `//evil.example` и `https://evil.example` — это открытый редирект, через который
 * уводят пользователя вместе с ожиданием «я на своём трекере».
 */
export function safeNextPath(raw: string | undefined): string | null {
  if (!raw || raw.length > 512) {
    return null;
  }
  if (!raw.startsWith('/') || raw.startsWith('//') || raw.startsWith('/\\')) {
    return null;
  }
  if (raw.includes('\\') || raw.includes('\n') || raw.includes('\r')) {
    return null;
  }
  return raw;
}
