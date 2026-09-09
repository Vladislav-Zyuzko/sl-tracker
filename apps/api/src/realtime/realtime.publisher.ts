import { Inject, Injectable, Logger } from '@nestjs/common';
import type { Redis } from 'ioredis';
import { type Executor, afterCommit } from '../database/index.js';
import { REDIS } from '../redis/index.js';
import {
  REALTIME_CONTROL_CHANNEL,
  type RealtimeControlMessage,
  type RealtimeEvent,
  encodeEnvelope,
  realtimeChannel,
} from './realtime.events.js';

/**
 * Публикация живых обновлений в Redis pub/sub.
 *
 * Почему pub/sub, а не рассылка внутри процесса: экземпляров API может быть больше
 * одного, и человек, открывший задачу, почти наверняка держит сокет не на том узле,
 * где произошло изменение. Внутрипроцессная рассылка молча перестала бы работать
 * ровно тогда, когда сервер масштабируют.
 *
 * Доставка **не гарантирована** и гарантирована быть не должна: pub/sub не хранит
 * сообщений, а сокет может быть закрыт. Живое обновление — ускорение, а не источник
 * правды: пропущенное событие клиент восполняет обычным запросом при следующем
 * действии или переподключении. Поэтому ни одна ошибка публикации не роняет запрос,
 * который её породил.
 */
@Injectable()
export class RealtimePublisher {
  private readonly logger = new Logger(RealtimePublisher.name);

  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  /**
   * Опубликовать события **после фиксации** транзакции.
   *
   * Единственный правильный способ публиковать из доменного кода: событие, ушедшее
   * изнутри транзакции, обгоняет её — клиент приходит за данными, которых ещё нет.
   * Вызывающая транзакция обязана быть открыта через `UnitOfWork`, иначе события
   * уйдут немедленно (см. `afterCommit`).
   */
  after(tx: Executor, events: readonly RealtimeEvent[]): void {
    if (events.length === 0) {
      return;
    }
    afterCommit(tx, () => this.publish(events));
  }

  /**
   * Опубликовать немедленно. Годится там, где транзакции нет и запись уже
   * зафиксирована: смена роли участника, пометка уведомления прочитанным.
   */
  async publish(events: readonly RealtimeEvent[]): Promise<void> {
    if (events.length === 0) {
      return;
    }

    try {
      const pipeline = this.redis.multi();
      for (const event of events) {
        pipeline.publish(realtimeChannel(event.topic), encodeEnvelope(event));
      }
      await pipeline.exec();
    } catch (error) {
      // Событие потеряно — данные целы. Наружу это не выносится.
      this.logger.warn(`Не удалось опубликовать событие: ${message(error)}`);
    }
  }

  /**
   * Отзыв доступа: закрыть все сокеты этого человека на всех узлах (US-09, ADR-0006).
   *
   * Сессии гасятся отдельно и раньше — здесь только сокеты, которые уже открыты
   * и HTTP-проверку сессии больше не проходят.
   */
  async revokeUser(userId: string): Promise<void> {
    await this.control({ type: 'user_revoked', userId });
  }

  /** Выход из трекера: закрыть сокеты, открытые под этой сессией (US-03). */
  async revokeSession(sessionId: string): Promise<void> {
    await this.control({ type: 'session_revoked', sessionId });
  }

  private async control(message_: RealtimeControlMessage): Promise<void> {
    try {
      await this.redis.publish(REALTIME_CONTROL_CHANNEL, JSON.stringify(message_));
    } catch (error) {
      // Запасной путь есть: gateway перепроверяет сессию на каждом такте heartbeat,
      // так что отозванный доступ закроет сокет и без этого сообщения — просто
      // не мгновенно, а в течение периода проверки.
      this.logger.warn(`Не удалось разослать служебное сообщение: ${message(error)}`);
    }
  }
}

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
