import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import type { HistoryChangeRow, HistoryGroupRow } from '../issue-history.repository.js';
import { HISTORY_MAX_LIMIT } from '../issue-history.service.js';
import { IssueUserDto } from './issue.dto.js';

export const HISTORY_KINDS = [
  'issue_created',
  'title_changed',
  'description_changed',
  'status_changed',
  'priority_changed',
  'story_points_changed',
  'author_changed',
  'assignee_changed',
  'attachment_added',
  'attachment_removed',
  'link_added',
  'link_removed',
  'comment_deleted',
] as const;

/** Одно изменённое поле внутри действия. */
export class IssueHistoryChangeDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    enum: HISTORY_KINDS,
    description:
      'Что изменилось. `issue_created` — создание задачи; эта запись всегда самая ранняя ' +
      'и показывает **реального создателя**, даже если поле «Автор» потом меняли (D-13). ' +
      'У `description_changed` значений нет: фиксируется только факт изменения, старый ' +
      'текст не хранится (US-91).',
  })
  kind!: (typeof HISTORY_KINDS)[number];

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Читаемое старое значение на момент изменения — имя человека, название статуса, ' +
      'число. `null` означает «пусто»: «не назначен» у исполнителя, «не оценено» ' +
      'у сложности (US-91).',
  })
  oldValue!: string | null;

  @ApiProperty({ type: String, nullable: true, description: 'Читаемое новое значение' })
  newValue!: string | null;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: 'Идентификатор прежнего объекта (пользователя или статуса) — для аватара и ссылки',
  })
  oldRefId!: string | null;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  newRefId!: string | null;

  static from(row: HistoryChangeRow): IssueHistoryChangeDto {
    return {
      id: row.id,
      kind: row.kind,
      oldValue: row.oldValue,
      newValue: row.newValue,
      oldRefId: row.oldRefId,
      newRefId: row.newRefId,
    };
  }
}

/**
 * Одно действие пользователя. Внутри — все поля, изменённые этим действием (US-90):
 * лента показывает их одной группой с общим временем и автором.
 */
export class IssueHistoryGroupDto {
  @ApiProperty({ format: 'uuid', description: 'Идентификатор группы изменений' })
  id!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({
    type: IssueUserDto,
    nullable: true,
    description:
      '`null` — изменение системное, а не человеческое (например, очистка исполнителя ' +
      'при исключении участника из проекта). Интерфейс показывает его как «Система», ' +
      'а не приписывает случайному пользователю (US-91).',
  })
  actor!: IssueUserDto | null;

  @ApiProperty({ type: [IssueHistoryChangeDto] })
  changes!: IssueHistoryChangeDto[];

  static from(group: HistoryGroupRow): IssueHistoryGroupDto {
    return {
      id: group.groupId,
      createdAt: group.createdAt.toISOString(),
      actor: group.actor ? IssueUserDto.from(group.actor) : null,
      changes: group.changes.map((change) => IssueHistoryChangeDto.from(change)),
    };
  }
}

export class IssueHistoryListDto {
  @ApiProperty({
    type: [IssueHistoryGroupDto],
    description:
      'Сначала новые (US-90). Страница считается по группам, а не по отдельным записям: ' +
      'одно действие никогда не разрывается границей страницы.',
  })
  items!: IssueHistoryGroupDto[];

  @ApiProperty({ type: String, nullable: true })
  nextCursor!: string | null;

  @ApiProperty({
    description: 'Всего действий по задаче. Минимум одно есть всегда — «Задача создана».',
  })
  total!: number;
}

export class ListIssueHistoryQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: HISTORY_MAX_LIMIT, default: 25 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(HISTORY_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей порции из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
