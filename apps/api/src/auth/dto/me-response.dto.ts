import { ApiProperty } from '@nestjs/swagger';
import type { SessionKind } from '../../sessions/index.js';
import type { AuthenticatedUser } from '../auth.types.js';

export class MeSessionDto {
  @ApiProperty({
    enum: ['cookie', 'bearer'],
    description: 'Чем предъявлена сессия. На права не влияет — это транспорт (ADR-0002).',
  })
  kind!: SessionKind;

  @ApiProperty({ type: String, format: 'date-time', description: 'Когда сессия истекает' })
  expiresAt!: string;
}

/**
 * Текущий пользователь.
 *
 * Проектных ролей здесь нет: проектов в API пока нет, и выдумывать поле, которое
 * фронт начнёт использовать, нельзя. Появятся проекты — появится и членство,
 * отдельным эндпоинтом.
 */
export class MeResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'Анна Петрова', description: 'Имя из Яндекс ID, обновляется при входе' })
  displayName!: string;

  @ApiProperty({ example: 'anna@yandex.ru' })
  email!: string;

  @ApiProperty({ type: String, nullable: true, description: 'Аватар из Яндекс ID' })
  avatarUrl!: string | null;

  @ApiProperty({
    description:
      'Владелец трекера — единственная глобальная роль (permissions.md, п. 1.2). ' +
      'Прав внутри проектов не даёт.',
  })
  isInstanceOwner!: boolean;

  @ApiProperty({
    description:
      'Показывать ли пункт «Доступ к трекеру». Флаг приходит с сервера готовым: клиент ' +
      'не вычисляет право сам (design/screens/access-list.md, Q-D30).',
  })
  canManageAccessList!: boolean;

  @ApiProperty({ type: MeSessionDto })
  session!: MeSessionDto;

  static from(
    user: AuthenticatedUser,
    session: { kind: SessionKind; expiresAt: Date },
  ): MeResponseDto {
    return {
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      isInstanceOwner: user.isInstanceOwner,
      canManageAccessList: user.isInstanceOwner,
      session: { kind: session.kind, expiresAt: session.expiresAt.toISOString() },
    };
  }
}
