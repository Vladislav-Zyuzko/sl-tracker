import { Inject, Injectable, Logger } from '@nestjs/common';
import { and, eq, isNull } from 'drizzle-orm';
import type { Redis } from 'ioredis';
import { ENV, type Env } from '../config/index.js';
import { DB, type Database, type Executor } from '../database/index.js';
import { sessions } from '../database/schema/index.js';
import { REDIS, SESSION_TTL_SECONDS, sessionKey, userSessionsKey } from '../redis/index.js';
import {
  formatSessionToken,
  generateSessionId,
  generateSessionVerifier,
  hashSessionVerifier,
  parseSessionToken,
  verifierMatches,
} from './session-token.js';
import type { IssuedSession, SessionKind, SessionRecord } from './session.types.js';

/**
 * Сессия продлевается и отметка «был здесь» обновляется не чаще раза в сутки: иначе
 * каждый запрос превращался бы в запись в PostgreSQL. Требование US-02 — «сессия живёт
 * не меньше 30 дней при периодическом использовании» — этим выполняется.
 */
const SESSION_REFRESH_AFTER_SECONDS = 24 * 60 * 60;

/** Поля сессии в Redis. Только строки: других типов Redis-хеш не знает. */
interface CachedSession {
  userId: string;
  kind: SessionKind;
  tokenHash: string;
  /** Момент истечения, миллисекунды эпохи. */
  expiresAt: string;
  /** Момент последнего обращения, миллисекунды эпохи. */
  lastSeenAt: string;
}

/**
 * Серверные сессии.
 *
 * Быстрый путь — Redis; PostgreSQL — долговременная запись, переживающая перезапуск
 * и очистку кэша. Если Redis сессию потерял (перезапуск, вытеснение), она поднимается
 * из PostgreSQL и возвращается в кэш: перезапуск кэша не выбрасывает людей из приложения.
 *
 * Ключевое требование ADR-0006: отзыв доступа гасит **все** сессии человека немедленно,
 * поэтому сессии всегда находятся по пользователю — и в Redis (множество
 * `sl:sessions:by-user:<userId>`), и в PostgreSQL (индекс по `user_id`).
 *
 * Ни cookie, ни bearer этот сервис не различает по существу: способ предъявления
 * фиксируется полем `kind` и дальше нигде на логику не влияет (ADR-0002).
 */
@Injectable()
export class SessionService {
  private readonly logger = new Logger(SessionService.name);

  constructor(
    @Inject(DB) private readonly db: Database,
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(ENV) private readonly env: Env,
  ) {}

  /**
   * Создаёт сессию и возвращает секрет — единственный раз за её жизнь.
   *
   * Строку в PostgreSQL можно писать в переданной транзакции. Учти: в Redis сессия
   * попадает сразу, поэтому при откате такой транзакции в кэше останется запись,
   * которой в базе нет. Вход этим не пользуется — сессия создаётся отдельно, уже
   * после того, как пользователь зафиксирован.
   */
  async create(
    userId: string,
    kind: SessionKind,
    executor: Executor = this.db,
  ): Promise<IssuedSession> {
    const id = generateSessionId();
    const verifier = generateSessionVerifier();
    const tokenHash = hashSessionVerifier(verifier, this.env.SESSION_SECRET);
    const now = new Date();
    const expiresAt = new Date(now.getTime() + SESSION_TTL_SECONDS * 1000);

    await executor.insert(sessions).values({
      id,
      userId,
      kind,
      tokenHash,
      expiresAt,
      lastSeenAt: now,
    });

    await this.cache(id, {
      userId,
      kind,
      tokenHash,
      expiresAt: String(expiresAt.getTime()),
      lastSeenAt: String(now.getTime()),
    });

    return { id, token: formatSessionToken(id, verifier), expiresAt };
  }

  /**
   * Находит действующую сессию по предъявленному секрету.
   *
   * `null` — единственный ответ на любую неудачу (мусор вместо токена, неизвестный
   * идентификатор, несовпавший верификатор, истёкшая или погашенная сессия): вызывающий
   * код не должен различать причины, иначе появляется оракул.
   */
  async resolve(rawToken: string | undefined | null): Promise<SessionRecord | null> {
    const parsed = parseSessionToken(rawToken);
    if (!parsed) {
      return null;
    }

    const cached = await this.load(parsed.id);
    if (!cached) {
      return null;
    }

    if (!verifierMatches(parsed.verifier, this.env.SESSION_SECRET, cached.tokenHash)) {
      return null;
    }

    const expiresAt = new Date(Number(cached.expiresAt));
    if (!Number.isFinite(expiresAt.getTime()) || expiresAt.getTime() <= Date.now()) {
      await this.forget(parsed.id, cached.userId);
      return null;
    }

    return {
      id: parsed.id,
      userId: cached.userId,
      kind: cached.kind,
      expiresAt,
      lastSeenAt: new Date(Number(cached.lastSeenAt)),
    };
  }

