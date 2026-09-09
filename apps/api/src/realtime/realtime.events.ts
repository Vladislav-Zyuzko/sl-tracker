import { REDIS_KEY_PREFIX } from '../redis/index.js';

/**
 * Словарь живых обновлений: темы, типы событий и раскладка каналов Redis.
 *
 * Здесь нет ни сокетов, ни SQL — только формат. Он общий для того, кто публикует
 * (доменные репозитории), и для того, кто рассылает (gateway), поэтому живёт
 * отдельным файлом и проверяется unit-тестами.
 *
 * Протокол для клиента описан в `docs/api/websocket.md`. OpenAPI WebSocket
 * не описывает — этот документ и есть контракт.
 */

/** Адрес сокета. Тот же префикс `/api`, что и у HTTP: Caddy проксирует его целиком. */
export const REALTIME_PATH = '/api/ws';

/**
 * Что бывает темой подписки.
 *
 *  - `issue` — одна задача: комментарии, изменения полей, история (D-26);
 *  - `project` — состав участников проекта (US-21, US-16);
 *  - `user` — свои уведомления и счётчик непрочитанных (US-102, US-103).
 *
 * Списки задач темой **не являются**: D-26 распространяется на экран задачи
 * и на счётчик уведомлений, но не на списки.
 */
export const REALTIME_TOPIC_KINDS = ['issue', 'project', 'user'] as const;
export type RealtimeTopicKind = (typeof REALTIME_TOPIC_KINDS)[number];

/**
 * Тема внутри сервера: всегда по идентификатору, а не по ключу задачи или короткому
 * имени проекта. Ключ задачи регистронезависим, короткое имя проекта меняется (US-18) —
 * канал, привязанный к ним, разъехался бы.
 */
export interface RealtimeTopic {
  kind: RealtimeTopicKind;
  /** UUID задачи, проекта или пользователя. */
  id: string;
}

/**
 * Типы событий.
 *
 * Событие — это **сигнал**: «здесь что-то изменилось, и вот что именно». Полные
 * данные клиент забирает обычным запросом. Поля внутри `data` названы так же,
 * как в ответах REST (`key`, `id`, `type`, `unreadCount`, `role`, `userId`):
 * разошедшиеся формы одного и того же — вечный источник багов.
 */
export const REALTIME_EVENTS = [
  /** Изменились поля задачи и/или появились записи истории. `data.changedFields`. */
  'issue.updated',
  /** Задача удалена: открытый экран должен закрыться (US-44). */
  'issue.deleted',
  'comment.created',
  'comment.updated',
  'comment.deleted',
  /** В проект вступил новый участник (US-21, US-23). */
  'project.member_joined',
  /** Участнику сменили роль (US-15). */
  'project.member_updated',
  /** Участник исключён или вышел сам (US-16). */
  'project.member_removed',
  /** Появилось уведомление: строка в центре и рост счётчика (US-102 … US-104). */
  'notification.created',
  /** Уведомления прочитаны — счётчик изменился в другой вкладке или на другом устройстве. */
  'notification.read',
] as const;

export type RealtimeEventType = (typeof REALTIME_EVENTS)[number];

/** Событие, которое публикует доменный код. */
export interface RealtimeEvent {
  topic: RealtimeTopic;
  event: RealtimeEventType;
  /**
   * Проект, членство в котором даёт право получить событие. `null` — только для темы
   * `user`: своё уведомление человек получает независимо от проектов.
   *
   * Наличие этого поля — не удобство, а требование безопасности: право проверяется
   * не только при подписке, но и **при каждой рассылке**, иначе исключённый из проекта
   * продолжал бы слушать уже открытый сокет.
   */
  projectId: string | null;
  /** Кто вызвал событие. Клиент по нему отличает свои действия от чужих. */
  actorId: string | null;
  data: Record<string, unknown>;
}

