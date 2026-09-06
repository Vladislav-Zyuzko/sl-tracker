import { sql } from 'drizzle-orm';
import {
  type AnyPgColumn,
  boolean,
  check,
  index,
  integer,
  pgTable,
  uniqueIndex,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';
import { createdAt, primaryId, tstz, updatedAt } from './_shared.js';
import { users } from './users.js';

/**
 * Проект — верхний контейнер и единица доступа (permissions.md, раздел 1).
 */
export const projects = pgTable(
  'projects',
  {
    id: primaryId(),
    /** 1–100 символов (US-11). */
    name: varchar('name', { length: 100 }).notNull(),
    /** До 5000 символов, Markdown (US-12). */
    description: varchar('description', { length: 5000 }),
    /**
     * Действующее короткое имя в адресе. Дубль текущей строки `project_slugs`:
     * держим здесь, чтобы не делать join ради каждой ссылки на проект.
     * Инвариант: значение обязано присутствовать в `project_slugs` c `is_current = true`.
     * Внешний ключ гарантирует первую половину инварианта на уровне БД.
     */
    slug: varchar('slug', { length: 40 })
      .notNull()
      .references((): AnyPgColumn => projectSlugs.slug, {
        onDelete: 'restrict',
        onUpdate: 'cascade',
      }),
    /** Ключ объекта обложки в S3. Имя объекта генерирует сервер, не пользователь. */
    coverObjectKey: varchar('cover_object_key', { length: 512 }),
    coverContentType: varchar('cover_content_type', { length: 100 }),
    coverSizeBytes: integer('cover_size_bytes'),
    createdByUserId: uuid('created_by_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('projects_slug_key').on(t.slug),
    // Обложка не больше 5 МБ (US-12); тип проверяется приложением до записи метаданных.
    check(
      'projects_cover_size_check',
      sql`${t.coverSizeBytes} is null or (${t.coverSizeBytes} > 0 and ${t.coverSizeBytes} <= 5242880)`,
    ),
  ],
);

/**
 * Реестр коротких имён проекта: и действующего, и всех прежних (ADR-0005, US-18).
 *
 * Зачем отдельная таблица:
 *  - старый адрес обязан продолжать открывать проект после смены имени;
 *  - прежнее имя не должно достаться другому проекту;
 *  - имена удалённого проекта тоже остаются занятыми — поэтому `project_id`
 *    обнуляется при удалении проекта, а строка остаётся как бронь.
 */
export const projectSlugs = pgTable(
  'project_slugs',
  {
    id: primaryId(),
    projectId: uuid('project_id').references((): AnyPgColumn => projects.id, {
      onDelete: 'set null',
    }),
    slug: varchar('slug', { length: 40 }).notNull().unique('project_slugs_slug_unique'),
    isCurrent: boolean('is_current').notNull().default(false),
    createdAt: createdAt(),
    /** Когда имя перестало быть действующим. У текущего — пусто. */
    retiredAt: tstz('retired_at'),
  },
  (t) => [
    // Глобальная уникальность на весь трекер, включая прежние имена и имена удалённых проектов.
    uniqueIndex('project_slugs_slug_key').on(t.slug),
    // У проекта ровно одно действующее короткое имя.
    uniqueIndex('project_slugs_current_key')
      .on(t.projectId)
      .where(sql`${t.isCurrent}`),
    index('project_slugs_project_id_idx').on(t.projectId),
  ],
);

export type Project = typeof projects.$inferSelect;
export type NewProject = typeof projects.$inferInsert;
export type ProjectSlug = typeof projectSlugs.$inferSelect;
