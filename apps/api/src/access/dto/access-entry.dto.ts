import { ApiProperty } from '@nestjs/swagger';
import type { AccessEntryRow, AccessEntrySource } from '../access-list.repository.js';
import type { AuthenticatedUser } from '../../auth/auth.types.js';
import { isOwnEntry } from '../access-list.service.js';

/** Человек, которым оказался адрес, или тот, кто адрес добавил. */
export class AccessEntryUserDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'Анна Петрова' })
  displayName!: string;

  @ApiProperty({ type: String, nullable: true, description: 'Аватар из Яндекс ID' })
  avatarUrl!: string | null;
}

export class AccessEntryDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'ivan@yandex.ru', description: 'Всегда в нижнем регистре' })
  email!: string;

  @ApiProperty({
    enum: ['config', 'manual', 'invitation'],
    description:
      'Откуда запись: `config` — из конфигурации инстанса, `manual` — добавлена владельцем ' +
      'вручную, `invitation` — появилась при приёме приглашения (ADR-0006).',
  })
  source!: AccessEntrySource;

  @ApiProperty({
    description:
      'Владелец трекера — единственная глобальная роль. Даёт право вести список доступа ' +
      'и не даёт никаких прав внутри проектов.',
  })
  isInstanceOwner!: boolean;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: 'Когда этот адрес впервые вошёл. `null` — «ещё не входил» (US-07).',
  })
  firstLoginAt!: string | null;

  @ApiProperty({
    type: AccessEntryUserDto,
    nullable: true,
    description: 'Пользователь, которым оказался адрес. `null` — человек ещё не входил.',
  })
  user!: AccessEntryUserDto | null;

  @ApiProperty({
    type: AccessEntryUserDto,
    nullable: true,
    description: 'Кто добавил запись вручную. Для `config` и `invitation` — `null`.',
  })
  addedBy!: AccessEntryUserDto | null;

  @ApiProperty({
    description: 'Запись текущего пользователя: удалить её нельзя (US-09, ответ 409).',
  })
  isSelf!: boolean;

  static from(row: AccessEntryRow, actor: AuthenticatedUser): AccessEntryDto {
    return {
      id: row.id,
      email: row.email,
      source: row.source,
      isInstanceOwner: row.isInstanceOwner,
      createdAt: row.createdAt.toISOString(),
      firstLoginAt: row.firstLoginAt ? row.firstLoginAt.toISOString() : null,
      user:
        row.userId && row.userDisplayName
          ? {
              id: row.userId,
              displayName: row.userDisplayName,
              avatarUrl: row.userAvatarUrl,
            }
          : null,
      addedBy:
        row.addedByUserId && row.addedByDisplayName
          ? { id: row.addedByUserId, displayName: row.addedByDisplayName, avatarUrl: null }
          : null,
      isSelf: isOwnEntry(row, actor),
    };
  }
}

export class AccessEntryListDto {
  @ApiProperty({ type: [AccessEntryDto], description: 'Сначала новые' })
  items!: AccessEntryDto[];

  @ApiProperty({
    type: String,
    nullable: true,
    description: 'Курсор следующей страницы. `null` — записей больше нет.',
  })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего записей с учётом поиска' })
  total!: number;
}

export class RevokeAccessResultDto {
  @ApiProperty({
    description: 'Сколько активных сессий человека погашено немедленно (US-09).',
    example: 2,
  })
  revokedSessions!: number;
}
