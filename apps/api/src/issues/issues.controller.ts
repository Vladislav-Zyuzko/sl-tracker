import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
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
import {
  CreateIssueDto,
  CreateIssueLinkDto,
  ListQueueIssuesQueryDto,
  UpdateIssueDto,
} from './dto/issue-input.dto.js';
import { IssueDto, IssueListDto, IssueRowDto } from './dto/issue.dto.js';
import {
  IssueHistoryGroupDto,
  IssueHistoryListDto,
  ListIssueHistoryQueryDto,
} from './dto/issue-history.dto.js';
import { IssueHistoryService } from './issue-history.service.js';
import { IssuesService } from './issues.service.js';

/**
 * Задачи очереди: список и создание (US-32, US-40).
 *
 * Адресуется ключом очереди, как и клиентский маршрут `/queues/DEV`. Не-участник
 * проекта получает 404 без названия очереди и проекта (permissions.md, п. 5).
 */
@ApiTags('issues')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Очереди нет или пользователь не участник проекта' })
@Controller('queues/:key/issues')
export class QueueIssuesController {
  constructor(private readonly issues: IssuesService) {}

  @Get()
  @ApiOperation({
    summary: 'Задачи очереди',
    description:
      'Список для плотной таблицы с виртуализацией (US-32). Отдаются **только поля ' +
      'строки списка**: ключ, название, статус, приоритет, сложность и исполнитель — ' +
      'описания, ссылок и автора здесь нет, иначе прокрутка на 1000 задач возит ' +
      'лишние килобайты.\n\n' +
      'Порядок по умолчанию — приоритет по убыванию, при равенстве номер по убыванию ' +
      '(D-28); `sort=newest` — только по номеру. Пагинация курсорная: `nextCursor` ' +
      'подставляется как есть, разбирать его не нужно. `limit` по умолчанию 50, ' +
      'жёсткий максимум 100 — большее значение молча ограничивается.\n\n' +
      'Фильтр `status` принимает **ключи** статусов через запятую. Фильтры по ' +
      'исполнителю, автору и приоритету в MVP-экране не используются (D-28), но ' +
      'контрактом поддержаны. `total` считается с теми же фильтрами — это счётчик ' +
      '«Показано N».',
  })
  @ApiParam({ name: 'key', example: 'DEV', description: 'Ключ очереди, регистронезависим' })
  @ApiOkResponse({ type: IssueListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Param('key') key: string,
    @Query() query: ListQueueIssuesQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueListDto> {
    const page = await this.issues.listForQueue(
      key,
      {
        limit: query.limit,
        cursor: query.cursor,
        sort: query.sort,
        statusKeys: query.status?.split(','),
        assignee: query.assignee,
        authorId: query.author,
        priorityMin: query.priorityMin,
        priorityMax: query.priorityMax,
      },
      actor,
    );

    return {
      items: page.items.map((row) => IssueRowDto.from(row)),
      nextCursor: page.nextCursor,
      total: page.total,
      role: page.queue.role,
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Создать задачу',
    description:
      'Администратор и участник проекта; читатель — 403 (US-40). Обязательное поле ' +
      'одно — `title`.\n\n' +
      'Ключ выдаётся автоматически: `<КЛЮЧ_ОЧЕРЕДИ>-<НОМЕР>`, номер — следующий ' +
      'по возрастанию в этой очереди. Номера не повторяются никогда, в том числе после ' +
      'удаления задач; пропуски допустимы (D-07). Параллельные создания получают разные ' +
      'номера — счётчик инкрементируется в той же транзакции, что и вставка (ADR-0004).\n\n' +
      'Умолчания: статус — первый статус очереди («Открыт»), приоритет — 50, сложность — ' +
      'не задана, автор — создатель, исполнитель — не назначен. В историю сразу пишется ' +
      'запись о создании с реальным создателем (D-13).',
  })
  @ApiParam({ name: 'key', example: 'DEV' })
  @ApiCreatedResponse({ type: IssueDto })
  @ApiBadRequestResponse({
    description:
      'Пустое название (`invalid_issue_title`), статус не из этой очереди (`invalid_status`), ' +
      'недопустимый приоритет (`invalid_priority`) или сложность (`invalid_story_points`), ' +
      'автор или исполнитель не участник проекта (`author_not_member`, `assignee_not_member`)',
  })
  @ApiForbiddenResponse({ description: 'Читатель не создаёт задачи (`issue_forbidden`)' })
  async create(
    @Param('key') key: string,
    @Body() body: CreateIssueDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueDto> {
    return IssueDto.from(await this.issues.create(key, body, actor));
  }
}

/**
 * Одна задача, адресуемая своим публичным ключом (US-41 … US-44, US-47, US-50 … US-53, US-61).
 *
 * Ключ регистронезависим: `/api/issues/dev-42` и `/api/issues/DEV-42` — одна и та же
 * задача (ADR-0004). Адрес не содержит ни проекта, ни очереди: ключ уникален глобально.
 *
 * Не-участник проекта и несуществующий ключ отвечают **одинаково** — 404 без единого
 * поля задачи, включая название (US-41, permissions.md, п. 5).
 */
@ApiTags('issues')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Задачи нет или пользователь не участник проекта' })
@Controller('issues/:key')
export class IssueController {
  constructor(
    private readonly issues: IssuesService,
    private readonly history: IssueHistoryService,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Задача по ключу',
    description:
      'Видна всем участникам проекта, включая читателя, — целиком, но без контролов ' +
      'изменения (US-41). Поле `permissions` говорит, что запросившему разрешено.\n\n' +
      'Поля «Создатель» в ответе нет намеренно: в интерфейсе задачи это слово ' +
      'не используется, реальный создатель виден только в первой записи истории (D-13).',
  })
  @ApiParam({ name: 'key', example: 'DEV-42', description: 'Ключ задачи, регистронезависим' })
  @ApiOkResponse({ type: IssueDto })
  async get(@Param('key') key: string, @CurrentUser() actor: AuthenticatedUser): Promise<IssueDto> {
    return IssueDto.from(await this.issues.getByKey(key, actor));
  }

  @Patch()
  @ApiOperation({
    summary: 'Изменить поля задачи',
    description:
      'Администратор и участник проекта, **в том числе у чужой задачи** (D-11); ' +
      'читатель — 403. Меняются название, описание, статус, приоритет, сложность, ' +
      'автор и исполнитель. Поля, которых нет в теле, не трогаются.\n\n' +
      'Переходы статусов свободные: из любого статуса очереди в любой другой, включая ' +
      'возврат назад и закрытие из любого состояния (D-10). Статус чужой очереди ' +
      'отклоняется — 400.\n\n' +
      'Каждое изменившееся поле пишется в историю **в той же транзакции**, что и само ' +
      'изменение; все поля одного запроса попадают в одну группу истории (US-90). Поле, ' +
      'значение которого не изменилось, записи не создаёт (US-91). Смена автора ' +
      'логируется отдельно и создателя задачи не меняет (D-13).\n\n' +
      'Конфликт одновременного редактирования не решается: побеждает последняя запись ' +
      '(D-27).',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiOkResponse({ type: IssueDto })
  @ApiBadRequestResponse({
    description:
      'Пустое название (`invalid_issue_title`), статус не из этой очереди (`invalid_status`), ' +
      'недопустимый приоритет (`invalid_priority`) или сложность (`invalid_story_points`), ' +
      'автор или исполнитель не участник проекта (`author_not_member`, `assignee_not_member`)',
  })
  @ApiForbiddenResponse({ description: 'Читатель ничего не меняет (`issue_forbidden`)' })
  async update(
    @Param('key') key: string,
    @Body() body: UpdateIssueDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueDto> {
    return IssueDto.from(await this.issues.update(key, body, actor));
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Удалить задачу',
    description:
      'Только администратор проекта (D-12): участник не удаляет задачи, даже свои. ' +
      'Комментарии, вложения, ссылки и история удаляются вместе с задачей, действие ' +
      'необратимо (US-44). Номер удалённой задачи повторно не выдаётся, и ссылка ' +
      'на неё навсегда отвечает 404.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiNoContentResponse({ description: 'Задача удалена' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`issue_forbidden`)' })
  async remove(@Param('key') key: string, @CurrentUser() actor: AuthenticatedUser): Promise<void> {
    await this.issues.remove(key, actor);
  }

  @Get('history')
  @ApiOperation({
    summary: 'История изменений задачи',
    description:
      'Доступна всем участникам проекта, включая читателя (US-90). Порядок — сначала ' +
      'новые; самая ранняя запись всегда `issue_created` с реальным создателем (D-13).\n\n' +
      'Страница считается **по группам**: одно действие пользователя, изменившее ' +
      'несколько полей, — одна группа с общим временем и автором, и границей страницы ' +
      'она не разрывается. `actor: null` означает системное изменение.\n\n' +
      'История не редактируется и не удаляется никем, включая администратора, поэтому ' +
      'методов записи у неё нет.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiOkResponse({ type: IssueHistoryListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async listHistory(
    @Param('key') key: string,
    @Query() query: ListIssueHistoryQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueHistoryListDto> {
    const page = await this.history.list(key, actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((group) => IssueHistoryGroupDto.from(group)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }

  @Post('links')
  @ApiOperation({
    summary: 'Добавить внешнюю ссылку',
    description:
      'Администратор и участник проекта; читатель — 403 (US-47). Принимаются только ' +
      'адреса со схемой `http` или `https`. Это **не** связь между задачами трекера — ' +
      'связей в MVP нет. Добавление попадает в историю задачи. В ответе — задача целиком ' +
      'с обновлённым списком ссылок.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiCreatedResponse({ type: IssueDto })
  @ApiBadRequestResponse({ description: 'Недопустимая схема адреса (`invalid_link_url`)' })
  @ApiForbiddenResponse({ description: 'Читатель не добавляет ссылки (`issue_forbidden`)' })
  async addLink(
    @Param('key') key: string,
    @Body() body: CreateIssueLinkDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueDto> {
    return IssueDto.from(await this.issues.addLink(key, body, actor));
  }

  @Delete('links/:linkId')
  @ApiOperation({
    summary: 'Удалить внешнюю ссылку',
    description:
      'Администратор и любой участник проекта — в том числе чужую ссылку (US-47). ' +
      'Удаление попадает в историю задачи.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiParam({ name: 'linkId', format: 'uuid' })
  @ApiOkResponse({ type: IssueDto })
  @ApiBadRequestResponse({ description: 'Ссылки нет у этой задачи (`link_not_found`)' })
  @ApiForbiddenResponse({ description: 'Читатель не удаляет ссылки (`issue_forbidden`)' })
  async removeLink(
    @Param('key') key: string,
    @Param('linkId', new ParseUUIDPipe()) linkId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssueDto> {
    return IssueDto.from(await this.issues.removeLink(key, linkId, actor));
  }
}
