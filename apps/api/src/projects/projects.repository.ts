import { Inject, Injectable } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import { projectMembers, projectSlugs, projects } from '../database/schema/index.js';
import { slugCandidate } from './project-slug.js';

export type ProjectRole = 'admin' | 'member' | 'reader';

export interface ProjectRow {
  id: string;
  name: string;
  description: string | null;
  slug: string;
  coverObjectKey: string | null;
  createdByUserId: string;
  createdAt: Date;
  updatedAt: Date;
}

/** Проект в списке «Мои проекты»: роль текущего пользователя и число участников. */
export interface ProjectListRow extends ProjectRow {
  role: ProjectRole;
  memberCount: number;
}

/** Участник для превью карточки проекта: аватары первых нескольких человек (US-10). */
export interface MemberPreviewRow {
  projectId: string;
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  role: ProjectRole;
}

/** Что нашлось по короткому имени: сам проект, роль пользователя и актуальность имени. */
export interface ProjectLookup {
  project: ProjectRow;
  role: ProjectRole | null;
  memberCount: number;
  /** `false` — обратились по прежнему короткому имени, клиенту нужно заменить адрес. */
  slugIsCurrent: boolean;
}

const PROJECT_COLUMNS = {
  id: projects.id,
  name: projects.name,
  description: projects.description,
  slug: projects.slug,
  coverObjectKey: projects.coverObjectKey,
  createdByUserId: projects.createdByUserId,
  createdAt: projects.createdAt,
  updatedAt: projects.updatedAt,
};

const memberCountSql = sql<number>`(
  select count(*)::int from project_members pm where pm.project_id = projects.id
)`;

/**
 * SQL проектов. Ни одной проверки прав здесь нет: репозиторий отдаёт роль
 * пользователя в проекте, а решение «показать или ответить 404» принимает сервис.
 */
