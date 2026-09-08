import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/index.js';
import { MentionsModule } from '../mentions/index.js';
import { NotificationsModule } from '../notifications/index.js';
import { CommentsController } from './comments.controller.js';
import { CommentsRepository } from './comments.repository.js';
import { CommentsService } from './comments.service.js';

/**
 * Комментарии (US-70 … US-73) и упоминания в них (US-74).
 *
 * `IssuesModule` нужен ради проверки доступа к задаче: комментарий не существует
 * отдельно от неё, и права на него выводятся из роли в проекте задачи.
 */
@Module({
  imports: [IssuesModule, MentionsModule, NotificationsModule],
  controllers: [CommentsController],
  providers: [CommentsRepository, CommentsService],
  exports: [CommentsService],
})
export class CommentsModule {}
