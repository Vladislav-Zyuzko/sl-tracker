import { Module } from '@nestjs/common';
import { IssueKeyService } from './issue-key.service.js';
import { MyIssuesController } from './my-issues.controller.js';
import { MyIssuesRepository } from './my-issues.repository.js';
import { MyIssuesService } from './my-issues.service.js';

/**
 * Домен задач. Пока здесь выдача ключей без гонок (ADR-0004) и список активных задач
 * текущего пользователя для сайдбара (US-81, US-82); создание и изменение задач —
 * следующим заходом.
 */
@Module({
  controllers: [MyIssuesController],
  providers: [IssueKeyService, MyIssuesRepository, MyIssuesService],
  exports: [IssueKeyService],
})
export class IssuesModule {}
