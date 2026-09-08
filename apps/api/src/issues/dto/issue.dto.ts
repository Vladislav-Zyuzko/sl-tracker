import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PROJECT_ROLES } from '../../projects/index.js';
import type { ProjectRole } from '../../projects/index.js';
import { STATUS_CATEGORIES } from '../../queues/status-category.js';
import type { StatusCategory } from '../../queues/status-category.js';
import { permissionsFor } from '../issue-access.service.js';
import {
  ISSUE_PRIORITY_VALUES,
  ISSUE_STORY_POINTS_VALUES,
  ISSUE_TITLE_MAX_LENGTH,
} from '../issue-fields.js';
import type { IssueLinkRow, IssueListRow, UserRef } from '../issues.repository.js';
import type { IssueView } from '../issues.service.js';

/** Пользователь в полях задачи: ровно то, что нужно отрисовать аватар и имя. */
export class IssueUserDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'Анна Иванова' })
  displayName!: string;

  @ApiProperty({ type: String, nullable: true })
  avatarUrl!: string | null;

  static from(user: UserRef): IssueUserDto {
    return { id: user.id, displayName: user.displayName, avatarUrl: user.avatarUrl };
  }
}

/** Статус задачи. Данные, а не enum: набор берётся из очереди (ADR-0003). */
export class IssueStatusFullDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'in_progress' })
  key!: string;

  @ApiProperty({ example: 'В работе' })
  name!: string;

  @ApiProperty({ enum: STATUS_CATEGORIES })
  category!: StatusCategory;

  @ApiProperty({ example: 2 })
  position!: number;
}

export class IssueLinkDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'https://example.com/spec' })
  url!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description: 'Подпись. Пусто — интерфейс показывает сам адрес (US-47).',
  })
  title!: string | null;

  @ApiProperty({ type: IssueUserDto })
  createdBy!: IssueUserDto;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  static from(link: IssueLinkRow): IssueLinkDto {
    return {
      id: link.id,
      url: link.url,
      title: link.title,
      createdBy: IssueUserDto.from(link.createdBy),
      createdAt: link.createdAt.toISOString(),
    };
  }
}

/** Что запросившему разрешено делать с этой задачей (permissions.md, раздел 2.4). */
export class IssuePermissionsDto {
  @ApiProperty({
    description:
      'Менять поля, название, описание и ссылки. Участник может менять **любую** ' +
      'задачу проекта, а не только свою (D-11). У читателя — `false`.',
  })
  canEdit!: boolean;

  @ApiProperty({ description: 'Удалить задачу. Только у администратора проекта (D-12).' })
  canDelete!: boolean;
}

export class IssueQueueRefDto {
  @ApiProperty({ example: 'DEV' })
  key!: string;

  @ApiProperty({ example: 'Разработка' })
  name!: string;
}

export class IssueProjectRefDto {
  @ApiProperty({ example: 'sladkiy-limit' })
  slug!: string;

  @ApiProperty({ example: 'Сладкий Лимит' })
  name!: string;
}

/**
 * Задача целиком — всё, что нужно её странице, одним ответом.
 *
 * Поля «Создатель» здесь нет намеренно: в интерфейсе задачи это слово не используется,
 * реальный создатель виден только в первой записи истории (D-13, glossary.md).
 */
export class IssueDto {
  @ApiProperty({ example: 'DEV-42', description: 'Публичный ключ задачи, он же адрес' })
  key!: string;

