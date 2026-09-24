import { ConflictException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { type IssuedSession, SessionService, type SessionSummary } from '../sessions/index.js';

/**
 * Срок по умолчанию — год: токен живёт в конфигурации агента, и заставлять человека
 * перевыпускать его каждый месяц значит получить «поставлю-ка я побольше» (RFC MCP, §5.3).
 */
export const PAT_DEFAULT_EXPIRES_IN_DAYS = 365;

/** Верхняя граница срока. Бессрочных токенов не бывает: их забывают отозвать. */
export const PAT_MAX_EXPIRES_IN_DAYS = 3650;

/**
 * Сколько действующих токенов может быть у человека одновременно. Ограничение не
 * от жадности, а от накопления: два десятка живых секретов один человек уже не помнит.
 */
export const PAT_ACTIVE_LIMIT = 20;

const SECONDS_IN_DAY = 24 * 60 * 60;

/** Назначение сессий, которыми управляет этот модуль. Сессии входа он не видит. */
const PAT_PURPOSE = 'pat' as const;

/**
 * Персональные токены доступа.
 *
 * Токен — это долгоживущая bearer-сессия владельца с назначением `pat`, а не отдельная
 * сущность: проверку, кэш и отзыв он получает от `SessionService` без единой строчки
 * в горячем пути запроса (RFC MCP, §5.1). Поэтому здесь нет ни своего репозитория,
 * ни своих запросов к БД — только правила выпуска и владения.
 *
 * Токен всегда выпускается **самому себе**: параметра «выдать другому» нет осознанно.
 * Машинный доступ — это доступ участника, вынесенный в токен, и объём прав токена
 * равен роли владельца в проекте (RFC MCP, §5.2).
 */
@Injectable()
export class TokensService {
  private readonly logger = new Logger(TokensService.name);

  constructor(private readonly sessions: SessionService) {}

  /**
   * Выпускает токен текущему пользователю. Секрет возвращается вызывающему коду
   * единственный раз за всю жизнь токена: в базе остаётся только HMAC от него.
   */
  async issue(
    actor: AuthenticatedUser,
    input: { name: string; expiresInDays?: number },
  ): Promise<IssuedSession & { name: string }> {
    const active = await this.sessions.countActive(actor.id, PAT_PURPOSE);
    if (active >= PAT_ACTIVE_LIMIT) {
      throw new ConflictException({
        code: 'token_limit_reached',
        message: `Достигнут лимит токенов (${PAT_ACTIVE_LIMIT}). Отзовите неиспользуемые`,
      });
    }

    const expiresInDays = input.expiresInDays ?? PAT_DEFAULT_EXPIRES_IN_DAYS;
    const issued = await this.sessions.create(actor.id, 'bearer', {
      label: input.name,
      purpose: PAT_PURPOSE,
      ttlSeconds: expiresInDays * SECONDS_IN_DAY,
    });

    // В лог — факт выпуска и опознавательные признаки, но не секрет и даже не его хеш.
    this.logger.log(
      `Выпущен токен доступа ${issued.id} (префикс ${issued.prefix}), владелец ${actor.id}, срок ${expiresInDays} дн.`,
    );

    return { ...issued, name: input.name };
  }

  /**
   * Свои токены, сначала новые. Сессии входа сюда не попадают: их место — не в списке
   * токенов, и отзывать их этим экраном нельзя.
   */
  async list(
    actor: AuthenticatedUser,
    options: { includeRevoked?: boolean } = {},
  ): Promise<SessionSummary[]> {
    return this.sessions.listForUser(actor.id, PAT_PURPOSE, {
      includeRevoked: options.includeRevoked,
    });
  }

  /**
   * Отзывает свой токен. Идемпотентно: повторный вызов — тоже успех.
   *
   * Чужой, несуществующий и не-PAT идентификатор отвечают одинаково — 404. Разделять
   * их значило бы подтверждать существование чужого токена тому, кто его перебирает.
   */
  async revoke(actor: AuthenticatedUser, tokenId: string): Promise<void> {
    const revoked = await this.sessions.revoke(tokenId, actor.id, PAT_PURPOSE);
    if (!revoked) {
      throw new NotFoundException({ code: 'not_found', message: 'Токен не найден' });
    }

    this.logger.log(`Отозван токен доступа ${tokenId}, владелец ${actor.id}`);
  }
}
