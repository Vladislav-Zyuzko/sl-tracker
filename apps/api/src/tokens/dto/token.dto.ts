import { ApiProperty } from '@nestjs/swagger';
import type { IssuedSession, SessionSummary } from '../../sessions/index.js';

export class TokenDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'dsh-mcp', description: 'Имя, которое дал владелец' })
  name!: string;

  @ApiProperty({
    example: '3f9a1c22',
    description:
      'Первые 8 символов токена — чтобы опознать его в списке. Не секрет и не часть ' +
      'проверки: сам секрет не хранится нигде и после выпуска не показывается.',
  })
  prefix!: string;

  @ApiProperty({
    enum: ['pat'],
    description: 'Всегда `pat`: сессии входа через этот раздел не видны и не отзываются.',
  })
  purpose!: 'pat';

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  @ApiProperty({
    type: String,
    format: 'date-time',
    description:
      'Когда токен предъявляли в последний раз, с точностью до суток: чаще раза в день ' +
      'отметка не обновляется. Пока токеном ни разу не пользовались, **не позже** ' +
      '`createdAt` — отметка ставится кодом, а `createdAt` дефолтом базы, и они ' +
      'расходятся на единицы миллисекунд. Признак «ни разу» проверяется как ' +
      '`lastSeenAt <= createdAt`, сравнение на равенство даст ложное «уже пользовались».',
  })
  lastSeenAt!: string;

  @ApiProperty({
    type: String,
    format: 'date-time',
    description:
      'Когда токен перестанет действовать. Срок задаётся при выпуске и **не продлевается** ' +
      'использованием; бессрочных токенов не бывает.',
  })
  expiresAt!: string;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: 'Когда токен отозвали. `null` — токен не отозван.',
  })
  revokedAt!: string | null;

  static from(row: SessionSummary): TokenDto {
    return {
      id: row.id,
      // Имя и префикс у PAT проставляются при выпуске; пустыми они бывают только
      // у сессий входа, которые в эту выборку не попадают.
      name: row.label ?? '',
      prefix: row.prefix ?? '',
      purpose: 'pat',
      createdAt: row.createdAt.toISOString(),
      lastSeenAt: row.lastSeenAt.toISOString(),
      expiresAt: row.expiresAt.toISOString(),
      revokedAt: row.revokedAt ? row.revokedAt.toISOString() : null,
    };
  }
}

export class TokenListDto {
  @ApiProperty({ type: [TokenDto], description: 'Сначала новые' })
  items!: TokenDto[];

  @ApiProperty({ description: 'Сколько токенов в ответе' })
  total!: number;
}

/**
 * Ответ на выпуск токена. Единственное место во всём API, где виден секрет:
 * повторно его получить нельзя ни здесь, ни в списке — в базе лежит только HMAC.
 */
export class IssuedTokenDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'dsh-mcp' })
  name!: string;

  @ApiProperty({ example: '3f9a1c22' })
  prefix!: string;

  @ApiProperty({
    example: '3f9a1c22-1f0e-4a5c-9a1b-0c2d3e4f5a6b.QmFzZTY0VmVyaWZpZXI',
    description:
      'Сам токен. **Показывается ровно один раз** — в этом ответе. Предъявляется ' +
      'заголовком `Authorization: Bearer <токен>` и даёт те же права, что у владельца.',
  })
  token!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  expiresAt!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  createdAt!: string;

  static from(issued: IssuedSession & { name: string }): IssuedTokenDto {
    return {
      id: issued.id,
      name: issued.name,
      prefix: issued.prefix,
      token: issued.token,
      expiresAt: issued.expiresAt.toISOString(),
      createdAt: issued.createdAt.toISOString(),
    };
  }
}
