/**
 * Короткое имя проекта в адресе (`/projects/<slug>`, ADR-0005, D-35).
 *
 * Правила здесь — чистые функции без БД: их проверяет unit-тест, и по ним же
 * фронтенд показывает предпросмотр адреса в форме создания. Окончательное значение
 * всегда выдаёт сервер: коллизию с уже занятым именем клиент увидеть не может.
 */

/** Длина ограничена 40 символами (D-35): адрес должен читаться, а не переноситься. */
export const SLUG_MAX_LENGTH = 40;

/** Разрешённый вид: строчные латинские буквы, цифры и одиночные дефисы внутри. */
export const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/**
 * Системные адреса приложения (ADR-0005, карта адресов). Проект с таким коротким
 * именем перекрыл бы собственный маршрут клиента, поэтому такие имена не выдаются
 * автоматически и не принимаются вручную.
 */
export const RESERVED_SLUGS: ReadonlySet<string> = new Set([
  'access-denied',
  'api',
  'invite',
  'issues',
  'login',
  'me',
  'notifications',
  'profile',
  'projects',
  'queues',
]);

/** База для имени, которое не удалось получить из названия (D-35: `project-7`). */
export const FALLBACK_SLUG_BASE = 'project';

/**
 * Таблица транслитерации кириллицы.
 *
 * Проверочный пример из D-35: «Сладкий Лимит 2026!» → `sladkiy-limit-2026`,
 * то есть `и` → `i`, `й` → `y`. Мягкий и твёрдый знаки пропадают, а не становятся
 * апострофом: апостроф в адресе не нужен.
 */
const CYRILLIC: Readonly<Record<string, string>> = {
  а: 'a',
  б: 'b',
  в: 'v',
  г: 'g',
  д: 'd',
  е: 'e',
  ё: 'e',
  ж: 'zh',
  з: 'z',
  и: 'i',
  й: 'y',
  к: 'k',
  л: 'l',
  м: 'm',
  н: 'n',
  о: 'o',
  п: 'p',
  р: 'r',
  с: 's',
  т: 't',
  у: 'u',
  ф: 'f',
  х: 'h',
  ц: 'ts',
  ч: 'ch',
  ш: 'sh',
  щ: 'sch',
  ъ: '',
  ы: 'y',
  ь: '',
  э: 'e',
  ю: 'yu',
  я: 'ya',
};

/** Кириллица латиницей, посимвольно. Остальные буквы проходят как есть. */
export function transliterate(value: string): string {
  let result = '';
  for (const char of value.toLowerCase()) {
    result += CYRILLIC[char] ?? char;
  }
  return result;
}

/**
 * Короткое имя из названия проекта: транслитерация, нижний регистр, всё недопустимое —
 * в дефис, повторные дефисы схлопываются, крайние обрезаются, длина до 40.
 *
 * Пустая строка означает «из названия не вышло ни одного допустимого символа»
 * (название из эмодзи или знаков) — вызывающий код берёт запасную базу.
 */
export function slugify(name: string): string {
  // Сначала NFC, и только потом транслитерация: в NFKD «й» распадается на «и»
  // и комбинирующий знак, и из «Сладкий» вышло бы `sladkii`. Разложение и снятие
  // диакритики применяется уже к латинице — ради «é» → «e».
  const latin = transliterate(name.normalize('NFC')).normalize('NFKD').replace(/[̀-ͯ]/g, '');

  const cleaned = latin
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

  return trimToLength(cleaned, SLUG_MAX_LENGTH);
}

/** База для перебора кандидатов: из названия или запасная, если название не дало ничего. */
export function slugBase(name: string): string {
  const generated = slugify(name);
  return generated.length > 0 ? generated : FALLBACK_SLUG_BASE;
}

/**
 * Кандидат номер `attempt` (нумерация с 1): `sweet-limit`, `sweet-limit-2`, …
 *
 * Суффикс добавляется и на первой попытке, если сама база зарезервирована приложением:
 * `projects` занято маршрутом, но `projects-2` — обычное имя, и отказывать
 * пользователю в создании проекта из-за названия «Проекты» не за что.
 */
export function slugCandidate(base: string, attempt: number): string {
  const normalized = base.length > 0 ? base : FALLBACK_SLUG_BASE;
  if (attempt <= 1 && !RESERVED_SLUGS.has(normalized)) {
    return normalized;
  }

  const suffix = `-${attempt <= 1 ? 2 : attempt}`;
  return `${trimToLength(normalized, SLUG_MAX_LENGTH - suffix.length)}${suffix}`;
}

export type SlugValidationError = 'invalid_slug' | 'reserved_slug';

/**
 * Проверка имени, введённого администратором вручную (US-18).
 *
 * Ввод не «чинится» молча: `Сладкий Лимит` и `sladkiy--limit` отклоняются с кодом,
 * а привести ввод к допустимому виду по мере набора — работа клиента, у которого
 * для этого есть `slugify` с теми же правилами.
 */
export function validateSlug(raw: string): SlugValidationError | null {
  const value = raw.trim();
  if (value.length === 0 || value.length > SLUG_MAX_LENGTH || !SLUG_PATTERN.test(value)) {
    return 'invalid_slug';
  }
  if (RESERVED_SLUGS.has(value)) {
    return 'reserved_slug';
  }
  return null;
}

/** Обрезка по длине без висящего дефиса на конце. */
function trimToLength(value: string, max: number): string {
  if (value.length <= max) {
    return value;
  }
  return value.slice(0, Math.max(1, max)).replace(/-+$/g, '');
}
