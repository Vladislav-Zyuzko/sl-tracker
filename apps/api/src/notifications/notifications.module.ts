import { Module } from '@nestjs/common';
import { NotificationEventsService } from './notification-events.service.js';
import { NotificationsController } from './notifications.controller.js';
import { NotificationsRepositoryPort } from './notifications.port.js';
import { NotificationsRepository } from './notifications.repository.js';
import { NotificationsService } from './notifications.service.js';

/**
 * Уведомления (US-100 … US-104, US-23).
 *
 * Модуль ни от кого не зависит и ни на кого не смотрит: события в него приносят
 * домены задач, комментариев и приглашений, а он только решает, кому и что записать.
 * Обратная стрелка сделала бы цикл и потащила бы половину трекера в счётчик
 * непрочитанных.
 */
@Module({
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
