import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCookieAuth,
  ApiForbiddenResponse,
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
  ListMembersQueryDto,
  ProjectMemberDto,
  ProjectMemberListDto,
  RemoveMemberResultDto,
  UpdateMemberRoleDto,
} from './dto/member.dto.js';
import { MembersService } from './members.service.js';

/**
 * Участники проекта и их роли (US-14 … US-16).
 *
 * Список видят все участники проекта, включая читателя. Менять состав и роли может
 * только администратор — кроме одного случая: выйти из проекта человек может сам.
 */
@ApiTags('projects')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
@Controller('projects/:slug/members')
export class MembersController {
  constructor(private readonly members: MembersService) {}

  @Get()
  @ApiOperation({
    summary: 'Участники проекта',
    description:
      'Виден всем участникам проекта, включая читателя (US-14). Порядок: сначала ' +
      'администраторы, дальше по имени.',
  })
  @ApiParam({ name: 'slug', example: 'sladkiy-limit' })
  @ApiOkResponse({ type: ProjectMemberListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Param('slug') slug: string,
    @Query() query: ListMembersQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectMemberListDto> {
    const page = await this.members.list(slug, actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((row) => ProjectMemberDto.from(row, actor.id)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }

  @Patch(':userId')
  @ApiOperation({
    summary: 'Изменить роль участника',
    description:
      'Только администратор (US-15). Администратор может понизить себя, если он ' +
      'не последний. Понижение последнего администратора — 409.',
  })
  @ApiOkResponse({ type: ProjectMemberDto })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiConflictResponse({
    description: 'Последний администратор проекта (`last_project_admin`)',
  })
  async changeRole(
    @Param('slug') slug: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() body: UpdateMemberRoleDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectMemberDto> {
    const updated = await this.members.changeRole(slug, userId, body.role, actor);
    return ProjectMemberDto.from(updated, actor.id);
  }

  @Delete(':userId')
  @ApiOperation({
    summary: 'Исключить участника или выйти из проекта',
    description:
      'Исключить другого может только администратор; выйти самостоятельно может любой ' +
      'участник — для этого в `userId` передаётся собственный идентификатор (US-16). ' +
      'Последний администратор не уходит ни тем, ни другим путём — 409.\n\n' +
      'Задачи исключённого остаются, поле «Исполнитель» в них очищается, и на каждую ' +
      'такую задачу пишется запись истории в той же транзакции (D-31).',
  })
  @ApiOkResponse({ type: RemoveMemberResultDto })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiConflictResponse({
    description: 'Последний администратор проекта (`last_project_admin`)',
  })
  async remove(
    @Param('slug') slug: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<RemoveMemberResultDto> {
    return this.members.remove(slug, userId, actor);
  }
}
