import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import { CreateQueueDto, UpdateQueueDto } from './dto/queue-input.dto.js';
import {
  CreatedQueueDto,
  QueueDto,
  QueueListDto,
  QueueStatusDto,
  QueueStatusListDto,
} from './dto/queue.dto.js';
import { QueuesService } from './queues.service.js';

/**
 * Очереди внутри проекта: список и создание (US-30, US-31).
 *
 * Адресуется коротким именем проекта, потому что это операции над проектом.
 * Всё, что делается с уже существующей очередью, живёт в `QueueController`
 * и адресуется ключом очереди — так же, как на клиенте (`/queues/DEV`).
 */
@ApiTags('queues')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
@Controller('projects/:slug/queues')
export class ProjectQueuesController {
  constructor(private readonly queues: QueuesService) {}

  @Get()
  @ApiOperation({
    summary: 'Очереди проекта',
    description:
      'Виден всем участникам проекта, включая читателя (US-31). Сортировка — ' +
      'по названию по возрастанию. `openIssueCount` — число незавершённых задач, ' +
      'то есть тех, чей статус **не** в категории `done`. Очередей у проекта единицы, ' +
      'поэтому список отдаётся целиком, без курсора.',
  })
  @ApiParam({ name: 'slug', example: 'sladkiy-limit' })
  @ApiOkResponse({ type: QueueListDto })
  async list(
    @Param('slug') slug: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<QueueListDto> {
    const page = await this.queues.listForProject(slug, actor);
    return {
      items: page.items.map((row) =>
        QueueDto.fromListRow(row, page.projectSlug, page.projectName, page.role),
      ),
      total: page.items.length,
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Создать очередь',
    description:
      'Только администратор проекта (US-30). Ключ уникален **на весь трекер**, а не ' +
      'внутри проекта, и после создания не меняется никогда (D-06, ADR-0004). Ключ ' +
      'удалённой очереди повторно не выдаётся (D-25), поэтому 409 возможен и на ключ, ' +
      'которого сейчас ни у кого нет. В каком проекте ключ занят — ответ не сообщает.\n\n' +
      'Вместе с очередью создаются пять статусов по умолчанию (US-60): Открыт, ' +
      'В работе, Ревью, Тестирование, Закрыт. Они возвращаются в поле `statuses`, ' +
      'второй запрос за ними не нужен. Первый из них — статус новой задачи по умолчанию.',
  })
  @ApiParam({ name: 'slug', example: 'sladkiy-limit' })
  @ApiCreatedResponse({ type: CreatedQueueDto })
  @ApiBadRequestResponse({
    description: 'Ключ не по формату (`invalid_queue_key`) или пустое название',
  })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiConflictResponse({ description: 'Ключ занят (`queue_key_taken`)' })
  async create(
    @Param('slug') slug: string,
    @Body() body: CreateQueueDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<CreatedQueueDto> {
    const created = await this.queues.create(slug, body, actor);
    return {
      ...QueueDto.from(created.view),
      statuses: created.statuses.map((status) => QueueStatusDto.from(status)),
    };
  }
}

/**
 * Одна очередь, адресуемая ключом (US-32 … US-34, US-60).
 *
 * Ключ в адресе регистронезависим: `/api/queues/dev` и `/api/queues/DEV` — одна
 * и та же очередь (ADR-0004). Не-участник проекта получает 404 без названия
 * очереди и проекта (permissions.md, п. 5).
 */
@ApiTags('queues')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Очереди нет или пользователь не участник проекта' })
@Controller('queues/:key')
export class QueueController {
  constructor(private readonly queues: QueuesService) {}

  @Get()
  @ApiOperation({
    summary: 'Очередь по ключу',
    description:
      'Видна всем участникам проекта, включая читателя. Ключ регистронезависим. ' +
      'В ответе есть короткое имя и название проекта — для хлебных крошек, ' +
      'без второго запроса.',
  })
  @ApiParam({ name: 'key', example: 'DEV' })
  @ApiOkResponse({ type: QueueDto })
  async get(@Param('key') key: string, @CurrentUser() actor: AuthenticatedUser): Promise<QueueDto> {
    return QueueDto.from(await this.queues.getByKey(key, actor));
  }

  @Get('statuses')
  @ApiOperation({
    summary: 'Статусы очереди',
    description:
      'Пять статусов очереди в фиксированном порядке (US-60). Статусы — данные, ' +
      'а не enum: у каждой очереди свой набор, и клиент обязан брать его отсюда, ' +
      'а не хардкодить (ADR-0003). Нужен для выпадающего списка на задаче и для ' +
      'фильтра в списке задач. Редактора статусов в MVP нет: список только читается.',
  })
  @ApiParam({ name: 'key', example: 'DEV' })
  @ApiOkResponse({ type: QueueStatusListDto })
  async statuses(
    @Param('key') key: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<QueueStatusListDto> {
    const rows = await this.queues.statusesOf(key, actor);
    return { items: rows.map((row) => QueueStatusDto.from(row)) };
  }

  @Patch()
  @ApiOperation({
    summary: 'Переименовать очередь',
    description:
      'Только администратор проекта (US-33). Меняются название и описание; **ключ ' +
      'не меняется никогда** (D-06) и в теле запроса не принимается. Ключи ' +
      'существующих задач переименование не затрагивает.',
  })
  @ApiParam({ name: 'key', example: 'DEV' })
  @ApiOkResponse({ type: QueueDto })
  @ApiBadRequestResponse({ description: 'Пустое название (`invalid_queue_name`)' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  async update(
    @Param('key') key: string,
    @Body() body: UpdateQueueDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<QueueDto> {
    return QueueDto.from(await this.queues.updateDetails(key, body, actor));
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Удалить очередь',
    description:
      'Только администратор проекта и **только пустую**: при наличии хотя бы одной ' +
      'задачи в любом статусе — 409 (US-34, D-24). Каскадного удаления задач нет.\n\n' +
      'Ключ удалённой очереди остаётся занятым навсегда и другой очереди не достанется ' +
      '(D-25): иначе старая ссылка `DEV-42` открыла бы совсем другую задачу.',
  })
  @ApiParam({ name: 'key', example: 'DEV' })
  @ApiNoContentResponse({ description: 'Очередь удалена' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiConflictResponse({ description: 'В очереди есть задачи (`queue_not_empty`)' })
  async remove(@Param('key') key: string, @CurrentUser() actor: AuthenticatedUser): Promise<void> {
    await this.queues.remove(key, actor);
  }
}
