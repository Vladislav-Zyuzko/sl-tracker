import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiGoneResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser, RateLimit } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import { INVITATION_DEFAULT_LIFETIME_DAYS } from './invitation-state.js';
import {
  AcceptInvitationResultDto,
  CreateInvitationDto,
  InvitationDto,
  InvitationListDto,
  InvitationPreviewDto,
  ListInvitationsQueryDto,
} from './dto/invitation.dto.js';
import { InvitationsService } from './invitations.service.js';

/**
 * Управление приглашениями проекта (US-20, US-22). Весь контроллер — только
 * для администратора проекта: участник и читатель получают 403, не-участник — 404.
 */
@ApiTags('invitations')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
@ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
@Controller('projects/:slug/invitations')
export class ProjectInvitationsController {
  constructor(private readonly invitations: InvitationsService) {}

  @Post()
  @ApiOperation({
    summary: 'Создать ссылку-приглашение',
    description:
      'Только администратор проекта (US-20). Роль администратора через приглашение выдать ' +
      `нельзя (D-05), срок жизни — 1, 7 или 30 дней (по умолчанию ${INVITATION_DEFAULT_LIFETIME_DAYS}); ` +
      'бессрочных приглашений нет. По одной ссылке может вступить любое число людей, ' +
      'пока она действует. Полный адрес ссылки — в поле `url`.',
  })
  @ApiParam({ name: 'slug', example: 'sladkiy-limit' })
  @ApiCreatedResponse({ type: InvitationDto })
  async create(
    @Param('slug') slug: string,
    @Body() body: CreateInvitationDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<InvitationDto> {
    const created = await this.invitations.create(
      slug,
      { role: body.role, expiresInDays: body.expiresInDays ?? INVITATION_DEFAULT_LIFETIME_DAYS },
      actor,
    );
    return InvitationDto.from(created);
  }

  @Get()
  @ApiOperation({
    summary: 'Приглашения проекта',
    description:
      'Все приглашения проекта, сначала новые: действующие, истёкшие и отозванные ' +
      'с числом вступивших по каждому (US-22).',
  })
  @ApiOkResponse({ type: InvitationListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Param('slug') slug: string,
    @Query() query: ListInvitationsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<InvitationListDto> {
    const page = await this.invitations.list(slug, actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((view) => InvitationDto.from(view)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }

  @Post(':id/revoke')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Отозвать приглашение',
    description:
      'Отозвать может любой администратор проекта, в том числе не тот, кто создавал ' +
      'ссылку. Сразу после отзыва переход по ссылке даёт 410. Уже вступившие остаются ' +
      'участниками (US-22).',
  })
  @ApiOkResponse({ type: InvitationDto })
  @ApiNotFoundResponse({ description: 'Приглашения нет (`invitation_not_found`)' })
  async revoke(
    @Param('slug') slug: string,
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<InvitationDto> {
    return InvitationDto.from(await this.invitations.revoke(slug, id, actor));
  }
}

/**
 * Приём приглашения по ссылке (US-21). Сессия нужна, а членства в проекте — нет:
 * это единственный вход в проект снаружи.
 *
 * Ограничение частоты обязательно: без него токены можно перебирать.
 */
@ApiTags('invitations')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@Controller('invitations')
export class InvitationAcceptController {
  constructor(private readonly invitations: InvitationsService) {}

  @Get(':token')
  @RateLimit({ name: 'invitation-preview', limit: 60, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Приглашение по токену',
    description:
      'Данные для экрана подтверждения: название проекта, обложка и роль, которую ' +
      'получит человек. Ни задач, ни очередей, ни участников (US-21). Неизвестный токен — ' +
      '404, истёкший или отозванный — 410; по сообщению нельзя понять, существует ли ' +
      'такой проект. `alreadyMember: true` означает, что экран показывать не нужно — ' +
      'клиент сразу открывает проект.',
  })
  @ApiParam({ name: 'token', description: 'Токен из ссылки `/invite/<token>`' })
  @ApiOkResponse({ type: InvitationPreviewDto })
  @ApiNotFoundResponse({ description: 'Токен неизвестен (`invitation_not_found`)' })
  @ApiGoneResponse({ description: 'Истекло или отозвано (`invitation_inactive`)' })
  async preview(
    @Param('token') token: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<InvitationPreviewDto> {
    return this.invitations.preview(token, actor);
  }

  @Post(':token/accept')
  @HttpCode(HttpStatus.OK)
  @RateLimit({ name: 'invitation-accept', limit: 20, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Вступить в проект по приглашению',
    description:
      'Человек становится участником с ролью из приглашения, а его email попадает ' +
      'в список доступа с источником `invitation` — со следующего входа ссылка ему ' +
      'уже не нужна (ADR-0006, п. 3). Тот, кто уже состоит в проекте, просто получает ' +
      'адрес проекта: роль не меняется и не понижается (US-21).',
  })
  @ApiOkResponse({ type: AcceptInvitationResultDto })
  @ApiNotFoundResponse({ description: 'Токен неизвестен (`invitation_not_found`)' })
  @ApiGoneResponse({ description: 'Истекло или отозвано (`invitation_inactive`)' })
  async accept(
    @Param('token') token: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AcceptInvitationResultDto> {
    return this.invitations.accept(token, actor);
  }
}
