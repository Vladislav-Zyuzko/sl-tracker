import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsIn, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import type { ProjectRole } from '../../projects/index.js';
import { PROJECT_ROLES } from '../../projects/dto/project.dto.js';
import {
  INVITATION_DEFAULT_LIFETIME_DAYS,
  INVITATION_LIFETIMES_DAYS,
  type InvitationLifetimeDays,
  type InvitationState,
} from '../invitation-state.js';
import type { InvitableRole } from '../invitations.repository.js';
import { INVITATIONS_MAX_LIMIT, type InvitationView } from '../invitations.service.js';

/** Роли, которые можно выдать ссылкой. Администратора через приглашение нельзя (D-05). */
export const INVITABLE_ROLES = ['member', 'reader'] as const;
export const INVITATION_STATES = ['active', 'expired', 'revoked'] as const;

export class InvitationAuthorDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ type: String, nullable: true, example: 'Анна Иванова' })
  displayName!: string | null;
}

export class InvitationDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    enum: INVITABLE_ROLES,
    description: 'Роль, которую получит вступивший. Администратора выдать нельзя (D-05).',
  })
  role!: InvitableRole;

  @ApiProperty({
    enum: INVITATION_STATES,
    description:
      'Вычисляется из срока и отметки об отзыве, отдельно не хранится. Истёкшие ' +
      'и отозванные остаются в списке, но повторно активировать их нельзя (US-22).',
  })
  state!: InvitationState;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Полная ссылка-приглашение. Заполнена только у действующего приглашения: ' +
      'у истёкшего и отозванного её нет и копировать нечего (US-22).',
  })
  url!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  expiresAt!: string;

  @ApiProperty({
    enum: INVITATION_LIFETIMES_DAYS,
    description:
      'Срок жизни ссылки в днях — тот, что выбрал администратор при создании. Отдаётся ' +
      'полем, а не выводится клиентом из разницы дат: строка списка показывает ' +
      '«Участник · 7 дней · до 19 фев» (design/screens/project.md), и вычитание дат ' +
      'у истёкшего приглашения дало бы не то, что выбирали.',
    example: 7,
  })
  lifetimeDays!: number;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  revokedAt!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({ type: InvitationAuthorDto, description: 'Кто создал приглашение' })
  createdBy!: InvitationAuthorDto;

  @ApiProperty({ description: 'Сколько человек вступило по этой ссылке (US-22)' })
  acceptedCount!: number;

  static from(view: InvitationView): InvitationDto {
    return {
      id: view.row.id,
      role: view.row.role,
      state: view.state,
      url: view.url,
      expiresAt: view.row.expiresAt.toISOString(),
      lifetimeDays: view.lifetimeDays,
      revokedAt: view.row.revokedAt ? view.row.revokedAt.toISOString() : null,
      createdAt: view.row.createdAt.toISOString(),
      createdBy: {
        id: view.row.createdByUserId,
        displayName: view.row.createdByDisplayName,
      },
      acceptedCount: view.row.acceptedCount,
    };
  }
}

export class InvitationListDto {
  @ApiProperty({ type: [InvitationDto], description: 'Сначала новые' })
  items!: InvitationDto[];

  @ApiProperty({ type: String, nullable: true })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего приглашений у проекта, включая истёкшие и отозванные' })
  total!: number;
}

export class CreateInvitationDto {
  @ApiProperty({
    enum: INVITABLE_ROLES,
    description: 'Роль для тех, кто вступит. Роли «администратор» в списке нет (D-05).',
  })
  @IsEnum(INVITABLE_ROLES)
  role!: InvitableRole;

  @ApiPropertyOptional({
    enum: INVITATION_LIFETIMES_DAYS,
    default: INVITATION_DEFAULT_LIFETIME_DAYS,
    description: 'Срок жизни ссылки в днях. Бессрочных приглашений нет (US-20).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsIn([...INVITATION_LIFETIMES_DAYS])
  expiresInDays?: InvitationLifetimeDays;
}

export class ListInvitationsQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: INVITATIONS_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(INVITATIONS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей страницы из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}

export class InvitationPreviewDto {
  @ApiProperty({ example: 'Сладкий лимит' })
  projectName!: string;

  @ApiProperty({ example: 'sladkiy-limit' })
  projectSlug!: string;

  @ApiProperty({ type: String, nullable: true, description: 'Подписанная ссылка на обложку' })
  coverUrl!: string | null;

  @ApiProperty({
    enum: PROJECT_ROLES,
    description:
      'Роль, которую человек получит. Если он уже участник — его текущая роль: ' +
      'приглашение её не меняет и не понижает (US-21).',
  })
  role!: ProjectRole;

  @ApiProperty({
    description:
      'Пользователь уже состоит в проекте: экран подтверждения не показывается, ' +
      'клиент сразу открывает проект (US-21).',
  })
  alreadyMember!: boolean;
}

export class AcceptInvitationResultDto {
  @ApiProperty({ example: 'sladkiy-limit', description: 'Куда переходить после вступления' })
  projectSlug!: string;

  @ApiProperty({ enum: PROJECT_ROLES, description: 'Роль пользователя в проекте после приёма' })
  role!: ProjectRole;

  @ApiProperty({ description: 'Пользователь уже был участником; роль не изменилась' })
  alreadyMember!: boolean;
}
