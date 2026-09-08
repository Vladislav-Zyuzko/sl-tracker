import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { SLUG_MAX_LENGTH } from '../project-slug.js';
import { PROJECTS_MAX_LIMIT } from '../projects.service.js';

export class CreateProjectDto {
  @ApiProperty({
    example: 'Сладкий лимит',
    minLength: 1,
    maxLength: 100,
    description:
      'Название проекта. Короткое имя в адресе выдаётся сервером автоматически ' +
      'по названию и отдельно не передаётся (US-11, US-18).',
  })
  @IsString()
  @Length(1, 100)
  name!: string;

  @ApiPropertyOptional({
    maxLength: 5000,
    nullable: true,
    description: 'Markdown, до 5000 символов. Пустая строка равнозначна отсутствию описания.',
  })
  @IsOptional()
  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MaxLength(5000)
  description?: string | null;
}

export class UpdateProjectDto {
  @ApiPropertyOptional({
    minLength: 1,
    maxLength: 100,
    description:
      'Новое название. Переименование **не меняет** короткое имя в адресе: ранее ' +
      'отправленные ссылки продолжают работать (US-18).',
  })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  name?: string;

  @ApiPropertyOptional({
    maxLength: 5000,
    nullable: true,
    description: '`null` или пустая строка убирают описание.',
  })
  @IsOptional()
  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MaxLength(5000)
  description?: string | null;
}

export class UpdateProjectSlugDto {
  @ApiProperty({
    example: 'sladkiy-limit',
    maxLength: SLUG_MAX_LENGTH,
    description:
      'Новое короткое имя: строчные латинские буквы, цифры и одиночные дефисы внутри. ' +
      'Прежнее имя остаётся занятым навсегда и продолжает открывать этот проект (US-18).',
  })
  @IsString()
  @Length(1, SLUG_MAX_LENGTH)
  slug!: string;
}

export class ListProjectsQueryDto {
  @ApiPropertyOptional({
    minimum: 1,
    maximum: PROJECTS_MAX_LIMIT,
    default: 50,
    description: 'Размер страницы. Больше максимума не отдаём.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(PROJECTS_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей страницы из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;
}