  /**
   * Отмечает обращение и продлевает сессию — не чаще раза в сутки, чтобы обычный запрос
   * не превращался в запись в PostgreSQL.
   *
   * Ошибка продления не отменяет запрос: доступ уже разрешён, продление — удобство.
   */
  async touch(session: SessionRecord): Promise<void> {
    const now = Date.now();
    if (now - session.lastSeenAt.getTime() < SESSION_REFRESH_AFTER_SECONDS * 1000) {
      return;
    }

    const expiresAt = new Date(now + SESSION_TTL_SECONDS * 1000);
    try {
      const [row] = await this.db
        .update(sessions)
        .set({ expiresAt, lastSeenAt: new Date(now) })
        .where(and(eq(sessions.id, session.id), isNull(sessions.revokedAt)))
        .returning({ tokenHash: sessions.tokenHash });

      if (!row) {
        return;
      }

      await this.cache(session.id, {
        userId: session.userId,
        kind: session.kind,
        tokenHash: row.tokenHash,
        expiresAt: String(expiresAt.getTime()),
        lastSeenAt: String(now),
      });
    } catch (error) {
      this.logger.warn(
        `Не удалось продлить сессию: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  /**
   * Жива ли сессия. Проверка по идентификатору, без секрета.
   *
   * Нужна долгоживущим соединениям: WebSocket открыт часами, а сессию за это время
   * могли погасить выходом или отзывом доступа. HTTP-запросы такой проверки не
   * требуют — они предъявляют секрет каждый раз.
   */
  async isActive(sessionId: string): Promise<boolean> {
    const cached = await this.load(sessionId);
    return cached !== null && Number(cached.expiresAt) > Date.now();
  }

  /** Завершает одну сессию — выход пользователя (US-03). */
  async destroy(sessionId: string): Promise<void> {
    const [row] = await this.db
      .update(sessions)
      .set({ revokedAt: new Date() })
      .where(and(eq(sessions.id, sessionId), isNull(sessions.revokedAt)))
      .returning({ userId: sessions.userId });

    const userId = row?.userId ?? (await this.lookupUserId(sessionId));
    await this.forget(sessionId, userId);
  }

  /**
   * Гасит все сессии пользователя. Вызывается при отзыве доступа: человек теряет трекер
   * во всех вкладках и на всех устройствах немедленно (US-09, D-40).
   *
   * Возвращает число погашенных сессий — это не отладочный вывод, а то, что проверяет
   * тест отзыва доступа.
   */
  async destroyAllForUser(userId: string): Promise<number> {
    const revoked = await this.db
      .update(sessions)
      .set({ revokedAt: new Date() })
      .where(and(eq(sessions.userId, userId), isNull(sessions.revokedAt)))
      .returning({ id: sessions.id });

    const ids = new Set(revoked.map((row) => row.id));

    // Множество в Redis читается отдельно: в нём могут остаться сессии, которых уже нет
    // в выборке (помечены отозванными ранее, но ключ в кэше ещё жив).
    for (const id of await this.redis.smembers(userSessionsKey(userId))) {
      ids.add(id);
    }

    if (ids.size > 0) {
      await this.redis.del(...[...ids].map((id) => sessionKey(id)));
    }
    await this.redis.del(userSessionsKey(userId));

    return revoked.length;
  }

  /** Redis — быстрый путь; PostgreSQL — источник правды, если кэш потерял запись. */
  private async load(sessionId: string): Promise<CachedSession | null> {
    const cached = await this.redis.hgetall(sessionKey(sessionId));
    if (cached.userId && cached.kind && cached.tokenHash && cached.expiresAt) {
      return {
        userId: cached.userId,
        kind: cached.kind as SessionKind,
        tokenHash: cached.tokenHash,
        expiresAt: cached.expiresAt,
        lastSeenAt: cached.lastSeenAt ?? cached.expiresAt,
      };
    }

    const [row] = await this.db
      .select({
        userId: sessions.userId,
        kind: sessions.kind,
        tokenHash: sessions.tokenHash,
        expiresAt: sessions.expiresAt,
        lastSeenAt: sessions.lastSeenAt,
      })
      .from(sessions)
      .where(and(eq(sessions.id, sessionId), isNull(sessions.revokedAt)))
      .limit(1);

    if (!row || row.expiresAt.getTime() <= Date.now()) {
      return null;
    }

    const record: CachedSession = {
      userId: row.userId,
      kind: row.kind,
      tokenHash: row.tokenHash,
      expiresAt: String(row.expiresAt.getTime()),
      lastSeenAt: String(row.lastSeenAt.getTime()),
    };

    await this.cache(sessionId, record);
    return record;
  }

  private async cache(sessionId: string, record: CachedSession): Promise<void> {
    const ttlSeconds = Math.max(1, Math.ceil((Number(record.expiresAt) - Date.now()) / 1000));

    await this.redis
      .multi()
      .hset(sessionKey(sessionId), { ...record })
      .expire(sessionKey(sessionId), ttlSeconds)
      .sadd(userSessionsKey(record.userId), sessionId)
      // Множество живёт чуть дольше самой долгой сессии: без TTL оно копило бы
      // идентификаторы вечно, а с более коротким — потеряло бы живые сессии.
      .expire(userSessionsKey(record.userId), SESSION_TTL_SECONDS + 24 * 60 * 60)
      .exec();
  }

  private async lookupUserId(sessionId: string): Promise<string | null> {
    const cached = await this.redis.hget(sessionKey(sessionId), 'userId');
    if (cached) {
      return cached;
    }

    const [row] = await this.db
      .select({ userId: sessions.userId })
      .from(sessions)
      .where(eq(sessions.id, sessionId))
      .limit(1);

    return row?.userId ?? null;
  }

  private async forget(sessionId: string, userId: string | null): Promise<void> {
    const pipeline = this.redis.multi().del(sessionKey(sessionId));
    if (userId) {
      pipeline.srem(userSessionsKey(userId), sessionId);
    }
    await pipeline.exec();
  }
}
