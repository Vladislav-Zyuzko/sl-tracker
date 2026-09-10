import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  PayloadTooLargeException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit, decodeCursor, encodeCursor } from '../common/index.js';
import type { InvalidFieldReason } from '../common/index.js';
import {
  COVER_ALLOWED_TYPES,
  COVER_MAX_BYTES,
  ObjectStorageService,
  detectImageType,
  extensionFor,
} from '../storage/index.js';
import type { ProjectContext } from './project-access.service.js';
import { ProjectAccessService } from './project-access.service.js';
import { slugBase, validateSlug } from './project-slug.js';
import {
  type MemberPreviewRow,
  type ProjectRole,
  type ProjectRow,
  ProjectsRepository,
} from './projects.repository.js';

/** Проектов у человека единицы, но потолок страницы всё равно жёсткий. */
export const PROJECTS_MAX_LIMIT = 100;
export const PROJECTS_DEFAULT_LIMIT = 50;
/** Сколько участников показывает карточка проекта группой аватаров (design/projects.md). */
const MEMBER_PREVIEW_SIZE = 3;

/** Название проекта: длина проверяется в DTO, пустота — здесь; отказ один и тот же. */
export const PROJECT_NAME_MAX_LENGTH = 100;
export const INVALID_PROJECT_NAME: InvalidFieldReason = {
  code: 'invalid_project_name',
  message: `Название проекта обязательно и не длиннее ${PROJECT_NAME_MAX_LENGTH} символов`,
};

export interface ProjectView {
  project: ProjectRow;
  role: ProjectRole;
  memberCount: number;
  members: MemberPreviewRow[];
  /** Подписанная ссылка на обложку с TTL или `null`, если обложки нет. */
  coverUrl: string | null;
}

export interface ProjectsPage {
  items: ProjectView[];
  nextCursor: string | null;
  total: number;
}

/**
 * Проекты: создание, чтение, изменение, удаление (US-10 … US-18).
 *
 * Здесь же живут инварианты, которых нет в схеме БД: запрет системных коротких имён,
 * правила смены короткого имени, ограничения обложки. Проверка прав — в
 * `ProjectAccessService`, вызывается на каждом действии.
 */
@Injectable()
export class ProjectsService {
  constructor(
    private readonly repository: ProjectsRepository,
    private readonly access: ProjectAccessService,
    private readonly storage: ObjectStorageService,
  ) {}

  /**
   * Создание проекта (US-11). Отдельного права нет: создать проект может любой,
   * кто прошёл список доступа. Создатель становится администратором.
   */
  async create(
    input: { name: string; description?: string | null },
    actor: AuthenticatedUser,
  ): Promise<ProjectView> {
    const name = input.name.trim();
    if (name.length === 0) {
      throw new BadRequestException(INVALID_PROJECT_NAME);
    }

    const project = await this.repository.create({
      name,
      description: normalizeDescription(input.description),
      slugBase: slugBase(name),
      createdByUserId: actor.id,
    });

    return this.view(project, 'admin', 1, [
      {
        projectId: project.id,
        userId: actor.id,
        displayName: actor.displayName,
        avatarUrl: actor.avatarUrl,
        role: 'admin',
      },
    ]);
  }

  /** «Мои проекты» (US-10): только проекты, где пользователь состоит. */
  async listForUser(
    actor: AuthenticatedUser,
    options: { limit?: number; cursor?: string },
  ): Promise<ProjectsPage> {
    const limit = clampLimit(options.limit, PROJECTS_DEFAULT_LIMIT, PROJECTS_MAX_LIMIT);
    const after = options.cursor ? parseCursor(options.cursor) : null;
    if (options.cursor && !after) {
      throw new BadRequestException({ code: 'invalid_cursor', message: 'Некорректный курсор' });
    }

    // На одну строку больше страницы: так видно, есть ли следующая, без второго запроса.
    const rows = await this.repository.listForUser({
      userId: actor.id,
      limit: limit + 1,
      after: after ?? undefined,
    });
    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    // Участники для превью — одним запросом на всю страницу, а не по запросу на карточку.
    const previews = await this.repository.memberPreviews(
      page.map((row) => row.id),
      MEMBER_PREVIEW_SIZE,
    );
    const byProject = new Map<string, MemberPreviewRow[]>();
    for (const preview of previews) {
      const list = byProject.get(preview.projectId) ?? [];
      list.push(preview);
      byProject.set(preview.projectId, list);
    }

    const items = await Promise.all(
      page.map(({ role, memberCount, ...project }) =>
        this.view(project, role, memberCount, byProject.get(project.id) ?? []),
      ),
    );
    const last = page.at(-1);

    return {
      items,
      nextCursor: hasMore && last ? encodeCursor([last.id, last.name]) : null,
      total: await this.repository.countForUser(actor.id),
    };
  }

  /**
   * Один проект по короткому имени. Прежнее короткое имя тоже открывает проект:
   * в ответе всегда действующее значение `slug`, и клиент заменяет им адрес (US-18).
   */
  async getBySlug(slug: string, actor: AuthenticatedUser): Promise<ProjectView> {
    const context = await this.access.require(slug, actor);
    return this.viewOf(context);
  }

  /** Название и описание меняет только администратор; короткое имя при этом не меняется. */
  async updateDetails(
    slug: string,
    patch: { name?: string; description?: string | null },
    actor: AuthenticatedUser,
  ): Promise<ProjectView> {
    const context = await this.access.requireAdmin(slug, actor);

    const changes: { name?: string; description?: string | null } = {};
    if (patch.name !== undefined) {
      const name = patch.name.trim();
      if (name.length === 0) {
        throw new BadRequestException(INVALID_PROJECT_NAME);
      }
      changes.name = name;
    }
    if (patch.description !== undefined) {
      changes.description = normalizeDescription(patch.description);
    }

    if (Object.keys(changes).length === 0) {
      return this.viewOf(context);
    }

    const updated = await this.repository.updateDetails(context.project.id, changes);
    if (!updated) {
      throw new NotFoundException({ code: 'project_not_found', message: 'Проект не найден' });
    }

    return this.viewOf({ ...context, project: updated });
  }

