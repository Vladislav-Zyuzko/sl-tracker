import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PROJECT_ROLES } from '../../projects/index.js';
import type { ProjectRole } from '../../projects/index.js';
import { STATUS_CATEGORIES } from '../status-category.js';
import type { StatusCategory } from '../status-category.js';
import type { QueueListRow, StatusRow } from '../queues.repository.js';
import type { QueueView } from '../queues.service.js';

/** Статус очереди целиком: клиенту нужен `id` для смены статуса задачи (ADR-0003). */
export class QueueStatusDto {
  @ApiProperty({ format: 'uuid', description: 'Идентификатор статуса: его кладут в задачу' })
  id!: string;

  @ApiProperty({ example: 'in_progress', description: 'Машинное имя статуса внутри очереди' })
  key!: string;

  @ApiProperty({ example: 'В работе', description: 'Название для интерфейса' })
  name!: string;

  @ApiProperty({
    enum: STATUS_CATEGORIES,
    description:
      'Категория статуса. Задача считается незавершённой, пока категория не `done`. ' +
      'Опираться нужно на категорию, а не на `key` и не на порядок (ADR-0003).',
  })
  category!: StatusCategory;

  @ApiProperty({ example: 2, description: 'Порядок отображения, начиная с 1' })
  position!: number;

  static from(row: StatusRow): QueueStatusDto {
    return {
      id: row.id,
      key: row.key,
      name: row.name,
      category: row.category,
      position: row.position,
    };
  }
}

export class QueueStatusListDto {
  @ApiProperty({ type: [QueueStatusDto], description: 'В фиксированном порядке отображения' })
  items!: QueueStatusDto[];
}

export class QueueDto {
  @ApiProperty({ example: 'DEV', description: 'Ключ очереди. Уникален на весь трекер, неизменяем' })
  key!: string;

  @ApiProperty({ example: 'Разработка' })
  name!: string;

  @ApiProperty({ type: String, nullable: true, description: 'Markdown, до 1000 символов' })
  description!: string | null;

  @ApiProperty({ example: 'sladkiy-limit', description: 'Короткое имя проекта в адресе' })
  projectSlug!: string;

  @ApiProperty({ example: 'Сладкий Лимит', description: 'Название проекта для хлебных крошек' })
  projectName!: string;

  @ApiProperty({
    example: 12,
    description: 'Незавершённые задачи: те, чей статус не в категории `done` (US-31)',
  })
  openIssueCount!: number;

  @ApiProperty({
    enum: PROJECT_ROLES,
    description:
      'Роль запросившего в проекте, которому принадлежит очередь. Права на очередь ' +
      'наследуются от проекта: прав уровня очереди в MVP нет (permissions.md, п. 3).',
  })
  role!: ProjectRole;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  updatedAt!: string;

  static from(view: QueueView): QueueDto {
    return {
      key: view.queue.key,
      name: view.queue.name,
      description: view.queue.description,
      projectSlug: view.projectSlug,
      projectName: view.projectName,
      openIssueCount: view.openIssueCount,
      role: view.role,
      createdAt: view.queue.createdAt.toISOString(),
      updatedAt: view.queue.updatedAt.toISOString(),
    };
  }

  static fromListRow(
    row: QueueListRow,
    projectSlug: string,
    projectName: string,
    role: ProjectRole,
  ): QueueDto {
    return {
      key: row.key,
      name: row.name,
      description: row.description,
      projectSlug,
      projectName,
      openIssueCount: row.openIssueCount,
      role,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}

/** Ответ создания очереди: статусы по умолчанию отдаются сразу, вторым запросом не ходим. */
export class CreatedQueueDto extends QueueDto {
  @ApiProperty({
    type: [QueueStatusDto],
    description: 'Пять статусов по умолчанию, созданных вместе с очередью (US-60)',
  })
  statuses!: QueueStatusDto[];
}

export class QueueListDto {
  @ApiProperty({ type: [QueueDto], description: 'По названию по возрастанию (US-31)' })
  items!: QueueDto[];

  @ApiPropertyOptional({
    description: 'Очередей у проекта единицы, поэтому список отдаётся целиком, без курсора',
  })
  total!: number;
}