@Injectable()
export class ProjectsRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Создаёт проект вместе с бронью короткого имени и членством создателя —
   * в одной транзакции (US-11: создатель сразу администратор и единственный участник).
   *
   * Уникальность короткого имени обеспечивает уникальный индекс `project_slugs.slug`,
   * а не предварительный `select`: два одновременных создания с одинаковым названием
   * иначе выбрали бы одно и то же имя. Кандидаты перебираются до первого, который
   * удалось вставить.
   */
  async create(input: {
    name: string;
    description: string | null;
    slugBase: string;
    createdByUserId: string;
    maxSlugAttempts?: number;
  }): Promise<ProjectRow> {
    const maxAttempts = input.maxSlugAttempts ?? 25;

    return this.db.transaction(async (tx) => {
      let slug: string | null = null;
      for (let attempt = 1; attempt <= maxAttempts && slug === null; attempt += 1) {
        const candidate = slugCandidate(input.slugBase, attempt);
        const reserved = await tx
          .insert(projectSlugs)
          .values({ slug: candidate, projectId: null, isCurrent: false })
          .onConflictDoNothing()
          .returning({ slug: projectSlugs.slug });
        slug = reserved[0]?.slug ?? null;
      }

      if (slug === null) {
        // Столько занятых кандидатов подряд означает не коллизию, а что-то странное:
        // лучше честно упасть, чем крутить перебор бесконечно.
        throw new Error('Не удалось подобрать свободное короткое имя проекта');
      }

      const [created] = await tx
        .insert(projects)
        .values({
          name: input.name,
          description: input.description,
          slug,
          createdByUserId: input.createdByUserId,
        })
        .returning(PROJECT_COLUMNS);

      await tx
        .update(projectSlugs)
        .set({ projectId: created!.id, isCurrent: true })
        .where(eq(projectSlugs.slug, slug));

      await tx
        .insert(projectMembers)
        .values({ projectId: created!.id, userId: input.createdByUserId, role: 'admin' });

      return created!;
    });
  }

  /**
   * Проект по короткому имени — действующему или прежнему (US-18: старый адрес
   * продолжает открывать проект). Роль пользователя приезжает тем же запросом:
   * отдельный поход за членством означал бы второй запрос на каждое открытие проекта.
   */
  async findBySlugForUser(slug: string, userId: string): Promise<ProjectLookup | null> {
    const [row] = await this.db
      .select({
        ...PROJECT_COLUMNS,
        memberCount: memberCountSql,
        role: projectMembers.role,
        slugIsCurrent: projectSlugs.isCurrent,
      })
      .from(projectSlugs)
      .innerJoin(projects, eq(projects.id, projectSlugs.projectId))
      .leftJoin(
        projectMembers,
        and(eq(projectMembers.projectId, projects.id), eq(projectMembers.userId, userId)),
      )
      .where(eq(projectSlugs.slug, slug))
      .limit(1);

    if (!row) {
      return null;
    }

    const { role, slugIsCurrent, memberCount, ...project } = row;
    return { project, role, memberCount, slugIsCurrent };
  }

  /** Проект по идентификатору — нужен там, где короткое имя уже разобрано. */
  async findById(projectId: string): Promise<ProjectRow | null> {
    const [row] = await this.db
      .select(PROJECT_COLUMNS)
      .from(projects)
      .where(eq(projects.id, projectId))
      .limit(1);
    return row ?? null;
  }

  /**
   * «Мои проекты» (US-10): только те, где пользователь состоит. Сортировка по названию,
   * курсор — пара `(name, id)`, потому что названия не уникальны.
   */
  async listForUser(options: {
    userId: string;
    limit: number;
    after?: { name: string; id: string };
  }): Promise<ProjectListRow[]> {
    const conditions = [eq(projectMembers.userId, options.userId)];
    if (options.after) {
      conditions.push(
        sql`(projects.name, projects.id) > (${options.after.name}, ${options.after.id}::uuid)`,
      );
    }

    return this.db
      .select({ ...PROJECT_COLUMNS, role: projectMembers.role, memberCount: memberCountSql })
      .from(projectMembers)
      .innerJoin(projects, eq(projects.id, projectMembers.projectId))
      .where(and(...conditions))
      .orderBy(asc(projects.name), asc(projects.id))
      .limit(options.limit);
  }

  async countForUser(userId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(projectMembers)
      .where(eq(projectMembers.userId, userId));
    return row?.value ?? 0;
  }

  /**
   * Первые несколько участников каждого из переданных проектов — одним запросом
   * на всю страницу, а не по запросу на карточку (иначе это N+1 на списке проектов).
   * Порядок внутри проекта тот же, что на вкладке «Участники»: администраторы первыми.
   */
  async memberPreviews(projectIds: string[], perProject: number): Promise<MemberPreviewRow[]> {
    if (projectIds.length === 0) {
      return [];
    }

    const ids = sql.join(
      projectIds.map((id) => sql`${id}::uuid`),
      sql`, `,
    );

    const result = await this.db.execute<{
      project_id: string;
      user_id: string;
      display_name: string;
      avatar_url: string | null;
      role: ProjectRole;
    }>(sql`
      select project_id, user_id, display_name, avatar_url, role
      from (
        select
          pm.project_id,
          u.id as user_id,
          u.display_name,
          u.avatar_url,
          pm.role,
          row_number() over (
            partition by pm.project_id
            order by (pm.role = 'admin') desc, u.display_name asc, u.id asc
          ) as rn
        from project_members pm
        join users u on u.id = pm.user_id
        where pm.project_id in (${ids})
      ) ranked
      where rn <= ${perProject}
    `);

    return result.rows.map((row) => ({
      projectId: row.project_id,
      userId: row.user_id,
      displayName: row.display_name,
      avatarUrl: row.avatar_url,
      role: row.role,
    }));
  }

  async updateDetails(
    projectId: string,
    patch: { name?: string; description?: string | null },
  ): Promise<ProjectRow | null> {
    const [row] = await this.db
      .update(projects)
      .set(patch)
      .where(eq(projects.id, projectId))
      .returning(PROJECT_COLUMNS);
    return row ?? null;
  }

  /**
   * Смена короткого имени (US-18). Прежнее имя остаётся в `project_slugs` навсегда:
   * оно продолжает открывать проект и не может достаться другому проекту.
   *
   * `taken` — имя уже занято кем-то, включая прежние имена и имена удалённых проектов.
   */
  async changeSlug(projectId: string, slug: string): Promise<ProjectRow | 'taken'> {
    return this.db.transaction(async (tx) => {
      const reserved = await tx
        .insert(projectSlugs)
        .values({ slug, projectId, isCurrent: false })
        .onConflictDoNothing()
        .returning({ slug: projectSlugs.slug });

      if (reserved.length === 0) {
        return 'taken' as const;
      }

      await tx
        .update(projectSlugs)
        .set({ isCurrent: false, retiredAt: new Date() })
        .where(and(eq(projectSlugs.projectId, projectId), eq(projectSlugs.isCurrent, true)));

      await tx
        .update(projectSlugs)
        .set({ isCurrent: true, retiredAt: null })
        .where(eq(projectSlugs.slug, slug));

      const [updated] = await tx
        .update(projects)
        .set({ slug })
        .where(eq(projects.id, projectId))
        .returning(PROJECT_COLUMNS);

      return updated!;
    });
  }

  /**
   * Удаление проекта (US-17). Очереди, задачи, комментарии и вложения уходят каскадом;
   * строки `project_slugs` и `queue_keys` остаются как бронь — их значения не выдаются
   * повторно (D-25, US-18).
   */
  async delete(projectId: string): Promise<boolean> {
    const deleted = await this.db
      .delete(projects)
      .where(eq(projects.id, projectId))
      .returning({ id: projects.id });
    return deleted.length > 0;
  }

  async setCover(
    projectId: string,
    cover: { objectKey: string; contentType: string; sizeBytes: number } | null,
  ): Promise<ProjectRow | null> {
    const [row] = await this.db
      .update(projects)
      .set({
        coverObjectKey: cover?.objectKey ?? null,
        coverContentType: cover?.contentType ?? null,
        coverSizeBytes: cover?.sizeBytes ?? null,
      })
      .where(eq(projects.id, projectId))
      .returning(PROJECT_COLUMNS);
    return row ?? null;
  }
}
