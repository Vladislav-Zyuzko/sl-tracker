import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Length, Matches, ValidateIf } from 'class-validator';
import { QUEUE_DESCRIPTION_MAX_LENGTH, QUEUE_NAME_MAX_LENGTH } from '../queues.service.js';

/**
 * Ключ принимается и в нижнем регистре: сервер приводит его к верхнему.
 * Проверка здесь регистронезависимая, а нормализация — в сервисе, чтобы
 * `dev` и `DEV` не считались разными ключами.
 */
const QUEUE_KEY_INPUT_PATTERN = /^[A-Za-z][A-Za-z0-9]{1,9}$/;

export class CreateQueueDto {
  @ApiProperty({
    example: 'DEV',
    description:
      'Ключ очереди: 2–10 латинских букв и цифр, первый символ — буква. Приводится ' +
      'к верхнему регистру. Уникален **на весь трекер**, а не внутри проекта, ' +
      'и не меняется после создания (ADR-0004).',
  })
  @IsString()
  @Matches(QUEUE_KEY_INPUT_PATTERN, {
    message: 'Ключ: 2–10 латинских букв и цифр, первый символ — буква',
  })
  key!: string;

  @ApiProperty({ example: 'Разработка', minLength: 1, maxLength: QUEUE_NAME_MAX_LENGTH })
  @IsString()
  @Length(1, QUEUE_NAME_MAX_LENGTH)
  name!: string;

  @ApiPropertyOptional({
    maxLength: QUEUE_DESCRIPTION_MAX_LENGTH,
    description: 'Markdown. Исполняемое содержимое недопустимо (D-22).',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(0, QUEUE_DESCRIPTION_MAX_LENGTH)
  description?: string | null;
}

export class UpdateQueueDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: QUEUE_NAME_MAX_LENGTH })
  @IsOptional()
  @IsString()
  @Length(1, QUEUE_NAME_MAX_LENGTH)
  name?: string;

  @ApiPropertyOptional({
    maxLength: QUEUE_DESCRIPTION_MAX_LENGTH,
    nullable: true,
    description: 'Markdown. `null` или пустая строка очищают описание.',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(0, QUEUE_DESCRIPTION_MAX_LENGTH)
  description?: string | null;
}
