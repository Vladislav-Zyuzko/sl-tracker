import { renderMentionsAsText } from '../mentions/index.js';

/** Сколько текста попадает во вторую строку уведомления (US-102, US-104). */
export const NOTIFICATION_EXCERPT_MAX_LENGTH = 100;

/**
 * Начало текста для уведомления: первые ~100 символов комментария или описания.
 *
 * Что здесь делается и чего нет:
 *  - упоминания разворачиваются в `@Имя`: сырой токен `@[Имя](user:…)` в ленте
 *    уведомлений выглядел бы мусором;
 *  - переводы строк схлопываются в пробел — строка в ленте одна;
 *  - **разметка Markdown не снимается**: её убирает клиент при отрисовке
 *    (design/screens/notifications.md, «снять разметку»). Сервер не должен решать,
 *    как выглядит превью, и тем более рендерить Markdown ради ста символов.
 *
 * Снимок сохраняется в `payload` уведомления: текст комментария потом могут
 * поправить или удалить, а уже отправленное уведомление меняться не должно (US-102).
 */
export function notificationExcerpt(body: string): string {
  const flat = renderMentionsAsText(body).replace(/\s+/gu, ' ').trim();

  if (flat.length <= NOTIFICATION_EXCERPT_MAX_LENGTH) {
    return flat;
  }
  // Обрезаем по последнему пробелу, чтобы превью не заканчивалось половиной слова.
  const head = flat.slice(0, NOTIFICATION_EXCERPT_MAX_LENGTH);
  const lastSpace = head.lastIndexOf(' ');
  return `${(lastSpace > NOTIFICATION_EXCERPT_MAX_LENGTH / 2 ? head.slice(0, lastSpace) : head).trimEnd()}…`;
}
