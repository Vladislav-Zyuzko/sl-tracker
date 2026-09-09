import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import type { MemberRow } from '../members.repository.js';
import type { ProjectRole } from '../projects.repository.js';
import { MEMBERS_MAX_LIMIT } from '../members.service.js';
import { PROJECT_ROLES } from './project.dto.js';

export class ProjectMemberDto {
  @ApiProperty({ format: 'uuid', description: 'Идентификатор пользователя' })
  userId!: string;

  @ApiProperty({ example: 'Анна Иванова' })
  displayName!: string;

  @ApiProperty({ example: 'anna@example.com' })
  email!: string;

  @ApiProperty({ type: String, nullable: true })
  avatarUrl!: string | null;

  @ApiProperty({ enum: PROJECT_ROLES })
  role!: ProjectRole;

  @ApiProperty({ type: String, format: 'date-time', description: 'Когда вступил в проект' })
  joinedAt!: string;

  @ApiProperty({ description: 'Это текущий пользователь: в списке помечается «(вы)»' })
  isSelf!: boolean;

  static from(row: MemberRow, currentUserId: string): ProjectMemberDto {
    return {
      userId: row.userId,
      displayName: row.displayName,
      email: row.email,
      avatarUrl: row.avatarUrl,
      role: row.role,
      joinedAt: row.joinedAt.toISOString(),
      isSelf: row.userId === currentUserId,
    };
  }
}

export class ProjectMemberListDto {
  @ApiProperty({
    type: [ProjectMemberDto],
    description: 'Сначала администраторы, дальше по имени (design/screens/project.md)',
  })
  items!: ProjectMemberDto[];

  @ApiProperty({ type: String, nullable: true })
  nextCursor!: string | null;

  @ApiProperty({
    description:
      'Всего участников в проекте, а при поиске (`q`) — сколько участников ему ' +
      'соответствует, то есть длина всего отфильтрованного списка, а не страницы.',
  })
  total!: number;
}

export class UpdateMemberRoleDto {
  @ApiProperty({
    enum: PROJECT_ROLES,
    description:
      'Новая роль. Понизить последнего администратора нельзя — 409 `last_project_admin` ' +
      '(permissions.md, п. 7).',
  })
  @IsEnum(PROJECT_ROLES)
  role!: ProjectRole;
}

export class RemoveMemberResultDto {
  @ApiProperty({
    description:
      'Сколько задач осталось без исполнителя: у задач исключённого поле «Исполнитель» ' +
      'очищается, и на каждую пишется запись истории (D-31).',
    example: 3,
  })
  unassignedIssues!: number;
}

export class ListMembersQueryDto {
  @ApiPropertyOptional({
    description:
      'Поиск по составу проекта: подстрока в имени или в email, без учёта регистра. ' +
      'Пустая строка и пробелы равнозначны отсутствию параметра. Порядок и курсор ' +
      'те же, что и без поиска, поэтому при переходе на следующую страницу `q` ' +
      'нужно передавать вместе с `cursor`.',
    example: 'ан',
  })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  q?: string;

  @ApiPropertyOptional({ minimum: 1, maximum: MEMBERS_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MEMBERS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей страницы из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
