import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { IssueUserDto } from '../../issues/dto/issue.dto.js';
import type { NotificationListRow, NotificationSettingRow } from '../notifications.repository.js';
import {
  NOTIFICATION_CHANNELS,
  NOTIFICATION_TYPES,
  type NotificationChannel,
  type NotificationType,
} from '../notification-types.js';
import { NOTIFICATIONS_MAX_LIMIT } from '../notifications.service.js';

/**
 * Снимок текста на момент события. Именно снимок, а не текущее состояние: задачу
 * потом переименуют, комментарий поправят, а уведомление обязано остаться тем,
 * что человек получил (US-102).
 *
 * Набор заполненных полей зависит от типа — какие именно, сказано у каждого поля.
 */
export class NotificationPayloadDto {
  @ApiPropertyOptional({ example: 'DEV-42', description: 'Ключ задачи на момент события' })
  issueKey?: string;

  @ApiPropertyOptional({ example: 'Починить экспорт CSV' })
  issueTitle?: string;

  @ApiPropertyOptional({ description: 'Статус до перехода. Только `issue_status_changed`.' })
  fromStatusName?: string | null;

  @ApiPropertyOptional({ description: 'Статус после перехода. Только `issue_status_changed`.' })
  toStatusName?: string | null;

  @ApiPropertyOptional({
    description:
      'Начало текста, ~100 символов: комментарий (`issue_commented`) либо текст ' +
      'с упоминанием (`issue_mentioned`). Упоминания развёрнуты в `@Имя`, **разметка ' +
      'Markdown не снята** — её убирает клиент при отрисовке превью (US-102).',
  })
  excerpt?: string;

  @ApiPropertyOptional({
    enum: ['comment', 'description'],
    description:
      'Где находится упоминание. `description` — в описании задачи: прокручивать надо ' +
      'к описанию, а не к комментарию (US-104). Только `issue_mentioned`.',
  })
  source?: 'comment' | 'description';

  @ApiPropertyOptional({ description: 'Только `project_member_joined`' })
  projectSlug?: string;

  @ApiPropertyOptional({ description: 'Только `project_member_joined`' })
  projectName?: string;

  @ApiPropertyOptional({ description: 'Имя вступившего. Только `project_member_joined`.' })
  memberName?: string;
}

export class NotificationDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    enum: NOTIFICATION_TYPES,
    description:
      'Тип события. От него зависит текст строки и то, какие поля заполнены ' +
      'в `payload` (design/screens/notifications.md).',
  })
  type!: NotificationType;

  @ApiProperty({
    enum: NOTIFICATION_CHANNELS,
    description: 'Канал доставки. В MVP всегда `in_app` (D-18).',
  })
  channel!: NotificationChannel;

  @ApiProperty({
    type: IssueUserDto,
    nullable: true,
    description:
      'Кто инициировал событие. `null` — системное событие: в ленте вместо аватара ' +
      'иконка, а не случайный пользователь.',
  })
  actor!: IssueUserDto | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Ключ задачи **сейчас**. `null` означает, что задачи больше нет или она в проекте, ' +
      'из которого пользователя исключили: переход по такому уведомлению показывает ' +
      '«Задача не найдена» (US-103). Текст строки берётся из `payload.issueKey`.',
  })
  issueKey!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: 'Короткое имя проекта — адрес перехода для `project_member_joined` (US-23)',
  })
  projectSlug!: string | null;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description:
      'Комментарий, к которому нужно прокрутить задачу (`/issues/DEV-42?comment=<id>`). ' +
      '`null` у удалённого комментария — тогда открывается сама задача, и клиент ' +
      'показывает «Комментарий удалён» (US-102).',
  })
  commentId!: string | null;

  @ApiProperty({ type: NotificationPayloadDto })
  payload!: NotificationPayloadDto;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '`null` — непрочитанное: точка слева и жирное имя инициатора',
  })
  readAt!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  static from(row: NotificationListRow): NotificationDto {
    return {
      id: row.id,
      type: row.type,
      channel: row.channel,
      actor: row.actor ? IssueUserDto.from(row.actor) : null,
      issueKey: row.issueKey,
      projectSlug: row.projectSlug,
      commentId: row.commentId,
      payload: row.payload,
      readAt: row.readAt ? row.readAt.toISOString() : null,
      createdAt: row.createdAt.toISOString(),
    };
  }
}

export class NotificationListDto {
  @ApiProperty({ type: [NotificationDto], description: 'Сначала новые (US-103)' })
  items!: NotificationDto[];

  @ApiProperty({ type: String, nullable: true, description: 'Курсор следующей порции' })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего уведомлений у пользователя' })
  total!: number;

  @ApiProperty({ description: 'Непрочитанных: то же число, что и в счётчике шапки' })
  unreadCount!: number;
}

export class UnreadCountDto {
  @ApiProperty({
    description:
      'Точное число непрочитанных. Обрезку до «99+» делает интерфейс, а не сервер: ' +
      'иначе он не сможет показать точное значение до 99 (US-103).',
    example: 12,
  })
  unreadCount!: number;
}

export class MarkAllReadResultDto {
  @ApiProperty({ description: 'Сколько уведомлений стало прочитанными', example: 12 })
  updated!: number;
}

export class NotificationSettingDto {
  @ApiProperty({ enum: NOTIFICATION_TYPES })
  type!: NotificationType;

  @ApiProperty({ enum: NOTIFICATION_CHANNELS })
  channel!: NotificationChannel;

  @ApiProperty({ description: 'По умолчанию включены все типы (US-103)' })
  enabled!: boolean;

  static from(row: NotificationSettingRow): NotificationSettingDto {
    return { type: row.type, channel: row.channel, enabled: row.enabled };
  }
}

export class NotificationSettingsDto {
  @ApiProperty({
    type: [NotificationSettingDto],
    description:
      'Все типы уведомлений, включая те, которые пользователь не трогал: отсутствие ' +
      'записи в базе означает «включено», и клиенту не нужно об этом знать.',
  })
  items!: NotificationSettingDto[];
}

export class UpdateNotificationSettingDto {
  @ApiProperty({ enum: NOTIFICATION_TYPES })
  @IsEnum(NOTIFICATION_TYPES)
  type!: NotificationType;

  @ApiPropertyOptional({
    enum: NOTIFICATION_CHANNELS,
    default: 'in_app',
    description: 'Канал. В MVP единственный, но передавать его можно уже сейчас (D-18).',
  })
  @IsOptional()
  @IsEnum(NOTIFICATION_CHANNELS)
  channel?: NotificationChannel;

  @ApiProperty({ description: 'Выключенный тип не создаёт ни записи, ни счётчика (US-103)' })
  @IsBoolean()
  enabled!: boolean;
}

export class UpdateNotificationSettingsDto {
  @ApiProperty({
    type: [UpdateNotificationSettingDto],
    description: 'Меняются только перечисленные типы; остальные остаются как были.',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateNotificationSettingDto)
  items!: UpdateNotificationSettingDto[];
}

export class ListNotificationsQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: NOTIFICATIONS_MAX_LIMIT, default: 30 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(NOTIFICATIONS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей порции из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
