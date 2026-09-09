import { Module } from '@nestjs/common';
import { RealtimeModule } from '../realtime/realtime.module.js';
import { NotificationEventsService } from './notification-events.service.js';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsRepositoryPort } from './notifications.port.js';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationsService } from './notifications.service.js';

/**
 * Уведомления (US-100 … US-104, US-23).
 *
 * На домены трекера модуль не смотрит: события в него приносят задачи, комментарии
 * и приглашения, а он только решает, кому и что записать. Обратная стрелка сделала бы
 * цикл и потащила бы половину трекера в счётчик непрочитанных.
 *
 * `RealtimeModule` — исключение, и оно безопасно: это публикация в Redis, у которой
 * своих зависимостей нет. Сам WebSocket-сервер живёт в другом модуле.
 */
@Module({
  imports: [RealtimeModule],
  controllers: [NotificationsController],
  providers: [
    NotificationsRepository,
    { provide: NotificationsRepositoryPort, useExisting: NotificationsRepository },
    NotificationsService,
    NotificationEventsService,
  ],
  exports: [NotificationEventsService, NotificationsRepository],
})
export class NotificationsModule {}
