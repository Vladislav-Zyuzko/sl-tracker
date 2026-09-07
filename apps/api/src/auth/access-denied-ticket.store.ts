import { randomBytes } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { ACCESS_DENIED_TICKET_TTL_SECONDS, REDIS, accessDeniedTicketKey } from '../redis/index.js';

/** 32 байта случайности: тикет не подбирается и не перебирается. */
const TICKET_BYTES = 32;
const TICKET_PATTERN = /^[A-Za-z0-9_-]{43}$/;

/**
 * Одноразовый тикет экрана «Доступ к трекеру закрыт».
 *
 * Экран показывает адрес, под которым человек вошёл, — это снимает самый частый случай
 * «зашёл личным аккаунтом вместо рабочего» (design/screens/access-denied.md). Передавать
 * адрес в query-параметре нельзя: он осядет в истории браузера, в реферере и в логах
 * обратного прокси, а ADR-0006 запрещает писать список доступа в логи.
 *
 * Поэтому в адресе редиректа — тикет, а адрес отдаётся один раз по обмену и тут же
 * забывается. Больше тикет не раскрывает ничего: ни существования записи в списке,
 * ни состава трекера.
 */
@Injectable()
export class AccessDeniedTicketStore {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async issue(email: string): Promise<string> {
    const ticket = randomBytes(TICKET_BYTES).toString('base64url');
    await this.redis.set(
      accessDeniedTicketKey(ticket),
      email,
      'EX',
      ACCESS_DENIED_TICKET_TTL_SECONDS,
    );
    return ticket;
  }

  /** Читает и сразу гасит тикет. `null` — неизвестен, истёк или уже использован. */
  async consume(ticket: string): Promise<string | null> {
    if (!TICKET_PATTERN.test(ticket)) {
      return null;
    }
    return this.redis.getdel(accessDeniedTicketKey(ticket));
  }
}
