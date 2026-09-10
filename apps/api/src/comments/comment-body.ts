import type { InvalidFieldReason } from '../common/index.js';

/** Комментарий: Markdown до 10 000 символов, пустой отправить нельзя (US-71). */
export const COMMENT_BODY_MAX_LENGTH = 10000;

/**
 * Нормализация текста комментария.
 *
 * `null` означает «текста нет»: строка из одних пробелов и переводов строк —
 * это пустой комментарий, а не комментарий из пробелов (US-71). Обрезаются только
 * края: внутренние переводы строк — часть разметки Markdown (D-22).
 */
export function normalizeCommentBody(raw: string): string | null {
  const value = raw.trim();
  if (value.length === 0 || value.length > COMMENT_BODY_MAX_LENGTH) {
    return null;
  }
  return value;
}

/** Отказ по тексту комментария: пустой и слишком длинный — один и тот же отказ. */
export const INVALID_COMMENT_BODY: InvalidFieldReason = {
  code: 'invalid_comment_body',
  message: `Комментарий не может быть пустым и длиннее ${COMMENT_BODY_MAX_LENGTH} символов`,
};
