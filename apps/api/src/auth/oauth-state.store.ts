import { randomBytes } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { OAUTH_STATE_TTL_SECONDS, REDIS, oauthStateKey } from '../redis/index.js';

/** Что мы помним между стартом входа и колбэком. */
export interface OauthStatePayload {
  /** Куда вернуть пользователя после входа. Уже проверенный относительный путь. */
  next: string | null;
  /** Токен приглашения, если человек шёл по ссылке-приглашению (ADR-0006, п. 3). */
  invite: string | null;
}

/** 32 байта — минимум по заданию; base64url даёт 43 символа. */
const STATE_BYTES = 32;

/** Всё, что не похоже на выданный нами `state`, отбрасывается до похода в Redis. */
const STATE_PATTERN = /^[A-Za-z0-9_-]{43}$/;

/**
 * Хранилище `state` для OAuth.
 *
 * `state` одноразовый: он читается и удаляется одной командой `GETDEL`. Поэтому
 * повторный вызов колбэка с тем же адресом (перезагрузка страницы, «повтор» из истории,
 * попытка переиспользовать `code`) не создаёт вторую сессию — он получает
 * `invalid_state`. Без проверки `state` колбэк принимает чужой `code` (ADR-0002).
 */
@Injectable()
export class OauthStateStore {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async issue(payload: OauthStatePayload): Promise<string> {
    const state = randomBytes(STATE_BYTES).toString('base64url');
    await this.redis.set(
      oauthStateKey(state),
      JSON.stringify(payload),
      'EX',
      OAUTH_STATE_TTL_SECONDS,
    );
    return state;
  }

  /** Возвращает полезную нагрузку и сразу гасит `state`. `null` — нет, истёк или уже использован. */
  async consume(state: string): Promise<OauthStatePayload | null> {
    if (!STATE_PATTERN.test(state)) {
      return null;
    }

    const raw = await this.redis.getdel(oauthStateKey(state));
    if (!raw) {
      return null;
    }

    try {
      const parsed: unknown = JSON.parse(raw);
      if (typeof parsed !== 'object' || parsed === null) {
        return null;
      }
      const record = parsed as Record<string, unknown>;
      return {
        next: typeof record.next === 'string' ? record.next : null,
        invite: typeof record.invite === 'string' ? record.invite : null,
      };
    } catch {
      return null;
    }
  }
}
