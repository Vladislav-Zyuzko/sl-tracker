/**
 * Работа с email как с идентификатором списка доступа.
 *
 * Сравнение и хранение — в нижнем регистре: `Ivan@Yandex.ru` и `ivan@yandex.ru` —
 * один адрес (ADR-0006, п. 1). Регулярное выражение намеренно простое: полная проверка
 * по RFC 5322 никому не нужна, а расхождение с проверкой на клиенте вредно —
 * фронтенду в спеке экрана прямо сказано согласовать выражение с бэкендом.
 */
const EMAIL_PATTERN = /^[^\s@,;<>"]+@[^\s@,;<>".]+(\.[^\s@,;<>".]+)+$/;

/** Ограничение колонки `varchar(320)` — предельная длина адреса. */
export const EMAIL_MAX_LENGTH = 320;

/** Приводит адрес к хранимому виду. Не проверяет формат. */
export function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

export function isValidEmail(value: string): boolean {
  return value.length > 0 && value.length <= EMAIL_MAX_LENGTH && EMAIL_PATTERN.test(value);
}

/** Нормализует и проверяет за один шаг. `null` — адрес не годится. */
export function toStorableEmail(raw: string): string | null {
  const normalized = normalizeEmail(raw);
  return isValidEmail(normalized) ? normalized : null;
}
