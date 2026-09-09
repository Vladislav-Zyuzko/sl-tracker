import { Module } from '@nestjs/common';
import { RealtimeModule } from '../realtime/realtime.module.js';
import { SessionsModule } from '../sessions/index.js';
import { AccessBootstrapService } from './access-bootstrap.service.js';
import { AccessController } from './access.controller.js';
import { AccessListRepository } from './access-list.repository.js';
import { AccessListService } from './access-list.service.js';
import { InstanceOwnerGuard } from './guards/instance-owner.guard.js';

/**
 * Доступ в трекер (уровень 0): список доступа, начальное наполнение, отзыв.
 * `SessionsModule` нужен здесь, потому что отзыв доступа гасит сессии, а
 * `RealtimeModule` — потому что он же обязан закрыть уже открытые сокеты (ADR-0006).
 */
@Module({
  imports: [SessionsModule, RealtimeModule],
  controllers: [AccessController],
  providers: [AccessListRepository, AccessListService, AccessBootstrapService, InstanceOwnerGuard],
  exports: [AccessListService],
})
export class AccessModule {}
