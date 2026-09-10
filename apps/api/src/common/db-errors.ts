/**
 * Разбор ошибок PostgreSQL до того, как они станут 500.
 *
 * Часть ошибок базы — не сбой сервера, а нормальный исход гонки: строку, на которую
 * ссылается вставка, удалили между проверкой и записью. Такое нарушение внешнего ключа
 * домен обязан превратить в осмысленный ответ (404), а не выпустить наружу текст драйвера.
 *
 * Смотреть приходится по цепочке `cause`: Drizzle оборачивает исходную ошибку в свою
 * («Failed query: insert into …»), и код `23503` лежит уже во вложенной.
 */

/** `foreign_key_violation`: ссылка на строку, которой нет. */
const FOREIGN_KEY_VIOLATION = '23503';

/** Глубже обёртки Drizzle искать нечего — предел на случай цикла в `cause`. */
const MAX_CAUSE_DEPTH = 5;

interface PgErrorLike {
  code: string | null;
  constraint: string | null;
}

/**
 * Нарушение внешнего ключа.
 *
 * `constraintSuffix` сужает проверку до конкретной связи: имена ограничений Drizzle
 * строит как `<таблица>_<колонка>_<цель>_fk`, поэтому по хвосту `_issue_id_issues_id_fk`
 * узнаётся именно «задачи больше нет» — в отличие от, например, исчезнувшего автора,
 * который 404 задачи не оправдывает.
 */
export function isForeignKeyViolation(error: unknown, constraintSuffix?: string): boolean {
  for (const link of causeChain(error)) {
    if (link.code !== FOREIGN_KEY_VIOLATION) {
      continue;
    }
    if (constraintSuffix === undefined) {
      return true;
    }
    if (link.constraint?.endsWith(constraintSuffix) === true) {
      return true;
    }
  }
  return false;
}

/** Сама ошибка и всё, что она обёртывает: у каждого звена берутся `code` и `constraint`. */
function* causeChain(error: unknown): Generator<PgErrorLike> {
  let current: unknown = error;
  for (let depth = 0; depth < MAX_CAUSE_DEPTH; depth += 1) {
    if (current === null || typeof current !== 'object') {
      return;
    }
    const candidate = current as { code?: unknown; constraint?: unknown; cause?: unknown };
    yield {
      code: typeof candidate.code === 'string' ? candidate.code : null,
      constraint: typeof candidate.constraint === 'string' ? candidate.constraint : null,
    };
    current = candidate.cause;
  }
}
