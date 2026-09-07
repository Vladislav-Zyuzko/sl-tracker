import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import {
  ApiOkResponse,
  ApiOperation,
  ApiServiceUnavailableResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { FastifyReply } from 'fastify';
import { Public } from '../auth/decorators/public.decorator.js';
import { HealthResponseDto } from './dto/health-response.dto.js';
import { HealthService } from './health.service.js';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  /**
   * Состояние сервиса и его зависимостей.
   *
   * Путь `/api/health` прописан в боевом Caddyfile как health-проба обратного прокси —
   * менять его нельзя. 200 — сервис принимает трафик, 503 — не принимает.
   */
  @Get()
  @Public()
  @ApiOperation({
    summary: 'Проверка доступности сервиса и его зависимостей',
    description:
      'Отвечает 200, если доступны PostgreSQL и Redis, иначе 503. Авторизация не требуется: ' +
      'эндпоинт используется как health-проба обратного прокси.',
  })
  @ApiOkResponse({ type: HealthResponseDto, description: 'Все зависимости доступны' })
  @ApiServiceUnavailableResponse({
    type: HealthResponseDto,
    description: 'Хотя бы одна зависимость недоступна',
  })
  async check(@Res({ passthrough: true }) reply: FastifyReply): Promise<HealthResponseDto> {
    const result = await this.healthService.check();
    reply.status(result.status === 'ok' ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE);
    return result;
  }
}
