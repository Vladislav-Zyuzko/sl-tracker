import type { IncomingMessage, Server as HttpServer } from 'node:http';
import type { Duplex } from 'node:stream';
import {
  Inject,
  Injectable,
  Logger,
  type OnApplicationBootstrap,
  type OnApplicationShutdown,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import type { Redis } from 'ioredis';
import { type RawData, type WebSocket, WebSocketServer } from 'ws';
import { type AuthenticatedUser, AuthRepository, SESSION_COOKIE_NAME } from '../auth/index.js';
import { ENV, type Env } from '../config/index.js';
import { IssueAccessService, IssuesRepository } from '../issues/index.js';
import { ProjectAccessService } from '../projects/index.js';
import { REDIS_SUBSCRIBER } from '../redis/index.js';
import { SessionService } from '../sessions/index.js';
import { RealtimeConnection } from './realtime.connection.js';
import {
  REALTIME_CONTROL_CHANNEL,
  REALTIME_PATH,
  decodeControl,
  decodeEnvelope,
  issueTopic,
  projectTopic,
  realtimeChannel,
  userTopic,
} from './realtime.events.js';
import {
  CANONICAL_USER_LABEL,
  CLOSE_CODES,
  HEARTBEAT_SECONDS,
  MAX_CLIENT_FRAME_BYTES,
  MAX_TOPICS_PER_CONNECTION,
  type RealtimeErrorCode,
  canonicalIssueLabel,
  canonicalProjectLabel,
  parseClientCommand,
  parseTopicLabel,
} from './realtime.protocol.js';

/** Разрешённая тема: канал Redis, канонический ярлык и проект, дающий на неё право. */
interface ResolvedTopic {
  channel: string;
  label: string;
  projectId: string | null;
}

/**
 * WebSocket-сервер живых обновлений (D-26).
 *
 * **Аутентификация — та же, что у HTTP.** Сессия предъявляется cookie (веб) или
 * заголовком `Authorization: Bearer` (будущая мобилка), проверяется тем же
 * `SessionService`, и соединение без действующей сессии не принимается вовсе:
 * рукопожатие отклоняется ответом 401, а не переходит в сокет, который потом висит.
 *
 * **Право проверяется дважды.** При подписке — теми же `IssueAccessService`
 * и `ProjectAccessService`, что и в REST: второй проверки прав в трекере быть не
 * должно. При каждой рассылке — заново, одним запросом на событие: сокет живёт часами,
 * и человека могли исключить из проекта уже после того, как он подписался. Без второй
 * проверки исключённый продолжал бы читать чужой проект, пока не закроет вкладку.
 *
 * **Что уходит клиенту.** Событие — сигнал: «в этой теме случилось вот это». Полные
 * данные клиент забирает обычным запросом, а поля внутри события названы так же,
 * как в ответах REST. Идентификатор сессии не попадает ни в один кадр.
 */
@Injectable()
export class RealtimeGateway implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(RealtimeGateway.name);
  private readonly appOrigin: string;

  private server: WebSocketServer | null = null;
  private heartbeat: NodeJS.Timeout | null = null;
  private upgradeListener:
    ((request: IncomingMessage, socket: Duplex, head: Buffer) => void) | null = null;

  private readonly connections = new Set<RealtimeConnection>();
  private readonly byUser = new Map<string, Set<RealtimeConnection>>();
  private readonly byChannel = new Map<string, Set<RealtimeConnection>>();
  /** Незавершённые `SUBSCRIBE`: два соединения могут занять один канал одновременно. */
  private readonly channelReady = new Map<string, Promise<unknown>>();

  constructor(
    private readonly adapterHost: HttpAdapterHost,
    private readonly sessions: SessionService,
    private readonly users: AuthRepository,
    private readonly issueAccess: IssueAccessService,
    private readonly projectAccess: ProjectAccessService,
    private readonly issues: IssuesRepository,
    @Inject(REDIS_SUBSCRIBER) private readonly subscriber: Redis,
    @Inject(ENV) env: Env,
  ) {
    this.appOrigin = new URL(env.APP_BASE_URL).origin;
  }

  async onApplicationBootstrap(): Promise<void> {
    const httpServer = this.adapterHost.httpAdapter?.getHttpServer() as HttpServer | undefined;
    if (!httpServer) {
      this.logger.warn('HTTP-сервер недоступен: живые обновления выключены');
      return;
    }

    this.server = new WebSocketServer({ noServer: true, maxPayload: MAX_CLIENT_FRAME_BYTES });

    // Обработчик рукопожатия ставится вручную, а не через `WebSocketServer({ server })`:
    // так аутентификация происходит **до** перехода в сокет, и неаутентифицированное
    // соединение получает честный 401, а не открытый и тут же закрытый сокет.
    this.upgradeListener = (request, socket, head) => {
      void this.onUpgrade(request, socket, head);
    };
    httpServer.on('upgrade', this.upgradeListener);

    this.subscriber.on('message', (channel: string, payload: string) => {
      void this.onRedisMessage(channel, payload);
    });
    await this.subscriber.subscribe(REALTIME_CONTROL_CHANNEL);

    this.heartbeat = setInterval(() => {
      void this.tick();
    }, HEARTBEAT_SECONDS * 1000);
    // Такт heartbeat не должен удерживать процесс живым.
    this.heartbeat.unref();
  }

  onApplicationShutdown(): void {
    if (this.heartbeat) {
      clearInterval(this.heartbeat);
      this.heartbeat = null;
    }

    const httpServer = this.adapterHost.httpAdapter?.getHttpServer() as HttpServer | undefined;
    if (httpServer && this.upgradeListener) {
      httpServer.off('upgrade', this.upgradeListener);
      this.upgradeListener = null;
    }

    for (const connection of [...this.connections]) {
      connection.close(CLOSE_CODES.shuttingDown, 'shutting down');
    }
    this.connections.clear();
    this.byUser.clear();
    this.byChannel.clear();
    this.channelReady.clear();

    this.server?.close();
    this.server = null;
  }

  /** Сколько соединений и каналов держит этот экземпляр. Нужно тестам на утечки. */
  stats(): { connections: number; channels: number } {
    return { connections: this.connections.size, channels: this.byChannel.size };
  }

  // --- Рукопожатие ------------------------------------------------------------

  private async onUpgrade(request: IncomingMessage, socket: Duplex, head: Buffer): Promise<void> {
    const path = (request.url ?? '').split('?')[0];
    if (path !== REALTIME_PATH) {
      // Обработчик `upgrade` в процессе один, поэтому чужой путь закрываем сами:
      // иначе сокет повиснет до таймаута.
      reject(socket, 404, 'Not Found');
      return;
    }

    const authenticated = await this.authenticate(request).catch((error: unknown) => {
      this.logger.warn(`Рукопожатие не проверено: ${message(error)}`);
      return null;
    });

    if (!authenticated) {
      reject(socket, 401, 'Unauthorized');
      return;
    }

    const server = this.server;
    if (!server) {
      reject(socket, 503, 'Service Unavailable');
      return;
    }

    const { user, sessionId } = authenticated;
    server.handleUpgrade(request, socket, head, (ws) => {
      void this.onConnection(ws, user, sessionId);
    });
  }

  /**
   * Сессия из рукопожатия. Ровно те же два способа предъявления, что и в HTTP
   * (ADR-0002), и та же проверка.
   *
   * Cookie дополнительно требует совпадения `Origin`. Это не паранойя: браузер
   * отправляет cookie и при открытии сокета с чужого сайта, а `SameSite` спасает
   * не во всех сочетаниях версий и настроек. Заголовок `Authorization` чужая
   * страница подставить не может — bearer в проверке не нуждается.
   */
  private async authenticate(
    request: IncomingMessage,
  ): Promise<{ user: AuthenticatedUser; sessionId: string } | null> {
    const header = request.headers.authorization;
    const bearer =
      typeof header === 'string' && header.toLowerCase().startsWith('bearer ')
        ? header.slice('bearer '.length).trim()
        : '';

    let token: string;
    if (bearer.length > 0) {
      token = bearer;
    } else {
      const cookie = readCookie(request.headers.cookie, SESSION_COOKIE_NAME);
      if (!cookie || request.headers.origin !== this.appOrigin) {
        return null;
      }
      token = cookie;
    }

    const session = await this.sessions.resolve(token);
    if (!session) {
      return null;
    }

    const user = await this.users.findAuthenticatedUser(session.userId);
    return user ? { user, sessionId: session.id } : null;
  }

  // --- Жизнь соединения -------------------------------------------------------

  private async onConnection(
    socket: WebSocket,
    user: AuthenticatedUser,
    sessionId: string,
  ): Promise<void> {
    const connection = new RealtimeConnection(socket, user, sessionId);
    this.connections.add(connection);
    index(this.byUser, user.id, connection);

    socket.on('pong', () => {
      connection.alive = true;
    });
    socket.on('message', (raw: RawData) => {
      void this.onMessage(connection, raw);
    });
    socket.on('close', () => {
      void this.onClose(connection);
    });
    socket.on('error', (error: Error) => {
      this.logger.debug?.(`Сокет закрылся с ошибкой: ${error.message}`);
    });

    // Своя тема даётся без запроса: счётчик непрочитанных нужен на каждом экране
    // (design/screens/notifications.md), и заставлять клиента подписываться на себя
    // отдельной командой незачем.
    await this.attach(
      connection,
      realtimeChannel(userTopic(user.id)),
      CANONICAL_USER_LABEL,
      CANONICAL_USER_LABEL,
    );

    connection.send({
      type: 'ready',
      topics: [CANONICAL_USER_LABEL],
      heartbeatSeconds: HEARTBEAT_SECONDS,
      maxTopics: MAX_TOPICS_PER_CONNECTION,
    });
  }

  private async onClose(connection: RealtimeConnection): Promise<void> {
    this.connections.delete(connection);

    const forUser = this.byUser.get(connection.user.id);
    if (forUser) {
      forUser.delete(connection);
      if (forUser.size === 0) {
        this.byUser.delete(connection.user.id);
      }
    }

    for (const channel of [...connection.channels.keys()]) {
      await this.detach(connection, channel);
    }
  }

  private async onMessage(connection: RealtimeConnection, raw: RawData): Promise<void> {
    const { command, error } = parseClientCommand(frameText(raw));
    if (error || !command) {
      connection.send({
        type: 'error',
        id: error?.id ?? null,
        code: error?.code ?? 'invalid_message',
        message: error?.message ?? 'Некорректное сообщение',
      });
      return;
    }

    if (command.type === 'ping') {
      // Прикладной ping/pong: браузерный JS не видит кадров протокола и без этого
      // не может сам заметить, что сервер перестал отвечать.
      connection.alive = true;
      connection.send({ type: 'pong', id: command.id });
      return;
    }

    if (command.type === 'unsubscribe') {
      const channel = connection.channelOf(command.topic);
      if (channel) {
        await this.detach(connection, channel);
      }
      // Отписка идемпотентна: незнакомая тема — тоже успех, и это не оракул
      // существования темы.
      connection.send({ type: 'unsubscribed', id: command.id, topic: command.topic });
      return;
    }

    await this.onSubscribe(connection, command.id, command.topic);
  }

  private async onSubscribe(
    connection: RealtimeConnection,
    id: string | null,
    label: string,
  ): Promise<void> {
    const request = parseTopicLabel(label);
    if (!request) {
      this.fail(connection, id, 'invalid_topic', 'Неизвестная тема');
      return;
    }

    if (connection.channels.size >= MAX_TOPICS_PER_CONNECTION && !connection.aliases.has(label)) {
      this.fail(connection, id, 'too_many_topics', 'Слишком много тем на одно соединение');
      return;
    }

    const resolved = await this.resolveTopic(connection.user, request);
    if (!resolved) {
      // Несуществующая и чужая тема снаружи неотличимы — как 404 у REST
      // (permissions.md, п. 5).
      this.fail(connection, id, 'topic_forbidden', 'Тема недоступна');
      return;
    }

    await this.attach(connection, resolved.channel, resolved.label, label);
    connection.send({ type: 'subscribed', id, topic: resolved.label });
  }

  /**
   * Право на тему. Проверяется теми же сервисами, что и HTTP-запрос к тому же ресурсу:
   * ни одной собственной проверки членства здесь нет и быть не должно.
   */
  private async resolveTopic(
    user: AuthenticatedUser,
    request: ReturnType<typeof parseTopicLabel>,
  ): Promise<ResolvedTopic | null> {
    if (!request) {
      return null;
    }

    try {
      if (request.kind === 'user') {
        return {
          channel: realtimeChannel(userTopic(user.id)),
          label: CANONICAL_USER_LABEL,
          projectId: null,
        };
      }

      if (request.kind === 'issue') {
        const context = await this.issueAccess.require(request.key, user);
        return {
          channel: realtimeChannel(issueTopic(context.detail.issue.id)),
          label: canonicalIssueLabel(context.detail.issue.key),
          projectId: context.detail.projectId,
        };
      }

      const context = await this.projectAccess.require(request.slug, user);
      return {
        channel: realtimeChannel(projectTopic(context.project.id)),
        label: canonicalProjectLabel(context.project.slug),
        projectId: context.project.id,
      };
    } catch {
      // 404 и 403 снаружи одинаковы: сокет не должен подсказывать, что скрыто.
      return null;
    }
  }

  // --- Каналы Redis -----------------------------------------------------------

  private async attach(
    connection: RealtimeConnection,
    channel: string,
    canonicalLabel: string,
    requestedLabel: string,
  ): Promise<void> {
    let subscribers = this.byChannel.get(channel);
    if (!subscribers) {
      subscribers = new Set();
      this.byChannel.set(channel, subscribers);
      const ready = this.subscriber.subscribe(channel);
      this.channelReady.set(channel, ready);
    }
    subscribers.add(connection);
    connection.remember(channel, canonicalLabel, requestedLabel);

    try {
      await this.channelReady.get(channel);
    } catch (error) {
      this.logger.warn(`Не удалось подписаться на канал: ${message(error)}`);
    }
  }

  private async detach(connection: RealtimeConnection, channel: string): Promise<void> {
    connection.forget(channel);

    const subscribers = this.byChannel.get(channel);
    if (!subscribers) {
      return;
    }

    subscribers.delete(connection);
    if (subscribers.size > 0) {
      return;
    }

    // Последний слушатель ушёл — канал в Redis больше не нужен. Без этого подписки
    // копились бы на каждой открытой и закрытой задаче.
    this.byChannel.delete(channel);
    this.channelReady.delete(channel);
    try {
      await this.subscriber.unsubscribe(channel);
    } catch (error) {
      this.logger.warn(`Не удалось отписаться от канала: ${message(error)}`);
    }
  }

  private async onRedisMessage(channel: string, payload: string): Promise<void> {
    if (channel === REALTIME_CONTROL_CHANNEL) {
      this.onControl(payload);
      return;
    }

    const envelope = decodeEnvelope(payload);
    if (!envelope) {
      return;
    }

    const targets = [...(this.byChannel.get(channel) ?? [])];
    if (targets.length === 0) {
      return;
    }

    // Одна проверка прав на событие, а не на каждого получателя: даже при десятке
    // слушателей это один запрос, и он обязателен — членство могло измениться
    // после подписки.
    let allowed: Set<string> | null = null;
    if (envelope.projectId) {
      const userIds = [...new Set(targets.map((target) => target.user.id))];
      try {
        allowed = await this.issues.projectMembersAmong(envelope.projectId, userIds);
      } catch (error) {
        this.logger.warn(`Проверка прав при рассылке не удалась: ${message(error)}`);
        return;
      }
    }

    for (const target of targets) {
      const label = target.channels.get(channel);
      if (!label) {
        continue;
      }

      if (allowed && !allowed.has(target.user.id)) {
        // Человека исключили из проекта: подписка снимается прямо сейчас, событие
        // до него не доходит.
        await this.detach(target, channel);
        target.send({
          type: 'error',
          id: null,
          code: 'topic_forbidden',
          message: 'Тема недоступна',
        });
        continue;
      }

      target.send({
        type: 'event',
        topic: label,
        event: envelope.event,
        at: envelope.at,
        actorId: envelope.actorId,
        data: envelope.data,
      });
    }
  }

  private onControl(payload: string): void {
    const control = decodeControl(payload);
    if (!control) {
      return;
    }

    if (control.type === 'user_revoked') {
      for (const connection of [...(this.byUser.get(control.userId) ?? [])]) {
        connection.close(CLOSE_CODES.revoked, 'access revoked');
      }
      return;
    }

    for (const connection of [...this.connections]) {
      if (connection.sessionId === control.sessionId) {
        connection.close(CLOSE_CODES.revoked, 'session closed');
      }
    }
  }

  // --- Живость ----------------------------------------------------------------

  /**
   * Такт heartbeat: не ответившее соединение обрывается, а сессия каждого
   * оставшегося перепроверяется.
   *
   * Перепроверка сессии — запасной путь к тому же, что делает служебный канал:
   * если сообщение об отзыве доступа потерялось, сокет всё равно закроется,
   * просто в течение такта, а не мгновенно.
   */
  private async tick(): Promise<void> {
    for (const connection of [...this.connections]) {
      if (!connection.alive) {
        connection.terminate();
        continue;
      }
      connection.alive = false;
      connection.ping();
    }

    const checked = new Map<string, boolean>();
    for (const connection of [...this.connections]) {
      let active = checked.get(connection.sessionId);
      if (active === undefined) {
        try {
          active = await this.sessions.isActive(connection.sessionId);
        } catch {
          // Недоступное хранилище сессий — не повод выбрасывать людей из трекера.
          active = true;
        }
        checked.set(connection.sessionId, active);
      }
      if (!active) {
        connection.close(CLOSE_CODES.unauthorized, 'session expired');
      }
    }
  }

  private fail(
    connection: RealtimeConnection,
    id: string | null,
    code: RealtimeErrorCode,
    text: string,
  ): void {
    connection.send({ type: 'error', id, code, message: text });
  }
}

