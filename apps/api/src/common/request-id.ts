import { randomUUID } from 'node:crypto';
import type { FastifyRequest } from 'fastify';

/**
 * Имя заголовка сквозного идентификатора запроса. Клиент читает именно это имя,
 * поэтому оно зафиксировано здесь, а не выводится из настроек Fastify.
 */
export const REQUEST_ID_HEADER = 'x-request-id';

/** Снаружи идентификатор принимается только в безопасном виде и ограниченной длины. */
const SAFE_REQUEST_ID = /^[A-Za-z0-9._:-]{1,128}$/;

/**
 * Идентификатор запроса: присланный клиентом или прокси, если он вменяемый, иначе новый.
 * Чужое значение не переносится в ответ без проверки — иначе в заголовок, в логи
 * и на экран пользователя уезжает произвольная строка из запроса.
 */
export function resolveRequestId(request: FastifyRequest): string {
  const incoming = request.headers[REQUEST_ID_HEADER];
  const value = Array.isArray(incoming) ? incoming[0] : incoming;
  return typeof value === 'string' && SAFE_REQUEST_ID.test(value) ? value : randomUUID();
}

declare module 'fastify' {
  interface FastifyRequest {
    /** Проставляется хуком в `configureApp`, читается логами и фильтром ошибок. */
    slRequestId?: string;
  }
}
