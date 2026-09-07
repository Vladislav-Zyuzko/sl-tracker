import { Module } from '@nestjs/common';
import { SessionService } from './session.service.js';

/**
 * Сессии вынесены из модуля авторизации отдельно намеренно: гасить сессии нужно и при
 * отзыве доступа (`AccessModule`), и при выходе (`AuthModule`). Общий модуль-зависимость
 * убирает круговую связь между ними.
 */
@Module({
  providers: [SessionService],
  exports: [SessionService],
})
export class SessionsModule {}
