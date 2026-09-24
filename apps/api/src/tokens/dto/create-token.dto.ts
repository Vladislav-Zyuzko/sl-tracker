import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';
import { InvalidField } from '../../common/index.js';
import { PAT_DEFAULT_EXPIRES_IN_DAYS, PAT_MAX_EXPIRES_IN_DAYS } from '../tokens.service.js';

export const TOKEN_NAME_MAX_LENGTH = 64;

/** Разбор булева параметра query: других написаний не принимаем. */
const TRUTHY = new Map<string, boolean>([
  ['true', true],
  ['false', false],
]);

export class CreateTokenDto {
  @ApiProperty({
    example: 'dsh-mcp',
    minLength: 1,
    maxLength: TOKEN_NAME_MAX_LENGTH,
    description:
      'Как владелец назвал токен — «dsh-mcp», «ноутбук». Нужно, чтобы через полгода было ' +
      'понятно, что отзывать.',
  })
  @IsString()
  @Length(1, TOKEN_NAME_MAX_LENGTH)
  @InvalidField({
    code: 'invalid_token_name',
    message: 'Название токена обязательно и не длиннее 64 символов',
  })
  name!: string;

  @ApiPropertyOptional({
    minimum: 1,
    maximum: PAT_MAX_EXPIRES_IN_DAYS,
    default: PAT_DEFAULT_EXPIRES_IN_DAYS,
    description:
      'Срок жизни токена в днях. Поле можно не передавать — тогда 365. Бессрочных токенов ' +
      'не бывает: `null` отклоняется, как и значение вне диапазона.',
  })
  // Не `@IsOptional()`: он пропустил бы и `null`, а «бессрочно» принимать нельзя.
  // Отсутствующее поле — это 365 по умолчанию, явный `null` — ошибка запроса.
  @ValidateIf((dto: CreateTokenDto) => dto.expiresInDays !== undefined)
  @IsInt()
  @Min(1)
  @Max(PAT_MAX_EXPIRES_IN_DAYS)
  @InvalidField({
    code: 'invalid_expires_in_days',
    message: 'Срок токена — целое число от 1 до 3650 дней',
  })
  expiresInDays?: number;
}

export class ListTokensQueryDto {
  @ApiPropertyOptional({
    type: Boolean,
    default: false,
    description: 'Показать отозванные токены. По умолчанию их в списке нет.',
  })
  @IsOptional()
  // Значение приходит строкой в query: `?includeRevoked=true`. Всё, что не «true»
  // и не «false», остаётся строкой и отсекается проверкой ниже — молча считать мусор
  // за «false» значит показать пользователю не тот список, о котором он просил.
  @Transform(({ value }): unknown => TRUTHY.get(value as string) ?? value)
  @IsBoolean()
  includeRevoked?: boolean;
}
