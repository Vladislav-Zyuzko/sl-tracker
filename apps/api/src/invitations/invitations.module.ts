import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/index.js';
import { ProjectsModule } from '../projects/index.js';
import { StorageModule } from '../storage/index.js';
import {
  InvitationAcceptController,
  ProjectInvitationsController,
} from './invitations.controller.js';
import { InvitationsRepository } from './invitations.repository.js';
import { InvitationsService } from './invitations.service.js';

/**
 * Приглашения в проект (US-20 … US-22).
 *
 * `ProjectsModule` импортируется ради `ProjectAccessService`: проверка «админ ли
 * этот пользователь в этом проекте» одна на весь трекер, второй такой быть не должно.
 * `NotificationsModule` — ради уведомления администраторам о новом участнике (US-23):
 * оно пишется в той же транзакции, что и само вступление.
 */
@Module({
  imports: [ProjectsModule, StorageModule, NotificationsModule],
  controllers: [ProjectInvitationsController, InvitationAcceptController],
  providers: [InvitationsRepository, InvitationsService],
  exports: [InvitationsService],
})
export class InvitationsModule {}
