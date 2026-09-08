import { Module } from '@nestjs/common';
import { IssuesModule } from '../issues/index.js';
import { StorageModule } from '../storage/index.js';
import { AttachmentsController } from './attachments.controller.js';
import { AttachmentsRepository } from './attachments.repository.js';
import { AttachmentsService } from './attachments.service.js';

/**
 * Вложения к задачам (US-46). `StorageModule` — тот же клиент MinIO, что и у обложек
 * проекта: второй S3-клиент в приложении не нужен.
 */
@Module({
  imports: [IssuesModule, StorageModule],
  controllers: [AttachmentsController],
  providers: [AttachmentsRepository, AttachmentsService],
  exports: [AttachmentsService],
})
export class AttachmentsModule {}
