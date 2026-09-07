import { Controller, Get } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCookieAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { SessionRecord } from '../sessions/index.js';
import type { AuthenticatedUser } from './auth.types.js';
import { CurrentSession, CurrentUser } from './decorators/current-user.decorator.js';
import { MeResponseDto } from './dto/me-response.dto.js';

/**
 * `/api/me` — то, чем фронт проверяет, вошёл ли пользователь (US-01, US-04).
 * Отдельный контроллер, потому что путь лежит вне `/api/auth/*`.
 */
@ApiTags('auth')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@Controller('me')
export class MeController {
  @Get()
  @ApiOperation({
    summary: 'Текущий пользователь',
    description:
      'Профиль из Яндекс ID и права уровня инстанса. 401 означает «сессии нет или она ' +
      'завершена» — в том числе после отзыва доступа (US-09).',
  })
  @ApiOkResponse({ type: MeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Нет сессии (`session_required`, `session_expired`)' })
  me(
    @CurrentUser() user: AuthenticatedUser,
    @CurrentSession() session: SessionRecord,
  ): MeResponseDto {
    return MeResponseDto.from(user, session);
  }
}
