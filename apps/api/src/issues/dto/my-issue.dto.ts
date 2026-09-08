import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import type { MyIssueRow, StatusCategory } from '../my-issues.repository.js';
import { MY_ISSUES_MAX_LIMIT } from '../my-issues.service.js';

export const STATUS_CATEGORIES = ['open', 'in_progress', 'done'] as const;

/** Статус задачи — данные, а не enum в коде (ADR-0003): клиенту нужны все три поля. */
export class IssueStatusDto {
  @ApiProperty({ example: 'in_progress', description: 'Машинное имя статуса в очереди' })
  key!: string;

  @ApiProperty({ example: 'В работе', description: 'Название для интерфейса' })
  name!: string;

  @ApiProperty({
    enum: STATUS_CATEGORIES,
    description:
      'Категория статуса. Активной считается задача, у которой категория не `done`; ' +
      'в этом списке `done` не встречается.',
  })
  category!: StatusCategory;
}

export class MyIssueDto {
  @ApiProperty({ example: 'DEV-42', description: 'Публичный ключ задачи, он же адрес' })
  key!: string;

  @ApiProperty({ example: 'Автоматизация отчёта', description: 'Тема задачи' })
  title!: string;

  @ApiProperty({
    example: 50,
    description: 'Приоритет 0–100 с шагом 10. Список отсортирован по нему по убыванию.',
  })
  priority!: number;

  @ApiProperty({ type: IssueStatusDto })
  status!: IssueStatusDto;

  static from(row: MyIssueRow): MyIssueDto {
    return {
      key: row.key,
      title: row.title,
      priority: row.priority,
      status: { key: row.statusKey, name: row.statusName, category: row.statusCategory },
    };
  }
}

export class MyIssueListDto {
  @ApiProperty({
    type: [MyIssueDto],
    description: 'Приоритет по убыванию, при равенстве — сначала недавно изменённые',
  })
  items!: MyIssueDto[];

  @ApiProperty({ type: String, nullable: true })
  nextCursor!: string | null;

  @ApiProperty({
    description: 'Всего активных задач у пользователя, **без учёта поиска**: счётчик у заголовка',
  })
  total!: number;
}

export class MyIssuesQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: MY_ISSUES_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MY_ISSUES_MAX_LIMIT)
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей страницы из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;

  @ApiPropertyOptional({
    description:
      'Поиск по подстроке в теме и в ключе, без учёта регистра. Ищет только среди ' +
      'активных задач текущего пользователя (D-20).',
    example: 'dev-4',
  })
  @IsOptional()
  @IsString()
  @Length(1, 128)
  q?: string;
}
