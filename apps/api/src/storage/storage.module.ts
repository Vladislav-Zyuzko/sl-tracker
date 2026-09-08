import { Module } from '@nestjs/common';
import { ObjectStorageService } from './object-storage.service.js';

/**
 * Файловое хранилище (MinIO по S3 API). Модуль глобальным не делается: файлы нужны
 * не всем доменам, и явный импорт показывает, кто именно с ними работает.
 */
@Module({
  providers: [ObjectStorageService],
  exports: [ObjectStorageService],
})
export class StorageModule {}
