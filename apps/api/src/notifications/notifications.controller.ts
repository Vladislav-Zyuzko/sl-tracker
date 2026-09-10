import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCookieAuth,
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
  ListNotificationsQueryDto,
  MarkAllReadResultDto,
  NotificationDto,
  NotificationListDto,
  NotificationSettingDto,
  NotificationSettingsDto,
  UnreadCountDto,
  UpdateNotificationSettingsDto,
} from './dto/notification.dto.js';
import { NotificationsService } from './notifications.service.js';

/**
 * Центр уведомлений и настройки подписки (US-100 … US-104, US-23).
 *
 * Все методы работают только со **своими** уведомлениями: получатель берётся
 * из сессии и в запрос от клиента не приходит (permissions.md, раздел 2.6).
 */
@ApiTags('notifications')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  @ApiOperation({
    summary: 'Мои уведомления',
    description:
      'Лента, сначала новые. Порция по умолчанию — 30, жёсткий максимум 100; ' +
      'пагинация курсорная (`nextCursor` подставляется как есть).\n\n' +
      'Текст строки собирается из `type`, `actor` и `payload`: `payload` — **снимок ' +
      'на момент события**, он не меняется вслед за переименованием задачи или правкой ' +
      'комментария (US-102). Поля `issueKey` и `commentId` верхнего уровня — наоборот, ' +
      'состояние сейчас: `null` в них означает, что переходить некуда (задача удалена ' +
      'или пользователь больше не в проекте; комментарий удалён).\n\n' +
      '`unreadCount` в ответе — то же число, что отдаёт `/api/notifications/unread-count`: ' +
      'экран может не делать второй запрос ради счётчика в своей шапке.',
  })
  @ApiOkResponse({ type: NotificationListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Query() query: ListNotificationsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<NotificationListDto> {
    const page = await this.notifications.list(actor, { limit: query.limit, cursor: query.cursor });

    return {
      items: page.items.map((row) => NotificationDto.from(row)),
      nextCursor: page.nextCursor,
      total: page.total,
      unreadCount: page.unreadCount,
    };
  }

  @Get('unread-count')
  @ApiOperation({
    summary: 'Счётчик непрочитанных',
    description:
      'Дешёвый запрос для колокольчика в шапке: считается по частичному индексу. ' +
      'Отдаётся точное число — «99+» рисует интерфейс (US-103).',
  })
  @ApiOkResponse({ type: UnreadCountDto })
  async unreadCount(@CurrentUser() actor: AuthenticatedUser): Promise<UnreadCountDto> {
    return { unreadCount: await this.notifications.unreadCount(actor) };
  }

  @Get('settings')
  @ApiOperation({
    summary: 'Настройки подписки',
    description:
      'Все типы уведомлений с признаком «включено». По умолчанию включены все (US-103); ' +
      'типы, которые пользователь никогда не трогал, тоже присутствуют в ответе.\n\n' +
      'Канал хранится отдельным измерением, хотя в MVP он один — `in_app`: появление ' +
      'email не должно потребовать от пользователя перенастройки (D-18).',
  })
  @ApiOkResponse({ type: NotificationSettingsDto })
  async settings(@CurrentUser() actor: AuthenticatedUser): Promise<NotificationSettingsDto> {
    const items = await this.notifications.settings(actor);
    return { items: items.map((row) => NotificationSettingDto.from(row)) };
  }

  @Put('settings')
  @ApiOperation({
    summary: 'Изменить настройки подписки',
    description:
      'Меняются только перечисленные типы, остальные остаются как были. Отключённый ' +
      'тип не создаёт ни записи в центре уведомлений, ни увеличения счётчика — то есть ' +
      'уведомление не появляется вовсе, а не скрывается (US-103). Уже полученные ' +
      'уведомления отключение типа не удаляет.',
  })
  @ApiOkResponse({ type: NotificationSettingsDto })
  async updateSettings(
    @Body() body: UpdateNotificationSettingsDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<NotificationSettingsDto> {
    const items = await this.notifications.saveSettings(actor, body.items);
    return { items: items.map((row) => NotificationSettingDto.from(row)) };
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Отметить все как прочитанные',
    description:
      'Строки не исчезают и не переупорядочиваются — гаснут только точки непрочитанного ' +
      '(US-103). В ответе — сколько записей изменилось.',
  })
  @ApiOkResponse({ type: MarkAllReadResultDto })
  async markAllRead(@CurrentUser() actor: AuthenticatedUser): Promise<MarkAllReadResultDto> {
    return { updated: await this.notifications.markAllRead(actor) };
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Отметить уведомление прочитанным',
    description:
      'Идемпотентно: повторный вызов не меняет время прочтения. Чужое уведомление — ' +
      '404: о его существовании клиент не узнаёт.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: UnreadCountDto, description: 'Счётчик непрочитанных после пометки' })
  @ApiNotFoundResponse({ description: 'Уведомления нет или оно чужое (`notification_not_found`)' })
  async markRead(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<UnreadCountDto> {
    await this.notifications.markRead(actor, id);
    return { unreadCount: await this.notifications.unreadCount(actor) };
  }
}
