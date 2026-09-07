import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AccessModule } from '../access/index.js';
import { SessionsModule } from '../sessions/index.js';
import { AccessDeniedTicketStore } from './access-denied-ticket.store.js';
import { AuthController } from './auth.controller.js';
import { AuthRepository } from './auth.repository.js';
import { AuthService } from './auth.service.js';
import { MeController } from './me.controller.js';
import { OauthStateStore } from './oauth-state.store.js';
import { RateLimitGuard } from './guards/rate-limit.guard.js';
import { SessionGuard } from './guards/session.guard.js';
import { YandexOAuthClient } from './yandex/yandex-oauth.client.js';
import { YANDEX_OAUTH } from './yandex/yandex-oauth.port.js';

/**
 * Вход, сессии, текущий пользователь.
 *
 * Обе охраны — глобальные и в этом порядке: сначала ограничение частоты (иначе перебор
 * сессий стоит нам ровно ничего), затем проверка сессии. Маршрут закрыт по умолчанию,
 * `@Public()` открывает его явным решением.
 *
 * Обращение к Яндексу подключается через токен `YANDEX_OAUTH`: тесты подставляют
 * подделку и проверяют поток целиком, не имея боевых `client_id`/`client_secret`.
 */
@Module({
  imports: [SessionsModule, AccessModule],
  controllers: [AuthController, MeController],
  providers: [
    AuthService,
    AuthRepository,
    OauthStateStore,
    AccessDeniedTicketStore,
    { provide: YANDEX_OAUTH, useClass: YandexOAuthClient },
    { provide: APP_GUARD, useClass: RateLimitGuard },
    { provide: APP_GUARD, useClass: SessionGuard },
  ],
  exports: [AuthRepository],
})
export class AuthModule {}
