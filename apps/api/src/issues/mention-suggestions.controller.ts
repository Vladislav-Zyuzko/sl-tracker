import { Controller, Get, Param, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCookieAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser, RateLimit } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import {
  MentionSuggestionListDto,
  MentionSuggestionsQueryDto,
} from './dto/mention-suggestion.dto.js';
import { MentionSuggestionsService } from './mention-suggestions.service.js';

/**
 * Подсказка `@` для поля комментария и редактора описания (US-74).
 *
 * Живёт в домене задач, потому что состав подсказки определяется проектом **этой**
 * задачи, а не текущим пользователем.
 */
@ApiTags('mentions')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Задачи нет или пользователь не участник проекта' })
@Controller('issues/:key/mention-suggestions')
export class MentionSuggestionsController {
  constructor(private readonly suggestions: MentionSuggestionsService) {}

  @Get()
  @RateLimit({ name: 'mention-suggestions', limit: 120, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Подсказка упоминаний',
    description:
      'Участники проекта, которому принадлежит задача, отфильтрованные по имени ' +
      'и email без учёта регистра (US-74). Порядок — по имени; не более 10 строк ' +
      'по умолчанию.\n\n' +
      'В подсказку попадают участники **в любой роли**, включая читателя ' +
      'и администратора; посторонние пользователи трекера — никогда, и перебором ' +
      'состав трекера отсюда не узнать: выборка идёт по участникам проекта, а не ' +
      'по пользователям (D-41, ADR-0006, п. 6). Себя подсказка показывает — упомянуть ' +
      'себя можно, уведомление себе при этом не приходит.\n\n' +
      'Идентификатор из ответа подставляется в токен `@[Имя](user:<uuid>)` в тексте ' +
      'комментария или описания. Читатель текстов не создаёт и получает 403 (D-29). ' +
      'Маршрут ограничен по частоте: это поиск.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42', description: 'Ключ задачи, регистронезависим' })
  @ApiOkResponse({ type: MentionSuggestionListDto })
  @ApiForbiddenResponse({ description: 'Читатель никого не упоминает (`mention_forbidden`)' })
  @ApiTooManyRequestsResponse({ description: 'Слишком часто (`rate_limited`)' })
  async suggest(
    @Param('key') key: string,
    @Query() query: MentionSuggestionsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<MentionSuggestionListDto> {
    const items = await this.suggestions.suggest(key, actor, {
      query: query.query,
      limit: query.limit,
    });

    return { items };
  }
}
