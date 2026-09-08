import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { IssueUserDto } from '../../issues/dto/issue.dto.js';
import { PREVIEWABLE_IMAGE_TYPES, isPreviewableImage } from '../../storage/index.js';
import { ATTACHMENTS_MAX_LIMIT, type AttachmentView } from '../attachments.service.js';

export class AttachmentDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'screenshot.png', description: 'Имя файла как его назвал загрузивший' })
  fileName!: string;

  @ApiProperty({
    example: 'image/png',
    description:
      'Тип, определённый **по содержимому файла**, а не по заголовку запроса ' +
      'и не по расширению. Неопознанное содержимое — `application/octet-stream`.',
  })
  contentType!: string;

  @ApiProperty({ example: 184320, description: 'Размер в байтах, максимум 26 214 400 (25 МБ)' })
  sizeBytes!: number;

  @ApiProperty({
    description: `Показывать превью в задаче. Верно для ${PREVIEWABLE_IMAGE_TYPES.join(', ')} (US-46).`,
  })
  isImage!: boolean;

  @ApiProperty({
    description:
      'Подписанная ссылка на содержимое, живёт 10 минут. Бакет не публичный: та же ' +
      'ссылка без подписи ничего не отдаёт, и посторонний файл не получит (US-46, D-21). ' +
      'Ссылка выдаётся заново при каждом запросе списка — сохранять её надолго нельзя.',
  })
  url!: string;

  @ApiProperty({
    description:
      'Та же подписанная ссылка, но с `Content-Disposition: attachment`: браузер ' +
      'скачивает файл под исходным именем, хотя в хранилище он лежит под именем, ' +
      'сгенерированным сервером.',
  })
  downloadUrl!: string;

  @ApiProperty({ type: IssueUserDto, description: 'Кто приложил' })
  uploadedBy!: IssueUserDto;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({
    description:
      'Может ли запросивший удалить это вложение: администратор проекта — любое, ' +
      'участник — только своё, читатель — никакое (US-46).',
  })
  canDelete!: boolean;

  static from(view: AttachmentView): AttachmentDto {
    return {
      id: view.row.id,
      fileName: view.row.fileName,
      contentType: view.row.contentType,
      sizeBytes: view.row.sizeBytes,
      isImage: isPreviewableImage(view.row.contentType),
      url: view.url,
      downloadUrl: view.downloadUrl,
      uploadedBy: IssueUserDto.from(view.row.uploadedBy),
      createdAt: view.row.createdAt.toISOString(),
      canDelete: view.canDelete,
    };
  }
}

export class AttachmentListDto {
  @ApiProperty({ type: [AttachmentDto], description: 'Сначала старые, в порядке добавления' })
  items!: AttachmentDto[];

  @ApiProperty({ type: String, nullable: true })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего вложений у задачи' })
  total!: number;

  @ApiProperty({
    description: 'Может ли запросивший приложить файл. `false` у читателя (US-46, D-29).',
  })
  canUpload!: boolean;
}

export class ListAttachmentsQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: ATTACHMENTS_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(ATTACHMENTS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей порции из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
