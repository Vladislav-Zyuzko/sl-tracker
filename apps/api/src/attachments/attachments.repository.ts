import { randomUUID } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { and, asc, desc, eq, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import { attachments, issueHistory, users } from '../database/schema/index.js';
import type { UserRef } from '../issues/index.js';

export interface AttachmentRow {
  id: string;
  issueId: string;
  objectKey: string;
  fileName: string;
  contentType: string;
  sizeBytes: number;
  uploadedBy: UserRef;
  createdAt: Date;
}

/**
 * SQL вложений. Сам файл лежит в MinIO — сюда попадают только метаданные и ключ
 * объекта, который сгенерировал сервер (US-46).
 *
 * Добавление и удаление вложения пишутся в историю задачи **в той же транзакции**,
 * что и изменение метаданных: история не должна расходиться со списком файлов.
 */
@Injectable()
export class AttachmentsRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  async create(input: {
    issueId: string;
    objectKey: string;
    fileName: string;
    contentType: string;
    sizeBytes: number;
    uploadedByUserId: string;
  }): Promise<AttachmentRow> {
    return this.db.transaction(async (tx) => {
      const [created] = await tx.insert(attachments).values(input).returning({
        id: attachments.id,
        issueId: attachments.issueId,
        objectKey: attachments.objectKey,
        fileName: attachments.fileName,
        contentType: attachments.contentType,
        sizeBytes: attachments.sizeBytes,
        createdAt: attachments.createdAt,
      });

      await tx.insert(issueHistory).values({
        issueId: input.issueId,
        actorId: input.uploadedByUserId,
        kind: 'attachment_added',
        groupId: randomUUID(),
        // В истории — имя файла, а не ключ объекта: ключ человеку ничего не говорит.
        oldValue: null,
        newValue: input.fileName,
        oldRefId: null,
        newRefId: null,
      });

      const [uploader] = await tx
        .select({ id: users.id, displayName: users.displayName, avatarUrl: users.avatarUrl })
        .from(users)
        .where(eq(users.id, input.uploadedByUserId))
        .limit(1);

      return { ...created!, uploadedBy: uploader! };
    });
  }

  /**
   * Удаление вместе с записью истории. Возвращает ключ объекта: файл из хранилища
   * убирает сервис — уже после того, как транзакция закоммитилась.
   */
  async delete(input: {
    issueId: string;
    attachmentId: string;
    actorId: string;
  }): Promise<{ objectKey: string } | null> {
    return this.db.transaction(async (tx) => {
      const deleted = await tx
        .delete(attachments)
        .where(and(eq(attachments.id, input.attachmentId), eq(attachments.issueId, input.issueId)))
        .returning({ objectKey: attachments.objectKey, fileName: attachments.fileName });

      if (deleted.length === 0) {
        return null;
      }

      await tx.insert(issueHistory).values({
        issueId: input.issueId,
        actorId: input.actorId,
        kind: 'attachment_removed',
        groupId: randomUUID(),
        oldValue: deleted[0]!.fileName,
        newValue: null,
        oldRefId: null,
        newRefId: null,
      });

      return { objectKey: deleted[0]!.objectKey };
    });
  }

  async findById(issueId: string, attachmentId: string): Promise<AttachmentRow | null> {
    const [row] = await this.db
      .select(SELECTION)
      .from(attachments)
      .innerJoin(users, eq(users.id, attachments.uploadedByUserId))
      .where(and(eq(attachments.id, attachmentId), eq(attachments.issueId, issueId)))
      .limit(1);
    return row ? shape(row) : null;
  }

  /**
   * Вложения задачи. Загрузивший приезжает join'ом: список показывает «кто и когда
   * приложил», и отдельный запрос на каждую строку был бы N+1.
   */
  async list(options: {
    issueId: string;
    limit: number;
    after?: { createdAt: Date; id: string };
  }): Promise<AttachmentRow[]> {
    const conditions = [eq(attachments.issueId, options.issueId)];
    if (options.after) {
      conditions.push(
        sql`(${attachments.createdAt}, ${attachments.id}) > (${options.after.createdAt}, ${options.after.id}::uuid)`,
      );
    }

    const rows = await this.db
      .select(SELECTION)
      .from(attachments)
      .innerJoin(users, eq(users.id, attachments.uploadedByUserId))
      .where(and(...conditions))
      .orderBy(asc(attachments.createdAt), asc(attachments.id))
      .limit(options.limit);

    return rows.map(shape);
  }

  async count(issueId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(attachments)
      .where(eq(attachments.issueId, issueId));
    return row?.value ?? 0;
  }

  /** Ключи объектов задачи — нужны, когда файлы надо убрать из хранилища пачкой. */
  async objectKeysOf(issueId: string): Promise<string[]> {
    const rows = await this.db
      .select({ objectKey: attachments.objectKey })
      .from(attachments)
      .where(eq(attachments.issueId, issueId))
      .orderBy(desc(attachments.createdAt));
    return rows.map((row) => row.objectKey);
  }
}

const SELECTION = {
  id: attachments.id,
  issueId: attachments.issueId,
  objectKey: attachments.objectKey,
  fileName: attachments.fileName,
  contentType: attachments.contentType,
  sizeBytes: attachments.sizeBytes,
  createdAt: attachments.createdAt,
  uploaderId: users.id,
  uploaderDisplayName: users.displayName,
  uploaderAvatarUrl: users.avatarUrl,
};

interface SelectedRow {
  id: string;
  issueId: string;
  objectKey: string;
  fileName: string;
  contentType: string;
  sizeBytes: number;
  createdAt: Date;
  uploaderId: string;
  uploaderDisplayName: string;
  uploaderAvatarUrl: string | null;
}

function shape(row: SelectedRow): AttachmentRow {
  const { uploaderId, uploaderDisplayName, uploaderAvatarUrl, ...attachment } = row;
  return {
    ...attachment,
    uploadedBy: {
      id: uploaderId,
      displayName: uploaderDisplayName,
      avatarUrl: uploaderAvatarUrl,
    },
  };
}