  @ApiProperty({ maxLength: ISSUE_TITLE_MAX_LENGTH, example: 'Починить экспорт CSV' })
  title!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Описание в Markdown. Хранится как текст и рендерится клиентом. **Сервер разметку ' +
      'не санитизирует**: клиент обязан рендерить её без исполнения содержимого — сырой ' +
      'HTML и скрипты не исполняются, ссылки со схемами кроме `http`, `https`, `mailto` ' +
      'не становятся кликабельными (D-22, US-43).',
  })
  description!: string | null;

  @ApiProperty({ type: IssueStatusFullDto })
  status!: IssueStatusFullDto;

  @ApiProperty({
    enum: ISSUE_PRIORITY_VALUES,
    example: 50,
    description:
      'Приоритет: 11 значений от 0 до 100 с шагом 10, больше — важнее. Пустым ' +
      '**не бывает никогда**: состояния «не задан» у поля нет, 0 — это «Низкий» (D-15).',
  })
  priority!: number;

  @ApiProperty({
    type: Number,
    nullable: true,
    enum: ISSUE_STORY_POINTS_VALUES,
    description: 'Сложность по шкале Фибоначчи. `null` — «не оценено» (D-16).',
  })
  storyPoints!: number | null;

  @ApiProperty({
    type: IssueUserDto,
    description: 'Автор задачи. Редактируется, пустым не бывает.',
  })
  author!: IssueUserDto;

  @ApiProperty({
    type: IssueUserDto,
    nullable: true,
    description: 'Исполнитель. `null` — «Не назначен».',
  })
  assignee!: IssueUserDto | null;

  @ApiProperty({ type: IssueQueueRefDto })
  queue!: IssueQueueRefDto;

  @ApiProperty({ type: IssueProjectRefDto })
  project!: IssueProjectRefDto;

  @ApiProperty({ type: [IssueLinkDto], description: 'Внешние ссылки задачи (US-47)' })
  links!: IssueLinkDto[];

  @ApiProperty({ enum: PROJECT_ROLES, description: 'Роль запросившего в проекте задачи' })
  role!: ProjectRole;

  @ApiProperty({ type: IssuePermissionsDto })
  permissions!: IssuePermissionsDto;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  updatedAt!: string;

  static from(view: IssueView): IssueDto {
    const { issue, status, author, assignee } = view.detail;
    return {
      key: issue.key,
      title: issue.title,
      description: issue.description,
      status,
      priority: issue.priority,
      storyPoints: issue.storyPoints,
      author: IssueUserDto.from(author),
      assignee: assignee ? IssueUserDto.from(assignee) : null,
      queue: { key: view.detail.queueKey, name: view.detail.queueName },
      project: { slug: view.detail.projectSlug, name: view.detail.projectName },
      links: view.links.map((link) => IssueLinkDto.from(link)),
      role: view.role,
      permissions: permissionsFor(view.role),
      createdAt: issue.createdAt.toISOString(),
      updatedAt: issue.updatedAt.toISOString(),
    };
  }
}

/** Статус в строке списка: без `position`, строке он не нужен. */
export class IssueRowStatusDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'in_progress' })
  key!: string;

  @ApiProperty({ example: 'В работе' })
  name!: string;

  @ApiProperty({ enum: STATUS_CATEGORIES })
  category!: StatusCategory;
}

/**
 * Строка списка задач очереди — ровно те поля, что рисует таблица
 * (design/queue-issues.md). Ни описания, ни ссылок, ни автора: на 1000 строк
 * это лишние килобайты на каждую прокрутку.
 */
export class IssueRowDto {
  @ApiProperty({ example: 'DEV-42' })
  key!: string;

  @ApiProperty({ example: 'Починить экспорт CSV' })
  title!: string;

  @ApiProperty({ type: IssueRowStatusDto })
  status!: IssueRowStatusDto;

  @ApiProperty({ example: 80 })
  priority!: number;

  @ApiProperty({ type: Number, nullable: true, description: '`null` — «не оценено»' })
  storyPoints!: number | null;

  @ApiProperty({
    type: IssueUserDto,
    nullable: true,
    description: '`null` — «Не назначен»',
  })
  assignee!: IssueUserDto | null;

  static from(row: IssueListRow): IssueRowDto {
    return {
      key: row.key,
      title: row.title,
      status: {
        id: row.statusId,
        key: row.statusKey,
        name: row.statusName,
        category: row.statusCategory,
      },
      priority: row.priority,
      storyPoints: row.storyPoints,
      assignee: row.assigneeId
        ? {
            id: row.assigneeId,
            displayName: row.assigneeDisplayName ?? '',
            avatarUrl: row.assigneeAvatarUrl,
          }
        : null,
    };
  }
}

export class IssueListDto {
  @ApiProperty({ type: [IssueRowDto] })
  items!: IssueRowDto[];

  @ApiProperty({
    type: String,
    nullable: true,
    description: 'Курсор следующей порции. `null` — задачи кончились.',
  })
  nextCursor!: string | null;

  @ApiProperty({
    description: 'Сколько задач подходит под текущие фильтры — счётчик «Показано N».',
  })
  total!: number;

  @ApiPropertyOptional({
    enum: PROJECT_ROLES,
    description: 'Роль запросившего в проекте очереди: по ней прячется кнопка «Создать задачу».',
  })
  role!: ProjectRole;
}
