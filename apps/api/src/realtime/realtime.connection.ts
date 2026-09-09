import type { WebSocket } from 'ws';
import type { AuthenticatedUser } from '../auth/index.js';
import type { ServerFrame } from './realtime.protocol.js';

/**
 * Одно открытое соединение.
 *
 * Всё состояние подписок живёт **здесь**, а не в отдельном хранилище: закрылся сокет —
 * состояние исчезло вместе с ним, и подписке негде подтечь. Переподключение поэтому
 * не «чинит» ничего на сервере: клиент открывает новое соединение и подписывается
 * заново, как в первый раз.
 *
 * Идентификатор сессии здесь есть (по нему закрывают сокет при выходе), но наружу
 * он не уходит ни в одном кадре: это секрет, по которому предъявляется сессия.
 */
export class RealtimeConnection {
  /** Канал Redis → канонический ярлык темы, под которым он отдаётся клиенту. */
  readonly channels = new Map<string, string>();

  /** Ярлык, как его написал клиент → канал. Нужен, чтобы отписка нашла свою тему. */
  readonly aliases = new Map<string, string>();

  /** Ответил ли клиент на прошлый heartbeat. `false` на следующем такте — обрыв. */
  alive = true;

  constructor(
    private readonly socket: WebSocket,
    readonly user: AuthenticatedUser,
    readonly sessionId: string,
  ) {}

  send(frame: ServerFrame): void {
    // OPEN === 1. Сравнение с числом, чтобы не тащить значение перечисления из ws.
    if (this.socket.readyState !== 1) {
      return;
    }
    this.socket.send(JSON.stringify(frame));
  }

  remember(channel: string, canonicalLabel: string, requestedLabel: string): void {
    this.channels.set(channel, canonicalLabel);
    this.aliases.set(canonicalLabel, channel);
    this.aliases.set(requestedLabel, channel);
  }

  forget(channel: string): void {
    this.channels.delete(channel);
    for (const [label, target] of this.aliases) {
      if (target === channel) {
        this.aliases.delete(label);
      }
    }
  }

  channelOf(label: string): string | null {
    return this.aliases.get(label) ?? null;
  }

  ping(): void {
    if (this.socket.readyState === 1) {
      this.socket.ping();
    }
  }

  close(code: number, reason: string): void {
    this.socket.close(code, reason);
  }

  terminate(): void {
    this.socket.terminate();
  }
}
