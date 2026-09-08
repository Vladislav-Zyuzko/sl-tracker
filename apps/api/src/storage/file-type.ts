/**
 * Определение типа загруженного файла по его содержимому.
 *
 * Тип берётся из сигнатуры файла, а не из заголовка `Content-Type` и не из расширения
 * в имени: и то и другое пишет клиент. Для вложений это не запрет (тип файла
 * не ограничен, D-21), а честный ответ на вопрос «что это на самом деле»: от него
 * зависит и превью в интерфейсе, и то, с каким типом файл уедет в хранилище.
 *
 * Неопознанное содержимое — не ошибка: такой файл сохраняется как
 * `application/octet-stream` и показывается строкой в списке (US-46).
 */

/** Вложение к задаче: любой тип, до 25 МБ (D-21). */
export const ATTACHMENT_MAX_BYTES = 25 * 1024 * 1024;

/** Максимальная длина имени файла, которое мы храним и показываем. */
export const ATTACHMENT_FILE_NAME_MAX_LENGTH = 255;

export const FALLBACK_CONTENT_TYPE = 'application/octet-stream';
export const FALLBACK_EXTENSION = 'bin';

/** Эти типы показываются превью прямо в задаче (US-46, D-21). */
export const PREVIEWABLE_IMAGE_TYPES = [
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
] as const;

export interface DetectedFileType {
  contentType: string;
  extension: string;
}

interface Signature {
  contentType: string;
  extension: string;
  /** Смещение, с которого сравниваются байты. */
  offset: number;
  bytes: readonly number[];
  /** Дополнительная проверка: контейнеры RIFF и ISO-BMFF различаются не первыми байтами. */
  also?: { offset: number; ascii: string };
}

const b = (ascii: string): number[] => [...Buffer.from(ascii, 'ascii')];

/**
 * Порядок важен: более специфичные сигнатуры идут раньше общих контейнеров.
 * Список намеренно короткий — он покрывает то, что реально таскают в трекер
 * (скриншоты, документы, архивы, логи), а не всё существующее.
 */
const SIGNATURES: readonly Signature[] = [
  { contentType: 'image/png', extension: 'png', offset: 0, bytes: [0x89, 0x50, 0x4e, 0x47] },
  { contentType: 'image/jpeg', extension: 'jpg', offset: 0, bytes: [0xff, 0xd8, 0xff] },
  { contentType: 'image/gif', extension: 'gif', offset: 0, bytes: b('GIF8') },
  {
    contentType: 'image/webp',
    extension: 'webp',
    offset: 0,
    bytes: b('RIFF'),
    also: { offset: 8, ascii: 'WEBP' },
  },
  { contentType: 'image/bmp', extension: 'bmp', offset: 0, bytes: b('BM') },
  { contentType: 'application/pdf', extension: 'pdf', offset: 0, bytes: b('%PDF-') },
  // OOXML и ODF — те же ZIP: различать их по содержимому архива дороже, чем это стоит.
  { contentType: 'application/zip', extension: 'zip', offset: 0, bytes: [0x50, 0x4b, 0x03, 0x04] },
  { contentType: 'application/gzip', extension: 'gz', offset: 0, bytes: [0x1f, 0x8b] },
  {
    contentType: 'application/x-7z-compressed',
    extension: '7z',
    offset: 0,
    bytes: [0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c],
  },
  { contentType: 'application/x-rar-compressed', extension: 'rar', offset: 0, bytes: b('Rar!') },
  {
    contentType: 'video/mp4',
    extension: 'mp4',
    offset: 4,
    bytes: b('ftyp'),
  },
  { contentType: 'audio/mpeg', extension: 'mp3', offset: 0, bytes: [0x49, 0x44, 0x33] },
];

/**
 * Что это за файл. Пустой буфер сюда не приходит: пустое вложение отклоняется раньше.
 *
 * Текст (логи, `.csv`, `.json`) сигнатуры не имеет, поэтому определяется отдельно —
 * по отсутствию управляющих байтов в начале. Иначе каждый лог уезжал бы в хранилище
 * как `application/octet-stream` и скачивался бы вместо просмотра.
 */
