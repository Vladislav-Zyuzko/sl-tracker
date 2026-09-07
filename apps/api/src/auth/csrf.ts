import { ForbiddenException } from '@nestjs/common';
import type { FastifyRequest } from 'fastify';

/**
 * Защита от подделки межсайтового запроса при cookie-сессии.
 *
 * `SameSite=Lax` закрывает основное — cookie не уйдёт с чужого сайта на POST. Но Lax
 * рассчитан на поведение браузера, а не на нашу проверку, поэтому небезопасные методы
 * дополнительно требуют совпадения `Origin` с адресом приложения. Фронт и API живут
 * на одном домене (ADR-0001), так что заголовок всегда на месте.
 *
 * К bearer-сессиям это не относится: заголовок `Authorization` браузер сам, без ведома
 * приложения, не отправит.
 */
export function assertSameOrigin(request: FastifyRequest, appOrigin: string): void {
  const origin = request.headers.origin;
  if (typeof origin !== 'string' || origin !== appOrigin) {
    throw new ForbiddenException({
      code: 'csrf_origin_mismatch',
      message: 'Запрос отклонён проверкой источника',
    });
  }
}

/** Методы, меняющие состояние. */
export const UNSAFE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);
