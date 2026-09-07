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
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/auth.types.js';
import { AccessListService } from './access-list.service.js';
import {
  AccessEntryDto,
  AccessEntryListDto,
  RevokeAccessResultDto,
} from './dto/access-entry.dto.js';
import {
  CreateAccessEntryDto,
  ListAccessEntriesQueryDto,
  UpdateAccessEntryDto,
} from './dto/create-access-entry.dto.js';
import { InstanceOwnerGuard } from './guards/instance-owner.guard.js';

/**
 * Экран «Доступ в трекер» (US-07, design/screens/access-list.md).
 * Весь контроллер доступен только владельцу трекера — иначе 403.
 */
@ApiTags('access')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiForbiddenResponse({ description: 'Не владелец трекера (`access_list_forbidden`)' })
@Controller('access-entries')
@UseGuards(InstanceOwnerGuard)
export class AccessController {
  constructor(private readonly accessList: AccessListService) {}

  @Get()
  @ApiOperation({
    summary: 'Список доступа',
    description:
      'Записи от новых к старым, курсорная пагинация. Запись в списке даёт только вход ' +
      'в трекер и никаких прав внутри проектов (ADR-0006).',
  })
  @ApiOkResponse({ type: AccessEntryListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Query() query: ListAccessEntriesQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AccessEntryListDto> {
    const page = await this.accessList.list({
      limit: query.limit,
      cursor: query.cursor,
      query: query.q,
    });

    return {
      items: page.items.map((row) => AccessEntryDto.from(row, actor)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Добавить адрес в список доступа',
    description:
      'Источник записи — `manual`, признак владельца ей не выдаётся. Человек может войти ' +
      'сразу, без перезапуска сервиса (US-06).',
  })
  @ApiCreatedResponse({ type: AccessEntryDto })
  @ApiBadRequestResponse({ description: 'Некорректный адрес (`invalid_email`)' })
  @ApiConflictResponse({ description: 'Адрес уже в списке (`access_entry_exists`)' })
  async add(
    @Body() body: CreateAccessEntryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AccessEntryDto> {
    const created = await this.accessList.add(body.email, actor);
    return AccessEntryDto.from(created, actor);
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Выдать или снять признак владельца трекера',
    description:
      'Снять признак с последнего владельца нельзя: в трекере всегда есть хотя бы один ' +
      'владелец (US-07).',
  })
  @ApiOkResponse({ type: AccessEntryDto })
  @ApiNotFoundResponse({ description: 'Записи нет (`access_entry_not_found`)' })
  @ApiConflictResponse({ description: 'Последний владелец (`last_instance_owner`)' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: UpdateAccessEntryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AccessEntryDto> {
    const updated = await this.accessList.setInstanceOwner(id, body.isInstanceOwner);
    return AccessEntryDto.from(updated, actor);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Отозвать доступ',
    description:
      'Удаляет запись и **немедленно гасит все сессии** этого человека: запросы из уже ' +
      'открытых вкладок получают 401 (US-09). Комментарии, история, авторство и членство ' +
      'в проектах сохраняются.',
  })
  @ApiOkResponse({ type: RevokeAccessResultDto })
  @ApiNotFoundResponse({ description: 'Записи нет (`access_entry_not_found`)' })
  @ApiConflictResponse({
    description:
      'Своя запись (`cannot_revoke_self`) или последний владелец (`last_instance_owner`)',
  })
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<RevokeAccessResultDto> {
    return this.accessList.remove(id, actor);
  }
}
