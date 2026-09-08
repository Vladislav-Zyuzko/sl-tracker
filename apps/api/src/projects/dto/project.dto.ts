import { ApiProperty } from '@nestjs/swagger';
import type { ProjectView } from '../projects.service.js';
import type { ProjectRole } from '../projects.repository.js';

export const PROJECT_ROLES = ['admin', 'member', 'reader'] as const;

/** Участник в группе аватаров на карточке проекта (US-10). */
export class ProjectMemberPreviewDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'Анна Иванова' })
  displayName!: string;

  @ApiProperty({ type: String, nullable: true })
  avatarUrl!: string | null;

  @ApiProperty({ enum: PROJECT_ROLES })
  role!: ProjectRole;
}

export class ProjectDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    example: 'sladkiy-limit',
    description:
      'Действующее короткое имя в адресе. Если проект запрошен по прежнему короткому ' +
      'имени, здесь всё равно действующее — клиенту следует заменить адрес в строке ' +
      'браузера на него (US-18).',
  })
  slug!: string;

  @ApiProperty({ example: 'Сладкий лимит', maxLength: 100 })
  name!: string;

  @ApiProperty({ type: String, nullable: true, description: 'Markdown, до 5000 символов' })
  description!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Подписанная ссылка на обложку со сроком жизни 10 минут. Бакет не публичный: ' +
      'ссылка без подписи содержимое не отдаёт. `null` — обложки нет, клиент рисует заглушку.',
  })
  coverUrl!: string | null;

  @ApiProperty({
    enum: PROJECT_ROLES,
    description: 'Роль текущего пользователя в этом проекте (permissions.md, 2.1).',
  })
  role!: ProjectRole;

  @ApiProperty({ description: 'Сколько всего участников в проекте' })
  memberCount!: number;

  @ApiProperty({
    type: [ProjectMemberPreviewDto],
    description: 'Первые участники для группы аватаров: администраторы, затем по имени.',
  })
  members!: ProjectMemberPreviewDto[];

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  updatedAt!: string;

  static from(view: ProjectView): ProjectDto {
    return {
      id: view.project.id,
      slug: view.project.slug,
      name: view.project.name,
      description: view.project.description,
      coverUrl: view.coverUrl,
      role: view.role,
      memberCount: view.memberCount,
      members: view.members.map((member) => ({
        id: member.userId,
        displayName: member.displayName,
        avatarUrl: member.avatarUrl,
        role: member.role,
      })),
      createdAt: view.project.createdAt.toISOString(),
      updatedAt: view.project.updatedAt.toISOString(),
    };
  }
}

export class ProjectListDto {
  @ApiProperty({ type: [ProjectDto], description: 'Проекты пользователя, по названию' })
  items!: ProjectDto[];

  @ApiProperty({
    type: String,
    nullable: true,
    description: 'Курсор следующей страницы. `null` — проектов больше нет.',
  })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего проектов у пользователя' })
  total!: number;
}
