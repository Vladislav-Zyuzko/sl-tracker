import { sql } from 'drizzle-orm';
import { bigint, check, index, pgTable, uniqueIndex, uuid, varchar } from 'drizzle-orm/pg-core';
import { createdAt, primaryId } from './_shared.js';
import { issues } from './issues.js';
import { users } from './users.js';

/**
 * Метаданные вложения. Сам файл лежит в MinIO по ключу `objectKey`.
 *
 * Имя объекта генерирует сервер, а не пользователь: иначе имя из браузера попадает
 * в путь бакета со всем, что в нём бывает. Содержимое отдаётся только участникам
 * проекта — подписанной ссылкой с TTL, а не публичным бакетом (US-46).
 */
export const attachments = pgTable(
  'attachments',
  {
    id: primaryId(),
    issueId: uuid('issue_id')
      .notNull()
      .references(() => issues.id, { onDelete: 'cascade' }),
    /** Ключ объекта в S3. Генерируется сервером. */
    objectKey: varchar('object_key', { length: 512 }).notNull(),
    /** Исходное имя файла — только для показа и скачивания. */
    fileName: varchar('file_name', { length: 255 }).notNull(),
    contentType: varchar('content_type', { length: 255 }).notNull(),
    /** До 25 МБ (D-21). Проверяется и при загрузке, и здесь. */
    sizeBytes: bigint('size_bytes', { mode: 'number' }).notNull(),
    uploadedByUserId: uuid('uploaded_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
  },
  (t) => [
    uniqueIndex('attachments_object_key_key').on(t.objectKey),
    index('attachments_issue_id_created_at_idx').on(t.issueId, t.createdAt),
    check('attachments_size_check', sql`${t.sizeBytes} > 0 and ${t.sizeBytes} <= 26214400`),
  ],
);

export type Attachment = typeof attachments.$inferSelect;
export type NewAttachment = typeof attachments.$inferInsert;