/** То, что реально уходит в Redis: событие плюс момент публикации. */
export interface RealtimeEnvelope extends RealtimeEvent {
  /** ISO-8601. Клиенту нужен, чтобы отбросить событие, пришедшее после его же запроса. */
  at: string;
}

/** Раскладка каналов: `sl:rt:<тема>:<id>` и один служебный канал. */
export const REALTIME_CHANNEL_PREFIX = `${REDIS_KEY_PREFIX}:rt`;

export function realtimeChannel(topic: RealtimeTopic): string {
  return `${REALTIME_CHANNEL_PREFIX}:${topic.kind}:${topic.id}`;
}

export const issueTopic = (issueId: string): RealtimeTopic => ({ kind: 'issue', id: issueId });
export const projectTopic = (projectId: string): RealtimeTopic => ({
  kind: 'project',
  id: projectId,
});
export const userTopic = (userId: string): RealtimeTopic => ({ kind: 'user', id: userId });

/**
 * Служебный канал: на него подписан каждый экземпляр API, а не отдельное соединение.
 * Через него расходится то, что обязано действовать немедленно и на всех узлах, —
 * прежде всего отзыв доступа (ADR-0006, US-09).
 */
export const REALTIME_CONTROL_CHANNEL = `${REALTIME_CHANNEL_PREFIX}:control`;

export type RealtimeControlMessage =
  /** Доступ к трекеру отозван: все сокеты этого человека закрываются (US-09). */
  | { type: 'user_revoked'; userId: string }
  /** Человек вышел: закрывается ровно тот сокет, который открыт под этой сессией. */
  | { type: 'session_revoked'; sessionId: string };

export function encodeEnvelope(event: RealtimeEvent, at: Date = new Date()): string {
  const envelope: RealtimeEnvelope = { ...event, at: at.toISOString() };
  return JSON.stringify(envelope);
}

/**
 * Разбор того, что пришло из Redis. `null` на любой мусор: в канал мог попасть чужой
 * или устаревший формат, и падать из-за этого рассылка не должна.
 */
export function decodeEnvelope(raw: string): RealtimeEnvelope | null {
  const parsed = parseJson(raw);
  if (!parsed) {
    return null;
  }

  const topic = parsed.topic;
  if (!topic || typeof topic !== 'object' || Array.isArray(topic)) {
    return null;
  }

  const kind = (topic as Record<string, unknown>).kind;
  const id = (topic as Record<string, unknown>).id;
  const event = parsed.event;
  const at = parsed.at;
  const data = parsed.data;

  if (
    typeof kind !== 'string' ||
    !isTopicKind(kind) ||
    typeof id !== 'string' ||
    typeof event !== 'string' ||
    !isEventType(event) ||
    typeof at !== 'string' ||
    !data ||
    typeof data !== 'object' ||
    Array.isArray(data)
  ) {
    return null;
  }

  return {
    topic: { kind, id },
    event,
    projectId: typeof parsed.projectId === 'string' ? parsed.projectId : null,
    actorId: typeof parsed.actorId === 'string' ? parsed.actorId : null,
    data: data as Record<string, unknown>,
    at,
  };
}

function isTopicKind(value: string): value is RealtimeTopicKind {
  return (REALTIME_TOPIC_KINDS as readonly string[]).includes(value);
}

function isEventType(value: string): value is RealtimeEventType {
  return (REALTIME_EVENTS as readonly string[]).includes(value);
}

export function decodeControl(raw: string): RealtimeControlMessage | null {
  const parsed = parseJson(raw);
  if (!parsed) {
    return null;
  }

  if (parsed.type === 'user_revoked' && typeof parsed.userId === 'string') {
    return { type: 'user_revoked', userId: parsed.userId };
  }
  if (parsed.type === 'session_revoked' && typeof parsed.sessionId === 'string') {
    return { type: 'session_revoked', sessionId: parsed.sessionId };
  }
  return null;
}

function parseJson(raw: string): Record<string, unknown> | null {
  try {
    const value: unknown = JSON.parse(raw);
    return value && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}
