import { Module } from '@nestjs/common';
import { QueuesModule } from '../queues/index.js';
import { IssueAccessService } from './issue-access.service.js';
import { IssueHistoryRepository } from './issue-history.repository.js';
import { IssueHistoryService } from './issue-history.service.js';
import { IssueKeyService } from './issue-key.service.js';
import { IssueController, QueueIssuesController } from './issues.controller.js';
import { IssuesRepository } from './issues.repository.js';
import { IssuesService } from './issues.service.js';
import { MyIssuesController } from './my-issues.controller.js';
import { MyIssuesRepository } from './my-issues.repository.js';
import { MyIssuesService } from './my-issues.service.js';

/**
 * Домен задач: выдача ключей без гонок (ADR-0004), CRUD задач, список задач очереди,
 * внешние ссылки, история изменений и список активных задач для сайдбара.
 *
 * `QueuesModule` импортируется ради `QueueAccessService` и статусов очереди. Стрелка
 * идёт только в эту сторону: очереди про задачи ничего не знают, кроме того, что
 * непустую очередь нельзя удалить.
 */
@Module({
  imports: [QueuesModule],
  controllers: [MyIssuesController, QueueIssuesController, IssueController],
  providers: [
    IssueKeyService,
    IssuesRepository,
    IssuesService,
    IssueAccessService,
    IssueHistoryRepository,
    IssueHistoryService,
    MyIssuesRepository,
    MyIssuesService,
  ],
  exports: [IssueKeyService, IssuesRepository, IssueAccessService],
})
export class IssuesModule {}
