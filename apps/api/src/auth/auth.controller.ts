import {
  BadRequestException,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  NotFoundException,
  Param,
  Post,
  Query,
  Req,
  Res,
} from '@nestjs/common';
import {
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { FastifyReply, FastifyRequest } from 'fastify';
import { ENV, type Env } from '../config/index.js';
import { SessionService } from '../sessions/index.js';
import {
  ACCESS_DENIED_PATH,
  type AuthErrorCode,
  LOGIN_PATH,
  SESSION_COOKIE_NAME,
} from './auth.constants.js';
import { AuthService } from './auth.service.js';
import { AccessDeniedInfoDto } from './dto/access-denied-info.dto.js';
import { UNSAFE_METHODS, assertSameOrigin } from './csrf.js';
import { Public } from './decorators/public.decorator.js';
import { RateLimit } from './decorators/rate-limit.decorator.js';
import { extractToken } from './guards/session.guard.js';

/**
 * HTTP-обёртка потока входа. Логики здесь нет: контроллер разбирает запрос, зовёт
 * сервис и превращает исход в редирект и cookie.
 */
@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly sessions: SessionService,
    @Inject(ENV) private readonly env: Env,
  ) {}

  @Get('yandex/start')
  @Public()
  @RateLimit({ name: 'auth-start', limit: 30, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Начать вход через Яндекс ID',
    description:
      'Генерирует одноразовый `state` (32 байта, TTL 10 минут в Redis) и редиректит на ' +
      'страницу согласия Яндекса. Открывается полным переходом браузера, а не XHR: ' +
      'ответ — 302 на внешний домен. Если вход не настроен на инстансе, редиректит на ' +
      '`/login?error=oauth_not_configured`.',
  })
  @ApiQuery({
    name: 'next',
    required: false,
    description:
      'Куда вернуть после входа. Принимается только путь внутри приложения ' +
      '(`/issues/DEV-42`); внешние адреса игнорируются.',
  })
  @ApiQuery({
    name: 'invite',
    required: false,
    description:
      'Токен ссылки-приглашения. Действующее приглашение пускает в трекер в обход ' +
      'списка доступа (ADR-0006, п. 3).',
  })
  @ApiResponse({ status: 302, description: 'Редирект на `oauth.yandex.ru/authorize`' })
  async start(
    @Query('next') next: string | undefined,
    @Query('invite') invite: string | undefined,
    @Res() reply: FastifyReply,
  ): Promise<void> {
    const result = await this.auth.start({ next, invite });

    if ('error' in result) {
      this.redirect(reply, this.errorUrl(result.error));
      return;
    }

    this.redirect(reply, result.authorizeUrl);
  }

  @Get('yandex/callback')
  @Public()
  @RateLimit({ name: 'auth-callback', limit: 30, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Колбэк Яндекс ID',
    description:
      'Проверяет `state`, меняет `code` на токен, читает профиль, заводит пользователя ' +
      'и сессию. Всегда отвечает редиректом:\n\n' +
      '- успех — на сохранённый адрес назначения или `/projects`, с cookie `sl_session`;\n' +
      '- нет доступа — на `/access-denied?ticket=<тикет>`, **без** cookie: ни сессии, ни ' +
      'пользователя в базе не появляется (US-05). Адрес, под которым человек вошёл, ' +
      'экран получает обменом тикета — в адресной строке его нет;\n' +
      '- ошибка — на `/login?error=<код>`: `access_denied`, `unauthorized_client` ' +
      '(приложение не прошло модерацию), `invalid_state`, `provider_unavailable`, ' +
      '`oauth_not_configured`, `server_error`.\n\n' +
      'Отсутствие параметра `state` — не возврат из браузера пользователя, а посторонний ' +
      'запрос: 400 без редиректа. Негодный или истёкший `state` — редирект на ' +
      '`/login?error=invalid_state`.',
  })
  @ApiQuery({ name: 'code', required: false })
  @ApiQuery({ name: 'state', required: false })
  @ApiQuery({ name: 'error', required: false, description: 'Код ошибки от Яндекса' })
  @ApiResponse({ status: 302, description: 'Редирект в приложение' })
  async callback(
    @Query('code') code: string | undefined,
    @Query('state') state: string | undefined,
    @Query('error') error: string | undefined,
    @Res() reply: FastifyReply,
  ): Promise<void> {
    const result = await this.auth.complete({ code, state, error });

    if (result.outcome === 'bad-request') {
      throw new BadRequestException({
        code: 'invalid_callback',
        message: 'Некорректный запрос',
      });
    }

    if (result.outcome === 'error') {
      this.redirect(reply, this.errorUrl(result.code));
      return;
    }

    if (result.outcome === 'access-denied') {
      const url = new URL(ACCESS_DENIED_PATH, this.env.APP_BASE_URL);
      if (result.ticket) {
        // В адресе — тикет, а не email: адрес не должен осесть в истории браузера
        // и в логах прокси (ADR-0006). Экран обменяет тикет на адрес.
        url.searchParams.set('ticket', result.ticket);
      }
      this.redirect(reply, url.toString());
      return;
    }

    // Cookie с датой истечения, а не на время вкладки: пользователь должен остаться
    // вошедшим после закрытия браузера (US-02).
    void reply.setCookie(SESSION_COOKIE_NAME, result.session.token, {
      ...this.cookieOptions(),
      expires: result.session.expiresAt,
    });
    this.redirect(reply, new URL(result.redirectPath, this.env.APP_BASE_URL).toString());
  }

  @Get('access-denied/:ticket')
  @Public()
  @RateLimit({ name: 'auth-denied-ticket', limit: 30, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Обменять тикет экрана отказа на адрес',
    description:
      'Экран «Доступ к трекеру закрыт» показывает адрес, под которым человек вошёл. ' +
      'Тикет одноразовый и живёт 60 секунд: адрес не попадает ни в адресную строку, ' +
      'ни в логи. Повторный обмен — 404. Ничего, кроме собственного адреса ' +
      'обратившегося, тикет не раскрывает.',
  })
  @ApiParam({ name: 'ticket', description: 'Значение параметра `ticket` из адреса редиректа' })
  @ApiOkResponse({ type: AccessDeniedInfoDto })
  @ApiNotFoundResponse({ description: 'Тикет неизвестен, истёк или уже использован' })
  async accessDeniedInfo(@Param('ticket') ticket: string): Promise<AccessDeniedInfoDto> {
    const email = await this.auth.resolveAccessDeniedTicket(ticket);
    if (!email) {
      throw new NotFoundException({
        code: 'ticket_not_found',
        message: 'Ссылка устарела',
      });
    }
    return { email };
  }

  @Post('logout')
  @Public()
  @HttpCode(HttpStatus.NO_CONTENT)
  @RateLimit({ name: 'auth-logout', limit: 60, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Выйти',
    description:
      'Уничтожает сессию **на сервере** и очищает cookie. Отвечает 204 и тогда, когда ' +
      'сессии уже нет: экран отказа доступа зовёт выход, не зная, была ли сессия создана.',
  })
  @ApiNoContentResponse({ description: 'Сессия завершена' })
  async logout(@Req() request: FastifyRequest, @Res() reply: FastifyReply): Promise<void> {
    const presented = extractToken(request);
    if (presented) {
      // Выход публичен (экран отказа зовёт его без сессии), поэтому проверку источника
      // делаем здесь сами: иначе чужой сайт мог бы разлогинивать наших пользователей.
      if (presented.kind === 'cookie' && UNSAFE_METHODS.has(request.method.toUpperCase())) {
        assertSameOrigin(request, new URL(this.env.APP_BASE_URL).origin);
      }

      const session = await this.sessions.resolve(presented.token);
      if (session) {
        await this.auth.logout(session.id);
      }
    }

    void reply.clearCookie(SESSION_COOKIE_NAME, this.cookieOptions());
    void reply.status(HttpStatus.NO_CONTENT).send();
  }

  /**
   * `Secure` выводится из адреса приложения: на боевом домене это https, и cookie
   * уходит только по нему. Локально по http браузер `Secure`-cookie не примет,
   * и вход было бы невозможно проверить.
   */
  private cookieOptions() {
    return {
      httpOnly: true,
      secure: new URL(this.env.APP_BASE_URL).protocol === 'https:',
      sameSite: 'lax' as const,
      path: '/',
    };
  }

  private errorUrl(code: AuthErrorCode): string {
    const url = new URL(LOGIN_PATH, this.env.APP_BASE_URL);
    url.searchParams.set('error', code);
    return url.toString();
  }

  private redirect(reply: FastifyReply, location: string): void {
    void reply.header('location', location).status(HttpStatus.FOUND).send();
  }
}
