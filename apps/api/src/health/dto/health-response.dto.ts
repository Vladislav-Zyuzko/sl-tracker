import { ApiProperty } from '@nestjs/swagger';

export type DependencyStatus = 'up' | 'down';
export type HealthStatus = 'ok' | 'degraded';

export class DependencyHealthDto {
  @ApiProperty({
    type: String,
    enum: ['up', 'down'],
    description: 'Доступна ли зависимость',
  })
  status!: DependencyStatus;

  @ApiProperty({ type: Number, description: 'Время ответа зависимости, мс', example: 3 })
  latencyMs!: number;

  @ApiProperty({
    type: String,
    required: false,
    description:
      'Причина недоступности в общих словах. Внутренние детали и стектрейсы наружу не выходят — они в логах сервера.',
    example: 'нет соединения',
  })
  error?: string;
}

export class HealthResponseDto {
  @ApiProperty({
    type: String,
    enum: ['ok', 'degraded'],
    description: '`ok` — все зависимости доступны; `degraded` — хотя бы одна нет (HTTP 503)',
  })
  status!: HealthStatus;

  @ApiProperty({ type: Number, description: 'Время работы процесса, секунды', example: 128 })
  uptimeSeconds!: number;

  @ApiProperty({ type: DependencyHealthDto, description: 'PostgreSQL' })
  postgres!: DependencyHealthDto;

  @ApiProperty({ type: DependencyHealthDto, description: 'Redis' })
  redis!: DependencyHealthDto;
}
