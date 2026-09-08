import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  PayloadTooLargeException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import { IssueAccessService } from '../issues/index.js';
import type { IssueContext } from '../issues/index.js';
import {
  ATTACHMENT_MAX_BYTES,
  ObjectStorageService,
  detectFileType,
  safeFileName,
} from '../storage/index.js';
import { type AttachmentRow, AttachmentsRepository } from './attachments.repository.js';

/** Вложений у задачи немного, но потолок страницы всё равно жёсткий. */
export const ATTACHMENTS_DEFAULT_LIMIT = 50;
export const ATTACHMENTS_MAX_LIMIT = 100;

export interface AttachmentView {
  row: AttachmentRow;
  /** Подписанная ссылка на просмотр — с TTL, бакет не публичный. */
  url: string;
  /** Та же ссылка, но заставляющая браузер скачать файл с исходным именем. */
  downloadUrl: string;
  canDelete: boolean;
}

export interface AttachmentsPage {
  items: AttachmentView[];
  nextCursor: string | null;
  total: number;
  context: IssueContext;
}

export interface UploadedFile {
  buffer: Buffer;
  fileName: string;
  truncated: boolean;
}

/**
 * Вложения задачи (US-46).
 *
 * Что здесь важнее всего:
 *  - **тип файла не ограничен** (D-21), но определяется по сигнатуре, а не по заголовку
 *    и расширению: клиент может написать в `Content-Type` что угодно;
 *  - **имя объекта в хранилище строит сервер**: имя из браузера — это чужой ввод
 *    в пути бакета;
 *  - **содержимое отдаётся только участнику проекта**: наружу уходит подписанная
 *    ссылка с TTL, которую выдаёт уже проверивший права эндпоинт. Прямая ссылка
 *    без подписи не отдаёт ничего;
 *  - удалить вложение может администратор проекта **или тот, кто его приложил**;
 *    участник чужое вложение не удаляет, читатель не удаляет ничего.
 */
@Injectable()
export class AttachmentsService {
  constructor(
    private readonly repository: AttachmentsRepository,
    private readonly access: IssueAccessService,
    private readonly storage: ObjectStorageService,
  ) {}

  /** Список вложений. Видят все участники проекта, включая читателя (US-41, US-46). */
  async list(
    issueKey: string,
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<AttachmentsPage> {
    const context = await this.access.require(issueKey, actor);
    const limit = clampLimit(options.limit, ATTACHMENTS_DEFAULT_LIMIT, ATTACHMENTS_MAX_LIMIT);

    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    const rows = await this.repository.list({
      issueId: context.detail.issue.id,
      limit: limit + 1,
      after: after ?? undefined,
    });

    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const last = items.at(-1);

    return {
      items: await Promise.all(items.map((row) => this.view(row, context, actor))),
      nextCursor: hasMore && last ? encodeCursor([last.createdAt.toISOString(), last.id]) : null,
      total: await this.repository.count(context.detail.issue.id),
      context,
    };
  }

  /** Загрузка файла (US-46). Администратор и участник; читатель — 403. */
  async upload(
    issueKey: string,
    file: UploadedFile,
    actor: AuthenticatedUser,
  ): Promise<AttachmentView> {
    const context = await this.access.require(issueKey, actor);
    if (context.role === 'reader') {
      throw new ForbiddenException({
        code: 'attachment_forbidden',
        message: 'У вас нет прав прикладывать файлы к задачам этого проекта',
      });
    }

    if (file.truncated || file.buffer.byteLength > ATTACHMENT_MAX_BYTES) {
      throw new PayloadTooLargeException({
        code: 'attachment_too_large',
        message: 'Файл больше 25 МБ',
      });
    }
    if (file.buffer.byteLength === 0) {
      throw new BadRequestException({ code: 'attachment_empty', message: 'Файл пустой' });
    }

    const detected = detectFileType(file.buffer);
    const fileName = safeFileName(file.fileName);

    const objectKey = this.storage.buildObjectKey(
      `issues/${context.detail.issue.id}/attachments`,
      detected.extension,
    );
    const stored = await this.storage.put(objectKey, file.buffer, detected.contentType);

    const row = await this.repository.create({
      issueId: context.detail.issue.id,
      objectKey: stored.objectKey,
      fileName,
      contentType: stored.contentType,
      sizeBytes: stored.sizeBytes,
      uploadedByUserId: actor.id,
    });

    return this.view(row, context, actor);
  }

  /** Удаление (US-46). Администратор проекта или тот, кто приложил. */
  async remove(issueKey: string, attachmentId: string, actor: AuthenticatedUser): Promise<void> {
    const context = await this.access.require(issueKey, actor);
    const existing = await this.repository.findById(context.detail.issue.id, attachmentId);
    if (!existing) {
      throw notFound();
    }

    if (!canDelete(existing, context, actor)) {
      throw new ForbiddenException({
        code: 'attachment_forbidden',
        message: 'Удалить вложение может администратор проекта или тот, кто его приложил',
      });
    }

    const deleted = await this.repository.delete({
      issueId: context.detail.issue.id,
      attachmentId,
      actorId: actor.id,
    });
    if (!deleted) {
      throw notFound();
    }

    // Файл — не источник правды: его исчезновение не должно валить удаление записи.
    await this.storage.remove(deleted.objectKey).catch(() => undefined);
  }

  private async view(
    row: AttachmentRow,
    context: IssueContext,
    actor: AuthenticatedUser,
  ): Promise<AttachmentView> {
    const [url, downloadUrl] = await Promise.all([
      this.storage.signedUrl(row.objectKey),
      this.storage.signedUrl(row.objectKey, undefined, { downloadFileName: row.fileName }),
    ]);

    return { row, url, downloadUrl, canDelete: canDelete(row, context, actor) };
  }
}

function canDelete(
  row: { uploadedBy: { id: string } },
  context: IssueContext,
  actor: AuthenticatedUser,
): boolean {
  if (context.role === 'reader') {
    return false;
  }
  return context.role === 'admin' || row.uploadedBy.id === actor.id;
}

function notFound(): NotFoundException {
  return new NotFoundException({ code: 'attachment_not_found', message: 'Вложение не найдено' });
}

function parseCursor(raw: string): { createdAt: Date; id: string } | null {
  const parts = decodeCursor(raw, 2);
  if (!parts) {
    return null;
  }
  const createdAt = new Date(parts[0]!);
  return Number.isNaN(createdAt.getTime()) ? null : { createdAt, id: parts[1]! };
}
