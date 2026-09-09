import type { RealtimeEventType } from './realtime.events.js';

/**
 * Протокол между браузером и сокетом: разбор команд клиента и форма ответов.
 *
 * Чистые функции без сокетов и без БД — их проверяют unit-тесты. Человеческое
 * описание протокола: `docs/api/websocket.md`.
 */

/** Больше тем на одно соединение не нужно даже открытой задаче: экран слушает 2–3. */
export const MAX_TOPICS_PER_CONNECTION = 20;

/** Потолок размера кадра от клиента. Команда подписки — это сотни байт, не больше. */
export const MAX_CLIENT_FRAME_BYTES = 8 * 1024;

/** Период проверки живости соединения, секунды. */
export const HEARTBEAT_SECONDS = 30;

/**
 * Коды закрытия из диапазона приложения (4000–4999).
 *
 * Нарушение протокола соединение не закрывает: на кривой кадр уходит `error`,
 * и клиент продолжает работать. Слишком большой кадр обрывает сама библиотека
 * кодом 1009 — это уровень ниже нашего.
 */
export const CLOSE_CODES = {
  /** Сессии нет или она уже не действует: клиент должен уйти на вход. */
  unauthorized: 4401,
  /** Доступ к трекеру отозван или человек вышел (US-09). */
  revoked: 4403,
  /** Сервер выключается. Клиенту следует переподключиться. */
  shuttingDown: 4499,
} as const;

export type ClientCommand =
  | { type: 'subscribe'; id: string | null; topic: string }
  | { type: 'unsubscribe'; id: string | null; topic: string }
  | { type: 'ping'; id: string | null };

/** Машиночитаемые коды ошибок протокола. Тексты для человека подбирает клиент. */
export type RealtimeErrorCode =
  'invalid_message' | 'unknown_command' | 'invalid_topic' | 'topic_forbidden' | 'too_many_topics';

export interface ParsedCommand {
  command?: ClientCommand;
  error?: { code: RealtimeErrorCode; message: string; id: string | null };
}

/**
 * Разбор кадра от клиента.
 *
 * Ничего не бросает: неверный кадр — это обычное состояние публичного сокета,
 * и отвечать на него надо кадром `error`, а не падением обработчика.
 */
export function parseClientCommand(raw: string): ParsedCommand {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { error: { code: 'invalid_message', message: 'Ожидается JSON-объект', id: null } };
  }

  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return { error: { code: 'invalid_message', message: 'Ожидается JSON-объект', id: null } };
  }

  const message = parsed as Record<string, unknown>;
  // `id` — корреляция запроса и ответа: клиент сопоставляет ответ со своей командой,
  // не полагаясь на порядок кадров.
  const id = typeof message.id === 'string' && message.id.length <= 64 ? message.id : null;
  const type = message.type;

  if (type === 'ping') {
    return { command: { type: 'ping', id } };
  }

  if (type === 'subscribe' || type === 'unsubscribe') {
    const topic = message.topic;
    if (typeof topic !== 'string' || topic.length === 0 || topic.length > 128) {
      return { error: { code: 'invalid_topic', message: 'Тема не указана', id } };
    }
    return { command: { type, id, topic } };
  }

  return { error: { code: 'unknown_command', message: 'Неизвестная команда', id } };
}

/**
 * Своя тема, и только своя: чужой идентификатор в подписке не принимается вовсе,
 * иначе право «слушать чужие уведомления» пришлось бы отдельно запрещать.
 */
export const CANONICAL_USER_LABEL = 'user:me';

/** Тема так, как её называет клиент. */
export type TopicRequest =
  { kind: 'issue'; key: string } | { kind: 'project'; slug: string } | { kind: 'user' };

// Ярлык только разбирается на «вид темы» и «имя». Настоящая проверка — та же самая,
// что у REST: `IssueAccessService` и `ProjectAccessService`. Второй проверки прав
// в трекере быть не должно.
const ISSUE_TOPIC = /^issue:([A-Za-z][A-Za-z0-9]{1,9}-\d{1,10})$/;
const PROJECT_TOPIC = /^project:([a-z0-9][a-z0-9-]{0,79})$/;

export function parseTopicLabel(label: string): TopicRequest | null {
  if (label === CANONICAL_USER_LABEL) {
    return { kind: 'user' };
  }

  const issue = ISSUE_TOPIC.exec(label);
  if (issue) {
    // Ключ задачи регистронезависим (ADR-0004), но канонический вид — верхний регистр.
    return { kind: 'issue', key: issue[1]!.toUpperCase() };
  }

  const project = PROJECT_TOPIC.exec(label);
  if (project) {
    return { kind: 'project', slug: project[1]! };
  }

  return null;
}

/**
 * Канонический ярлык темы — тот, который сервер возвращает в подтверждении и ставит
 * в каждое событие. Клиент подписывается как ему удобно (`issue:sl-42`, старое короткое
 * имя проекта), а сравнивает уже канонический вид.
 */
export function canonicalIssueLabel(key: string): string {
  return `issue:${key}`;
}

export function canonicalProjectLabel(slug: string): string {
  return `project:${slug}`;
}

/** Кадры, которые отправляет сервер. */
export type ServerFrame =
  | {
      type: 'ready';
      /** Свои темы, на которые сервер подписал соединение сам. */
      topics: string[];
      heartbeatSeconds: number;
      maxTopics: number;
    }
  | { type: 'subscribed'; id: string | null; topic: string }
  | { type: 'unsubscribed'; id: string | null; topic: string }
  | { type: 'pong'; id: string | null }
  | { type: 'error'; id: string | null; code: RealtimeErrorCode; message: string }
  | {
      type: 'event';
      topic: string;
      event: RealtimeEventType;
      at: string;
      actorId: string | null;
      data: Record<string, unknown>;
    };
