import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { EMAIL_MAX_LENGTH } from '../../common/index.js';
import { ACCESS_LIST_MAX_LIMIT } from '../access-list.service.js';

export class CreateAccessEntryDto {
  @ApiProperty({
    example: 'ivan@yandex.ru',
    maxLength: EMAIL_MAX_LENGTH,
    description:
      'Адрес аккаунта Яндекса. Регистр не важен: адрес приводится к нижнему регистру. ' +
      'Формат проверяется сервером, некорректный — 400 с кодом `invalid_email`.',
  })
  @IsString()
  @Length(3, EMAIL_MAX_LENGTH)
  email!: string;
}

export class UpdateAccessEntryDto {
  @ApiProperty({
    description:
      'Признак владельца трекера. Снять его с последнего владельца нельзя — 409 ' +
      '`last_instance_owner`.',
  })
  @IsBoolean()
  isInstanceOwner!: boolean;
}

export class ListAccessEntriesQueryDto {
  @ApiPropertyOptional({
    minimum: 1,
    maximum: ACCESS_LIST_MAX_LIMIT,
    default: 50,
    description: 'Размер страницы. Больше максимума не отдаём.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(ACCESS_LIST_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей страницы из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;

  @ApiPropertyOptional({ description: 'Поиск по подстроке в email и имени вошедшего (US-07)' })
  @IsOptional()
  @IsString()
  @Length(1, 128)
  q?: string;
}