  /**
   * Смена короткого имени вручную (US-18). Прежнее имя остаётся занятым навсегда
   * и продолжает открывать этот же проект.
   */
  async changeSlug(slug: string, next: string, actor: AuthenticatedUser): Promise<ProjectView> {
    const context = await this.access.requireAdmin(slug, actor);
    const value = next.trim();

    const problem = validateSlug(value);
    if (problem === 'invalid_slug') {
      throw new BadRequestException({
        code: 'invalid_slug',
        message: 'Допустимы строчные латинские буквы, цифры и дефис',
      });
    }
    if (problem === 'reserved_slug') {
      throw new ConflictException({
        code: 'reserved_slug',
        message: 'Этот адрес зарезервирован приложением',
      });
    }

    if (value === context.project.slug) {
      return this.viewOf(context);
    }

    const updated = await this.repository.changeSlug(context.project.id, value);
    if (updated === 'taken') {
      // Каким именно проектом занято — не сообщаем: это раскрыло бы чужой проект.
      throw new ConflictException({ code: 'slug_taken', message: 'Такой адрес уже занят' });
    }

    return this.viewOf({ ...context, project: updated });
  }

  /** Удаление проекта (US-17). Доступно только администратору. */
  async remove(slug: string, actor: AuthenticatedUser): Promise<void> {
    const context = await this.access.requireAdmin(slug, actor);
    const coverKey = context.project.coverObjectKey;

    const deleted = await this.repository.delete(context.project.id);
    if (!deleted) {
      throw new NotFoundException({ code: 'project_not_found', message: 'Проект не найден' });
    }

    if (coverKey) {
      // Файл — не источник правды: его исчезновение не должно валить удаление проекта.
      await this.storage.remove(coverKey).catch(() => undefined);
    }
  }

  /**
   * Загрузка обложки (US-12): PNG, JPEG или WEBP до 5 МБ. Тип определяется
   * по содержимому файла, имя объекта генерирует сервер.
   */
  async setCover(
    slug: string,
    file: { buffer: Buffer; truncated: boolean },
    actor: AuthenticatedUser,
  ): Promise<ProjectView> {
    const context = await this.access.requireAdmin(slug, actor);

    if (file.truncated || file.buffer.byteLength > COVER_MAX_BYTES) {
      throw new PayloadTooLargeException({
        code: 'cover_too_large',
        message: 'Допустимы PNG, JPEG, WEBP до 5 МБ',
      });
    }

    const type = detectImageType(file.buffer);
    if (!type) {
      throw new BadRequestException({
        code: 'cover_unsupported_type',
        message: 'Допустимы PNG, JPEG, WEBP до 5 МБ',
        allowedTypes: COVER_ALLOWED_TYPES,
      });
    }

    const objectKey = this.storage.buildObjectKey(
      `projects/${context.project.id}/cover`,
      extensionFor(type),
    );
    const stored = await this.storage.put(objectKey, file.buffer, type);

    const previousKey = context.project.coverObjectKey;
    const updated = await this.repository.setCover(context.project.id, stored);
    if (!updated) {
      throw new NotFoundException({ code: 'project_not_found', message: 'Проект не найден' });
    }

    if (previousKey && previousKey !== objectKey) {
      // Прежний файл больше ни на что не ссылается: держать его в хранилище незачем.
      await this.storage.remove(previousKey).catch(() => undefined);
    }

    return this.viewOf({ ...context, project: updated });
  }

  /** Удаление обложки (US-12): в списке и в шапке снова показывается заглушка. */
  async removeCover(slug: string, actor: AuthenticatedUser): Promise<ProjectView> {
    const context = await this.access.requireAdmin(slug, actor);
    const previousKey = context.project.coverObjectKey;

    const updated = await this.repository.setCover(context.project.id, null);
    if (!updated) {
      throw new NotFoundException({ code: 'project_not_found', message: 'Проект не найден' });
    }
    if (previousKey) {
      await this.storage.remove(previousKey).catch(() => undefined);
    }

    return this.viewOf({ ...context, project: updated });
  }

  private async viewOf(context: ProjectContext): Promise<ProjectView> {
    const previews = await this.repository.memberPreviews(
      [context.project.id],
      MEMBER_PREVIEW_SIZE,
    );
    return this.view(context.project, context.role, context.memberCount, previews);
  }

  private async view(
    project: ProjectRow,
    role: ProjectRole,
    memberCount: number,
    members: MemberPreviewRow[],
  ): Promise<ProjectView> {
    return {
      project,
      role,
      memberCount,
      members,
      // Ссылка подписанная и с TTL: бакет не публичный, и прямая ссылка на объект
      // без подписи ничего не отдаёт (US-12, D-21).
      coverUrl: project.coverObjectKey
        ? await this.storage.signedUrl(project.coverObjectKey)
        : null,
    };
  }
}

function normalizeDescription(raw: string | null | undefined): string | null {
  if (raw === null || raw === undefined) {
    return null;
  }
  const value = raw.trim();
  return value.length > 0 ? value : null;
}

/** Свободный текст в курсоре идёт последним — см. `decodeCursor`. */
function parseCursor(raw: string): { name: string; id: string } | null {
  const parts = decodeCursor(raw, 2);
  return parts ? { id: parts[0]!, name: parts[1]! } : null;
}
