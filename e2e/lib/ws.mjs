import WebSocket from 'ws';
import { config } from './config.mjs';

/**
 * Клиент живых обновлений — по контракту `docs/api/websocket.md`.
 *
 * Библиотека `ws`, а не встроенный в Node `WebSocket`, взята по одной причине:
 * рукопожатию нужны заголовки `Cookie` и `Origin`. Браузер ставит их сам, встроенный
 * клиент задавать их не умеет, а без них соединение не откроется вовсе (401).
 *
 * Кадры копятся в буфере, а ожидание строится на условии, а не на паузе: `sleep`
 * в тестах живых обновлений — это либо флак, либо замедление прогона, и обычно и то и другое.
 */
export class RealtimeClient {
  constructor({ token, label = 'ws', origin = config.appOrigin } = {}) {
    this.label = label;
    this.frames = [];
    this.closed = null;
    this.waiters = [];
    this.nextId = 0;

    const headers = {};
    if (token) headers.cookie = `sl_session=${token}`;
    if (origin) headers.origin = origin;

    this.socket = new WebSocket(config.wsUrl, { headers });

    this.opened = new Promise((resolve, reject) => {
      this.socket.on('open', resolve);
      this.socket.on('unexpected-response', (_request, response) => {
        reject(
          new Error(`Рукопожатие ${this.label} отклонено: HTTP ${response.statusCode}`),
        );
      });
      this.socket.on('error', reject);
    });

    this.socket.on('message', (data) => {
      let frame;
      try {
        frame = JSON.parse(data.toString());
      } catch {
        frame = { type: 'non-json', raw: data.toString() };
      }
      // Момент получения нужен проверке D-26: «доходит не позднее чем через 5 секунд».
      frame.receivedAt = Date.now();
      this.frames.push(frame);
      this.#notify();
    });

    this.socket.on('close', (code, reason) => {
      this.closed = { code, reason: reason.toString(), at: Date.now() };
      this.#notify();
    });
  }

  #notify() {
    for (const waiter of [...this.waiters]) {
      waiter();
    }
  }

  /** Ждёт открытия и кадра `ready` — состояния, с которого клиент вправе подписываться. */
  async ready(timeoutMs = 5000) {
    await this.opened;
    return this.waitFor((frame) => frame.type === 'ready', { timeoutMs });
  }

  /**
   * Ждёт кадр, удовлетворяющий предикату. Уже полученные кадры тоже просматриваются:
   * иначе быстрое событие, пришедшее до вызова, было бы потеряно, и тест стал бы флаком.
   */
  waitFor(predicate, { timeoutMs = 5000, what = 'кадр' } = {}) {
    const found = this.frames.find(predicate);
    if (found) return Promise.resolve(found);

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        cleanup();
        reject(
          new Error(
            `${this.label}: не дождались «${what}» за ${timeoutMs} мс. ` +
              `Полученные кадры: ${JSON.stringify(this.frames.map((f) => f.type + (f.event ? `/${f.event}` : '')))}` +
              (this.closed ? `; сокет закрыт кодом ${this.closed.code}` : ''),
          ),
        );
      }, timeoutMs);

      const check = () => {
        const frame = this.frames.find(predicate);
        if (frame) {
          cleanup();
          resolve(frame);
        }
      };

      const cleanup = () => {
        clearTimeout(timer);
        this.waiters = this.waiters.filter((w) => w !== check);
      };

      this.waiters.push(check);
      check();
    });
  }

  /** Ждёт событие по теме. Возвращает кадр вместе с моментом получения. */
  waitForEvent(event, { topic, timeoutMs = 5000 } = {}) {
    return this.waitFor(
      (frame) =>
        frame.type === 'event' &&
        frame.event === event &&
        (topic === undefined || frame.topic.toLowerCase() === topic.toLowerCase()),
      { timeoutMs, what: `событие ${event}${topic ? ` в теме ${topic}` : ''}` },
    );
  }

  waitForClose(timeoutMs = 10000) {
    if (this.closed) return Promise.resolve(this.closed);
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        cleanup();
        reject(new Error(`${this.label}: сокет не закрылся за ${timeoutMs} мс`));
      }, timeoutMs);
      const check = () => {
        if (this.closed) {
          cleanup();
          resolve(this.closed);
        }
      };
      const cleanup = () => {
        clearTimeout(timer);
        this.waiters = this.waiters.filter((w) => w !== check);
      };
      this.waiters.push(check);
      check();
    });
  }

  send(frame) {
    this.socket.send(JSON.stringify(frame));
  }

  /** Подписка на тему; возвращает канонический ярлык, который вернул сервер. */
  async subscribe(topic, { timeoutMs = 5000 } = {}) {
    const id = `sub-${++this.nextId}`;
    this.send({ type: 'subscribe', id, topic });
    const frame = await this.waitFor(
      (f) => (f.type === 'subscribed' || f.type === 'error') && f.id === id,
      { timeoutMs, what: `ответ на подписку ${topic}` },
    );
    if (frame.type === 'error') {
      throw new Error(`${this.label}: подписка на ${topic} отклонена: ${frame.code}`);
    }
    return frame.topic;
  }

  /** Пытается подписаться и возвращает кадр как есть — для проверки отказов. */
  async trySubscribe(topic, { timeoutMs = 5000 } = {}) {
    const id = `sub-${++this.nextId}`;
    this.send({ type: 'subscribe', id, topic });
    return this.waitFor((f) => (f.type === 'subscribed' || f.type === 'error') && f.id === id, {
      timeoutMs,
      what: `ответ на подписку ${topic}`,
    });
  }

  /** Забывает накопленные кадры: измерять задержку доставки надо от действия, а не от начала теста. */
  clear() {
    this.frames = [];
  }

  close() {
    if (this.socket.readyState === WebSocket.OPEN || this.socket.readyState === WebSocket.CONNECTING) {
      this.socket.close();
    }
  }
}

/** Открывает соединение и дожидается `ready`. */
export async function openRealtime(options) {
  const client = new RealtimeClient(options);
  await client.ready();
  return client;
}

/** Пытается открыть соединение; возвращает код HTTP-отказа вместо исключения. */
export async function realtimeHandshake(options) {
  const client = new RealtimeClient(options);
  try {
    await client.ready();
    return { opened: true, client };
  } catch (error) {
    client.close();
    return { opened: false, error: String(error.message ?? error) };
  }
}
