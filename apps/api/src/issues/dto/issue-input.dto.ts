import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  ValidateIf,
} from 'class-validator';
import {
  ISSUE_DESCRIPTION_MAX_LENGTH,
  ISSUE_PRIORITY_DEFAULT,
  ISSUE_PRIORITY_VALUES,
  ISSUE_STORY_POINTS_VALUES,
  ISSUE_TITLE_MAX_LENGTH,
} from '../issue-fields.js';
import {
  ISSUE_LINK_TITLE_MAX_LENGTH,
  ISSUE_LINK_URL_MAX_LENGTH,
  ISSUES_MAX_LIMIT,
} from '../issues.service.js';

const DESCRIPTION_HELP =
  'Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает ' +
  'и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме ' +
  '`http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность ' +
  'клиента при рендере (D-22, US-43).';

export class CreateIssueDto {
  @ApiProperty({
    example: 'Починить экспорт CSV на больших выгрузках',
    minLength: 1,
    maxLength: ISSUE_TITLE_MAX_LENGTH,
    description: 'Единственное обязательное поле (US-40)',
  })
  @IsString()
  @Length(1, ISSUE_TITLE_MAX_LENGTH)
  title!: string;

  @ApiPropertyOptional({ maxLength: ISSUE_DESCRIPTION_MAX_LENGTH, description: DESCRIPTION_HELP })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(0, ISSUE_DESCRIPTION_MAX_LENGTH)
  description?: string | null;

  @ApiPropertyOptional({
    format: 'uuid',
    description: 'Статус из набора этой очереди. По умолчанию — первый статус очереди («Открыт»).',
  })
  @IsOptional()
  @IsUUID()
  statusId?: string;

  @ApiPropertyOptional({
    enum: ISSUE_PRIORITY_VALUES,
    default: ISSUE_PRIORITY_DEFAULT,
    description: `0–100 с шагом 10. По умолчанию ${ISSUE_PRIORITY_DEFAULT}. \`null\` недопустим (D-15).`,
  })
  @IsOptional()
  @Type(() => Number)
  @IsIn([...ISSUE_PRIORITY_VALUES])
  priority?: number;

