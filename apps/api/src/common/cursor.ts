/**
 * Курсорная пагинация, общая для всех списков.
 *
 * Курсор — это значения полей сортировки последней отданной строки, а не смещение:
 * OFFSET на списке, который параллельно пополняется, пропускает и дублирует строки.
 * Наружу отдаётся base64url, чтобы клиент не пытался его разбирать и не начинал
 * зависеть от внутреннего порядка полей.
 */

const SEPARATOR = '|';

export function encodeCursor(parts: readonly string[]): string {
  return Buffer.from(parts.join(SEPARATOR), 'utf8').toString('base64url');
}

/**
 * `null` — курсор испорчен или пришёл не от нас. Вызывающий код отвечает 400
 * с кодом `invalid_cursor`, а не пытается угадать намерение клиента.
 *
 * Последняя часть забирает остаток строки целиком, поэтому разделитель внутри
 * значения курсор не ломает. Отсюда правило для вызывающего кода: свободный текст
 * (название проекта, имя человека) кладётся в курсор **последним**.
 */
export function decodeCursor(raw: string, expectedParts: number): string[] | null {
  try {
    const decoded = Buffer.from(raw, 'base64url').toString('utf8');
    const parts: string[] = [];
    let rest = decoded;

    for (let index = 0; index < expectedParts - 1; index += 1) {
      const separator = rest.indexOf(SEPARATOR);
      if (separator < 0) {
        return null;
      }
      parts.push(rest.slice(0, separator));
      rest = rest.slice(separator + SEPARATOR.length);
    }
    parts.push(rest);

    return parts.some((part) => part.length === 0) ? null : parts;
  } catch {
    return null;
  }
}

/** Жёсткий потолок страницы: клиент не может попросить «всё сразу». */
export function clampLimit(raw: number | undefined, fallback: number, max: number): number {
  if (raw === undefined || !Number.isFinite(raw)) {
    return fallback;
  }
  return Math.min(Math.max(Math.trunc(raw), 1), max);
}
