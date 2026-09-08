/**
 * Правила полей задачи, вынесенные из сервиса, чтобы их можно было проверить
 * без базы и без HTTP (US-50, US-51, glossary.md, раздел 3).
 *
 * Те же ограничения продублированы `check`-ами в схеме БД. Дублирование намеренное:
 * проверка в коде даёт человеку внятное сообщение, проверка в базе не даёт записать
 * мусор в обход приложения — например, миграцией или чужим скриптом.
 */

export const ISSUE_TITLE_MAX_LENGTH = 255;
export const ISSUE_DESCRIPTION_MAX_LENGTH = 100_000;

/** 11 значений: 0, 10, …, 100. Больше — важнее. */
export const ISSUE_PRIORITY_STEP = 10;
export const ISSUE_PRIORITY_MIN = 0;
export const ISSUE_PRIORITY_MAX = 100;
/** Новая задача создаётся с приоритетом 50 — «обычная задача» (D-15). */
export const ISSUE_PRIORITY_DEFAULT = 50;

export const ISSUE_PRIORITY_VALUES: readonly number[] = [
  0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
];

/** Шкала Фибоначчи (D-16). «Не оценено» — это `null`, а не ноль и не пустая строка. */
export const ISSUE_STORY_POINTS_VALUES: readonly number[] = [1, 2, 3, 5, 8, 13];

/**
 * Приоритет **никогда не бывает пустым**: состояния «не задан» у поля нет, `null`
 * недопустим ни в API, ни в UI (D-15). Значение 0 — это «Низкий», а не «пусто».
 */
export function isValidPriority(value: unknown): value is number {
  return (
    typeof value === 'number' &&
    Number.isInteger(value) &&
    value >= ISSUE_PRIORITY_MIN &&
    value <= ISSUE_PRIORITY_MAX &&
    value % ISSUE_PRIORITY_STEP === 0
  );
}

/** `null` — допустимое значение: «не оценено» (US-51). */
export function isValidStoryPoints(value: unknown): value is number | null {
  if (value === null) {
    return true;
  }
  return typeof value === 'number' && ISSUE_STORY_POINTS_VALUES.includes(value);
}

/** Читаемое представление сложности для истории: «не оценено» вместо пустой строки (US-91). */
export function storyPointsLabel(value: number | null): string | null {
  return value === null ? null : String(value);
}

/**
 * Название: обрезаем пробелы по краям и требуем непустоту. Пустое название сохранить
 * нельзя — прежнее значение остаётся (US-42).
 */
export function normalizeTitle(raw: string): string | null {
  const value = raw.trim();
  if (value.length === 0 || value.length > ISSUE_TITLE_MAX_LENGTH) {
    return null;
  }
  return value;
}

/**
 * Описание хранится ровно так, как его написал человек: Markdown — это текст,
 * и любая «нормализация» разметки на сервере ломает то, что автор видел в редакторе.
 * Пустое описание — `null`, а не пустая строка: у поля одно состояние «пусто».
 *
 * Санитизация здесь **не делается сознательно** (D-22): содержимое рендерит клиент,
 * и он же отвечает за то, чтобы сырой HTML не исполнялся.
 */
export function normalizeDescription(raw: string | null | undefined): string | null {
  if (raw === null || raw === undefined) {
    return null;
  }
  return raw.trim().length > 0 ? raw : null;
}