  @ApiPropertyOptional({
    enum: ISSUE_STORY_POINTS_VALUES,
    nullable: true,
    description: 'Шкала Фибоначчи. `null` или отсутствие поля — «не оценено» (D-16).',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsIn([...ISSUE_STORY_POINTS_VALUES])
  storyPoints?: number | null;

  @ApiPropertyOptional({
    format: 'uuid',
    description: 'Автор задачи. По умолчанию — создатель. Только участник проекта (US-53).',
  })
  @IsOptional()
  @IsUUID()
  authorId?: string;

  @ApiPropertyOptional({
    format: 'uuid',
    nullable: true,
    description: 'Исполнитель. `null` — «Не назначен». Только участник проекта (US-52).',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsUUID()
  assigneeId?: string | null;
}

/**
 * Частичное изменение задачи. Отсутствующее поле не трогается; поле со значением,
 * равным текущему, не порождает записи в истории (US-91).
 *
 * `createdByUserId` здесь нет и быть не может: создатель неизменяем (D-13).
 * Ключа очереди тоже нет: переноса задач между очередями в MVP нет (D-14).
 */
export class UpdateIssueDto {
  @ApiPropertyOptional({ minLength: 1, maxLength: ISSUE_TITLE_MAX_LENGTH })
  @IsOptional()
  @IsString()
  @Length(1, ISSUE_TITLE_MAX_LENGTH)
  title?: string;

  @ApiPropertyOptional({
    maxLength: ISSUE_DESCRIPTION_MAX_LENGTH,
    nullable: true,
    description: `${DESCRIPTION_HELP} \`null\` или пустая строка очищают описание.`,
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(0, ISSUE_DESCRIPTION_MAX_LENGTH)
  description?: string | null;

  @ApiPropertyOptional({
    format: 'uuid',
    description:
      'Новый статус. Переход разрешён из любого статуса очереди в любой другой, ' +
      'включая возврат назад и закрытие из любого состояния (D-10). Статус чужой ' +
      'очереди отклоняется.',
  })
  @IsOptional()
  @IsUUID()
  statusId?: string;

  @ApiPropertyOptional({ enum: ISSUE_PRIORITY_VALUES })
  @IsOptional()
  @Type(() => Number)
  @IsIn([...ISSUE_PRIORITY_VALUES])
  priority?: number;

  @ApiPropertyOptional({
    enum: ISSUE_STORY_POINTS_VALUES,
    nullable: true,
    description: '`null` снимает оценку и возвращает «не оценено» (US-51).',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsIn([...ISSUE_STORY_POINTS_VALUES])
  storyPoints?: number | null;

  @ApiPropertyOptional({
    format: 'uuid',
    description:
      'Новый автор — любой участник проекта. Очистить поле нельзя. Смена автора ' +
      'логируется отдельной записью истории; создатель задачи при этом не меняется (D-13).',
  })
  @IsOptional()
  @IsUUID()
  authorId?: string;

  @ApiPropertyOptional({
    format: 'uuid',
    nullable: true,
    description: '`null` снимает исполнителя и возвращает «Не назначен».',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsUUID()
  assigneeId?: string | null;
}

export class CreateIssueLinkDto {
  @ApiProperty({
    example: 'https://example.com/spec',
    maxLength: ISSUE_LINK_URL_MAX_LENGTH,
    description: 'Только схемы `http` и `https` (US-47)',
  })
  @IsString()
  @Length(1, ISSUE_LINK_URL_MAX_LENGTH)
  url!: string;

  @ApiPropertyOptional({
    maxLength: ISSUE_LINK_TITLE_MAX_LENGTH,
    nullable: true,
    description: 'Подпись. Пусто — интерфейс показывает сам адрес.',
  })
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(0, ISSUE_LINK_TITLE_MAX_LENGTH)
  title?: string | null;
}

/** Ключи статусов через запятую: `?status=in_progress,review` (design/queue-issues.md). */
const STATUS_KEYS_PATTERN = /^[a-z0-9_]+(,[a-z0-9_]+)*$/;

export class ListQueueIssuesQueryDto {
  @ApiPropertyOptional({ minimum: 1, maximum: ISSUES_MAX_LIMIT, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  limit?: number;

  @ApiPropertyOptional({ description: 'Курсор следующей порции из поля `nextCursor`' })
  @IsOptional()
  @IsString()
  @Length(1, 256)
  cursor?: string;

  @ApiPropertyOptional({
    enum: ['priority', 'newest'],
    default: 'priority',
    description:
      '`priority` — приоритет по убыванию, при равенстве номер по убыванию (по умолчанию, ' +
      'D-28). `newest` — только по номеру по убыванию, «сначала новые».',
  })
  @IsOptional()
  @IsIn(['priority', 'newest'])
  sort?: 'priority' | 'newest';

  @ApiPropertyOptional({
    example: 'in_progress,review',
    description:
      'Ключи статусов через запятую (не идентификаторы): фильтр читаем в адресе страницы ' +
      'и его можно скопировать (US-32). Статус, которого нет в этой очереди, просто ' +
      'не совпадёт ни с чем; если не совпал ни один — вернётся пустая страница, не ошибка.',
  })
  @IsOptional()
  @IsString()
  @Matches(STATUS_KEYS_PATTERN, { message: 'Ожидаются ключи статусов через запятую' })
  status?: string;

  @ApiPropertyOptional({
    description:
      'Идентификатор исполнителя либо `none` — только задачи без исполнителя. ' +
      'Вне объёма MVP-экрана (D-28), но контракт его поддерживает.',
  })
  @IsOptional()
  @IsString()
  @Length(1, 64)
  assignee?: string;

  @ApiPropertyOptional({ format: 'uuid', description: 'Идентификатор автора задачи' })
  @IsOptional()
  @IsUUID()
  author?: string;

  @ApiPropertyOptional({ enum: ISSUE_PRIORITY_VALUES, description: 'Приоритет не ниже указанного' })
  @IsOptional()
  @Type(() => Number)
  @IsIn([...ISSUE_PRIORITY_VALUES])
  priorityMin?: number;

  @ApiPropertyOptional({ enum: ISSUE_PRIORITY_VALUES, description: 'Приоритет не выше указанного' })
  @IsOptional()
  @Type(() => Number)
  @IsIn([...ISSUE_PRIORITY_VALUES])
  priorityMax?: number;
}