function index(
  registry: Map<string, Set<RealtimeConnection>>,
  key: string,
  connection: RealtimeConnection,
): void {
  const existing = registry.get(key);
  if (existing) {
    existing.add(connection);
    return;
  }
  registry.set(key, new Set([connection]));
}

/** Отказ на этапе рукопожатия: обычный HTTP-ответ, без перехода в сокет. */
function reject(socket: Duplex, status: number, text: string): void {
  socket.write(`HTTP/1.1 ${status} ${text}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`);
  socket.destroy();
}

function readCookie(header: string | undefined, name: string): string | null {
  if (!header) {
    return null;
  }
  for (const part of header.split(';')) {
    const separator = part.indexOf('=');
    if (separator < 0) {
      continue;
    }
    if (part.slice(0, separator).trim() !== name) {
      continue;
    }
    const value = part.slice(separator + 1).trim();
    return value.length > 0 ? decodeURIComponent(value) : null;
  }
  return null;
}

/** Кадр клиента как текст. `RawData` бывает буфером, массивом буферов и ArrayBuffer. */
function frameText(raw: RawData): string {
  if (Array.isArray(raw)) {
    return Buffer.concat(raw).toString('utf8');
  }
  if (Buffer.isBuffer(raw)) {
    return raw.toString('utf8');
  }
  return Buffer.from(raw).toString('utf8');
}

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
