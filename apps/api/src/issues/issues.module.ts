import { Module } from '@nestjs/common';
import { IssueKeyService } from './issue-key.service.js';

/**
 * Домен задач. Пока здесь только выдача ключей: эндпоинты появятся следующим заходом,
 * а механизм нумерации без гонок нужен уже сейчас (ADR-0004).
 */
@Module({
  providers: [IssueKeyService],
  exports: [IssueKeyService],
})
export class IssuesModule {}