export function detectFileType(buffer: Buffer): DetectedFileType {
  for (const signature of SIGNATURES) {
    if (matches(buffer, signature)) {
      return { contentType: signature.contentType, extension: signature.extension };
    }
  }

  if (looksLikeUtf8Text(buffer)) {
    return { contentType: 'text/plain; charset=utf-8', extension: 'txt' };
  }

  return { contentType: FALLBACK_CONTENT_TYPE, extension: FALLBACK_EXTENSION };
}

/** Показывать ли вложение картинкой в задаче (US-46). */
export function isPreviewableImage(contentType: string): boolean {
  return (PREVIEWABLE_IMAGE_TYPES as readonly string[]).includes(contentType);
}

/**
 * Имя файла для показа и скачивания. Путь из него вырезается: имя приходит из браузера
 * пользователя, и `../../etc/passwd` в нём — обычное дело. В путь объекта оно не попадает
 * никогда (его строит сервер), но и в заголовок `Content-Disposition` мусор пускать незачем.
 */
export function safeFileName(raw: string | undefined | null): string {
  const base = (raw ?? '').split(/[/\\]/).pop() ?? '';
  const cleaned = [...base]
    // Управляющие символы, кавычки и обратные слэши ломают заголовок ответа.
    // Фильтром, а не регулярным выражением: диапазон управляющих символов в regexp
    // линтер справедливо считает подозрительным, а читаемости он здесь не добавляет.
    .filter((char) => {
      const code = char.codePointAt(0) ?? 0;
      return code > 0x1f && code !== 0x7f && char !== '"' && char !== '\\';
    })
    .join('')
    .trim();

  if (cleaned.length === 0) {
    return 'file';
  }
  return cleaned.length > ATTACHMENT_FILE_NAME_MAX_LENGTH
    ? cleaned.slice(0, ATTACHMENT_FILE_NAME_MAX_LENGTH)
    : cleaned;
}

function matches(buffer: Buffer, signature: Signature): boolean {
  const end = signature.offset + signature.bytes.length;
  if (buffer.length < end) {
    return false;
  }
  for (let index = 0; index < signature.bytes.length; index += 1) {
    if (buffer[signature.offset + index] !== signature.bytes[index]) {
      return false;
    }
  }
  if (signature.also) {
    const { offset, ascii } = signature.also;
    if (buffer.length < offset + ascii.length) {
      return false;
    }
    return buffer.subarray(offset, offset + ascii.length).toString('ascii') === ascii;
  }
  return true;
}

/**
 * Похоже ли начало файла на текст в UTF-8. Проверяется первый килобайт: этого
 * достаточно, чтобы отличить лог от бинарника, и не требует читать файл целиком.
 */
function looksLikeUtf8Text(buffer: Buffer): boolean {
  const head = trimToCharBoundary(buffer.subarray(0, Math.min(buffer.length, 1024)));
  if (head.length === 0) {
    return false;
  }

  for (const byte of head) {
    // Управляющие символы, кроме табуляции, перевода строки и возврата каретки.
    if (byte < 0x09 || (byte > 0x0d && byte < 0x20)) {
      return false;
    }
  }

  // Некорректная последовательность UTF-8 означает, что это не текст, а данные,
  // случайно не содержащие управляющих байтов в начале.
  return Buffer.compare(Buffer.from(head.toString('utf8'), 'utf8'), head) === 0;
}

/**
 * Отрезает от куска хвост незавершённой последовательности UTF-8: иначе текстовый файл
 * длиннее килобайта не проходил бы проверку только потому, что мы разрезали его
 * посередине буквы «ё».
 */
function trimToCharBoundary(head: Buffer): Buffer {
  for (let back = 0; back < 4 && back < head.length; back += 1) {
    const byte = head[head.length - 1 - back]!;
    // ASCII или конец завершённой последовательности — резать нечего.
    if (byte < 0x80) {
      return back === 0 ? head : head.subarray(0, head.length - back);
    }
    // Ведущий байт: последовательность начинается здесь и в кусок целиком не влезла.
    if (byte >= 0xc0) {
      return head.subarray(0, head.length - back - 1);
    }
  }
  return head;
}
