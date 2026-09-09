/**
 * Подстрочный поиск по свободному тексту (имя, email).
 *
 * Единственная тонкость, ради которой это отдельный файл: `%` и `_` — подстановочные
 * знаки `LIKE`. Пришедшие от пользователя, они превращают поиск «по подстроке»
 * в «по шаблону»: запрос `_` совпал бы со всеми. Экранируются вместе с самим символом
 * экранирования, а в SQL к оператору обязательно добавляется `escape '\'`.
 */

/** Обрезанная строка запроса или `undefined`, если искать нечего. */
export function normalizeSearchTerm(raw: string | undefined): string | undefined {
  const trimmed = raw?.trim();
  return trimmed ? trimmed : undefined;
}

/** Шаблон `%…%` для `ilike` с экранированием подстановочных знаков. */
export function containsPattern(term: string): string {
  return `%${term.replace(/[\\%_]/g, (char) => `\\${char}`)}%`;
}
