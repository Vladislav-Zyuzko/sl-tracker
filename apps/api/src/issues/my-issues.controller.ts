import { Controller, Get, Query } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCookieAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser, RateLimit } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import { MyIssueDto, MyIssueListDto, MyIssuesQueryDto } from './dto/my-issue.dto.js';
import { MyIssuesService } from './my-issues.service.js';

/**
 * Активные задачи текущего пользователя — список сайдбара (US-81, US-82).
 *
 * Фильтрация и поиск серверные: клиенту фильтровать этот список запрещено (D-20),
 * потому что список отдаётся страницами и клиентский фильтр видел бы только первую.
 */
@ApiTags('issues')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@Controller('issues')
export class MyIssuesController {
  constructor(private readonly myIssues: MyIssuesService) {}

  @Get('my-active')
  // Поиск — вторая после входа точка, которую дёшево дёргать в цикле.
  @RateLimit({ name: 'my-active-issues', limit: 120, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Мои активные задачи',
    description:
      'Задачи, где текущий пользователь — исполнитель, а категория статуса **не** `done` ' +
      '(US-81). Других условий нет. Задачи собираются из всех проектов, где пользователь ' +
      'состоит. Порядок: приоритет по убыванию, при равенстве — сначала недавно ' +
      'изменённые. Параметр `q` ищет по подстроке в теме и в ключе среди этого же ' +
      'набора; поиск выполняет сервер (D-20).',
  })
  @ApiOkResponse({ type: MyIssueListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async myActive(
    @Query() query: MyIssuesQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<MyIssueListDto> {
    const page = await this.myIssues.list(actor, {
      limit: query.limit,
      cursor: query.cursor,
      query: query.q,
    });

    return {
      items: page.items.map((row) => MyIssueDto.from(row)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }
}
