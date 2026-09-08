import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { MENTION_SUGGESTIONS_MAX_LIMIT } from '../mention-suggestions.service.js';

export class MentionSuggestionDto {
  @ApiProperty({ format: 'uuid', description: 'Подставляется в токен `@[Имя](user:<uuid>)`' })
  id!: string;

  @ApiProperty({ example: 'Анна Иванова' })
  displayName!: string;

  @ApiProperty({
    example: 'anna@example.com',
    description:
      'Показывается второй строкой **только при совпадении имён** (US-74). Адрес виден ' +
      'лишь по участникам того же проекта — там он и так есть на вкладке «Участники».',
  })
  email!: string;

  @ApiProperty({ type: String, nullable: true })
  avatarUrl!: string | null;
}

export class MentionSuggestionListDto {
  @ApiProperty({
    type: [MentionSuggestionDto],
    description: 'По имени по возрастанию; не более 10 совпадений',
  })
  items!: MentionSuggestionDto[];
}

export class MentionSuggestionsQueryDto {
  @ApiPropertyOptional({
    description:
      'Строка после `@`. Фильтрует по имени и по email без учёта регистра. Пустая ' +
      'строка — начало списка участников проекта.',
    example: 'ан',
  })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  query?: string;

  @ApiPropertyOptional({ minimum: 1, maximum: MENTION_SUGGESTIONS_MAX_LIMIT, default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MENTION_SUGGESTIONS_MAX_LIMIT)
  limit?: number;
}
