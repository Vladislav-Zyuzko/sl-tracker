/**
 * Разбор упоминаний в тексте комментария и описания задачи (US-74).
 *
 * **Упоминание хранится ссылкой на пользователя, а не именем.** В тексте оно
 * записано токеном `@[Имя](user:<uuid>)`:
 *  - идентификатор — то, по чему создаётся связь и уведомление. Имя в токене
 *    участвует только в запасном отображении;
 *  - актуальное имя клиент берёт из списка `mentions` в ответе API, поэтому смена
 *    имени в Яндекс ID видна во всех старых комментариях (US-74);
 *  - если человек больше не участник проекта, связи в ответе не будет, и клиент
 *    покажет имя из токена **обычным текстом** — как и требует US-74.
 *
 * Всё, что не совпало с токеном (в том числе набранное вручную `@ivan`), остаётся
 * обычным текстом: ни подсветки, ни связи, ни уведомления (D-41).
 */

/** Токен упоминания. Имя — до 120 символов и без `]`, чтобы разбор был однозначным. */
const MENTION_TOKEN =
  /@\[([^\]\r\n]{1,120})\]\(user:([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\)/gu;

export interface ParsedMention {
  userId: string;
  /** Имя на момент написания — запасной вариант отображения, не источник правды. */
  displayName: string;
}

/**
 * Все упоминания текста, каждый пользователь — один раз (US-74: повторное упоминание
 * того же человека в одном комментарии создаёт одно уведомление).
 */
export function parseMentions(body: string): ParsedMention[] {
  const seen = new Map<string, ParsedMention>();

  for (const match of body.matchAll(MENTION_TOKEN)) {
    const userId = match[2]!.toLowerCase();
    if (!seen.has(userId)) {
      seen.set(userId, { userId, displayName: match[1]!.trim() });
    }
  }

  return [...seen.values()];
}

/** Текст без токенов: `@[Анна](user:…)` → `@Анна`. Нужен превью уведомления и поиску. */
export function renderMentionsAsText(body: string): string {
  return body.replace(MENTION_TOKEN, (_match, name: string) => `@${name.trim()}`);
}

/** Собрать токен — нужен тестам и клиентским примерам в документации. */
export function mentionToken(userId: string, displayName: string): string {
  return `@[${displayName}](user:${userId})`;
}
