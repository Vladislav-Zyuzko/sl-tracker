import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { IssueUserDto } from '../../issues/dto/issue.dto.js';
import { COMMENT_BODY_MAX_LENGTH } from '../comment-body.js';
import type { CommentRow } from '../comments.repository.js';
import { COMMENTS_MAX_LIMIT, commentPermissionsFor } from '../comments.service.js';

/** Что запросившему разрешено с этим комментарием (permissions.md, раздел 2.5). */
export class CommentPermissionsDto {
  @ApiProperty({
    description:
      'Править может **только автор**, независимо от роли: администратор чужой ' +
      'комментарий не редактирует (US-72).',
  })
  canEdit!: boolean;

  @ApiProperty({
    description: 'Свой комментарий удаляет автор, чужой — только администратор проекта (US-73).',
  })
  canDelete!: boolean;
}

export class CommentDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    maxLength: COMMENT_BODY_MAX_LENGTH,
    description:
      'Текст в Markdown, как есть. Упоминания записаны токеном `@[Имя](user:<uuid>)`; ' +
      'актуальные имена и аватары упомянутых — в поле `mentions`, а токен, которому ' +
      'там ничего не соответствует, показывается **обычным текстом** (US-74).\n\n' +
      '**Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения ' +
      'содержимого (D-22).',
  })
  body!: string;

  @ApiProperty({ type: IssueUserDto, description: 'Автор: имя и аватар приезжают сразу' })
  author!: IssueUserDto;

  @ApiProperty({
    type: [IssueUserDto],
    description:
      'Упомянутые в тексте участники проекта — **актуальные** имена и аватары: человек ' +
      'сменил имя в Яндекс ID, и оно поменялось во всех старых комментариях (US-74). ' +
      'Упоминание того, кто не состоит в проекте, сюда не попадает никогда (D-41).',
  })
  mentions!: IssueUserDto[];

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: 'Когда комментарий правили. Не `null` — в ленте помечается «изменён» (US-72).',
  })
  editedAt!: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({ type: CommentPermissionsDto })
  permissions!: CommentPermissionsDto;

  static from(row: CommentRow, context: { role: string; actorId: string }): CommentDto {
    return {
      id: row.id,
      body: row.body,
      author: IssueUserDto.from(row.author),
      mentions: row.mentions.map((user) => IssueUserDto.from(user)),
      editedAt: row.editedAt ? row.editedAt.toISOString() : null,
      createdAt: row.createdAt.toISOString(),
      permissions: commentPermissionsFor(row, context),
    };
  }
}

export class CommentListDto {
  @ApiProperty({
    type: [CommentDto],
    description: 'В хронологическом порядке, **сначала старые** (US-70)',
  })
  items!: CommentDto[];

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Курсор **более ранних** комментариев — тех, что выше по ленте («Показать более ' +
      'ранние»). Страница без курсора отдаёт последние комментарии задачи. `null` — ' +
      'более ранних нет.',
  })
  nextCursor!: string | null;

  @ApiProperty({ description: 'Всего комментариев у задачи — счётчик на вкладке' })
  total!: number;

  @ApiProperty({
    description:
      'Может ли запросивший написать комментарий. `false` у читателя: поле ввода ' +
      'не показывается, а прямой вызов API вернёт 403 (US-71, D-29).',
  })
  canComment!: boolean;
}

export class CreateCommentDto {
  @ApiProperty({
    maxLength: COMMENT_BODY_MAX_LENGTH,
    description:
      'Markdown. Пустой текст и текст из одних пробелов отклоняются (US-71). ' +
      'Упоминание вставляется токеном `@[Имя](user:<uuid>)`, идентификатор берётся ' +
      'из подсказки `GET /api/issues/{key}/mention-suggestions`. Токен с посторонним ' +
      'пользователем **молча игнорируется**: связи и уведомления не будет, текст ' +
      'останется текстом (D-41).',
    example: 'Посмотри, пожалуйста, @[Анна Иванова](user:0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0)',
  })
  @IsString()
  @Length(1, COMMENT_BODY_MAX_LENGTH)
  body!: string;
}

export class UpdateCommentDto extends CreateCommentDto {}

export class ListCommentsQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: COMMENTS_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(COMMENTS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({
    description: 'Курсор более ранней порции из поля `nextCursor`',
  })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
