import { Module } from '@nestjs/common';
import { SessionsModule } from '../sessions/index.js';
import { CookieSessionGuard } from './guards/cookie-session.guard.js';
import { TokensController } from './tokens.controller.js';
import { TokensService } from './tokens.service.js';

/**
 * Персональные токены доступа. Своего хранилища у модуля нет: токен — это сессия
 * с назначением `pat`, поэтому вся работа с данными идёт через `SessionsModule`
 * (RFC MCP, §5.1).
 */
@Module({
  imports: [SessionsModule],
  controllers: [TokensController],
  providers: [TokensService, CookieSessionGuard],
  exports: [TokensService],
})
export class TokensModule {}
