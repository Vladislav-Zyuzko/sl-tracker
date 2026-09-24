import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
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
  ApiNoContentResponse,
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
import { CreateTokenDto, ListTokensQueryDto } from './dto/create-token.dto.js';
import { IssuedTokenDto, TokenDto, TokenListDto } from './dto/token.dto.js';
import { CookieSessionGuard } from './guards/cookie-session.guard.js';
import { TokensService } from './tokens.service.js';

/**
 * Экран «Токены доступа» в профиле (RFC MCP, SPEC-PAT-API §5).
 *
 * Весь контроллер работает только со **своими** токенами: владелец берётся из сессии
 * и параметром не приходит. И весь контроллер требует cookie-сессии — токеном нельзя
 * ни выпустить новый токен, ни посмотреть список, ни отозвать чужой (`CookieSessionGuard`).
 */
@ApiTags('tokens')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiForbiddenResponse({
  description:
    'Запрос сделан токеном, а не из браузера (`pat_cannot_manage_tokens`): управлять ' +
    'токенами может только человек из веб-интерфейса.',
})
@Controller('tokens')
@UseGuards(CookieSessionGuard)
export class TokensController {
  constructor(private readonly tokens: TokensService) {}

  @Get()
  @ApiOperation({
    summary: 'Мои токены доступа',
    description:
      'Сначала новые. Секрета в ответе нет ни при каких условиях — в базе его и не ' +
      'существует, хранится только HMAC. Сессии входа в список не попадают.',
  })
  @ApiOkResponse({ type: TokenListDto })
  async list(
    @Query() query: ListTokensQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<TokenListDto> {
    const rows = await this.tokens.list(actor, { includeRevoked: query.includeRevoked });
    const items = rows.map((row) => TokenDto.from(row));

    return { items, total: items.length };
  }

  @Post()
  @RateLimit({ name: 'tokens-create', limit: 10, windowSeconds: 60 })
  @ApiOperation({
    summary: 'Выпустить токен доступа',
    description:
      'Токен выпускается **текущему пользователю** и даёт ровно его права: отдельной ' +
      'машинной идентичности в трекере нет, задачи и комментарии подписываются владельцем ' +
      'токена (RFC MCP, §5.2).\n\n' +
      '**Секрет возвращается единственный раз** — в этом ответе. Повторно получить его ' +
      'нельзя: в базе лежит только HMAC. Потерян — выпускайте новый и отзывайте старый.\n\n' +
      'Срок обязателен и конечен: по умолчанию 365 дней, допустимо 1..3650. Использование ' +
      'токена срок **не продлевает**.',
  })
  @ApiCreatedResponse({ type: IssuedTokenDto })
  @ApiBadRequestResponse({
    description:
      'Название пустое или длиннее 64 символов (`invalid_token_name`); срок не целое ' +
      'число, `null` или вне диапазона 1..3650 (`invalid_expires_in_days`).',
  })
  @ApiConflictResponse({
    description: 'Больше 20 действующих токенов (`token_limit_reached`)',
  })
  @ApiTooManyRequestsResponse({ description: 'Слишком частые запросы (`rate_limited`)' })
  async create(
    @Body() body: CreateTokenDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<IssuedTokenDto> {
    const issued = await this.tokens.issue(actor, {
      name: body.name,
      expiresInDays: body.expiresInDays,
    });

    return IssuedTokenDto.from(issued);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Отозвать токен',
    description:
      'Действует немедленно: следующий запрос с этим токеном получает 401 ' +
      '`session_expired`. Идемпотентно — повторный отзыв своего токена тоже 204.\n\n' +
      'Чужой, несуществующий и не-PAT идентификатор отвечают одинаково (404): ' +
      'существование чужого токена раскрывать нельзя.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Идентификатор токена из списка' })
  @ApiNoContentResponse({ description: 'Токен отозван' })
  @ApiNotFoundResponse({ description: 'Токена нет или он не ваш (`not_found`)' })
  async revoke(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<void> {
    await this.tokens.revoke(actor, id);
  }
}
