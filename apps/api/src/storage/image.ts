/**
 * Проверка загружаемого изображения.
 *
 * Тип определяется по сигнатуре файла, а не по заголовку `Content-Type` из запроса:
 * заголовок пишет клиент, и `image/png` на самом деле может быть чем угодно. То же
 * касается расширения в имени файла — оно вообще не участвует в решении.
 */

/** Обложка проекта: только эти три типа и не больше 5 МБ (US-12, D-21). */
export const COVER_ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/webp'] as const;
export const COVER_MAX_BYTES = 5 * 1024 * 1024;

export type ImageType = (typeof COVER_ALLOWED_TYPES)[number];

const EXTENSIONS: Readonly<Record<ImageType, string>> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/webp': 'webp',
};

export function extensionFor(type: ImageType): string {
  return EXTENSIONS[type];
}

/** `null` — это не PNG, не JPEG и не WEBP, каким бы ни был заявленный тип. */
export function detectImageType(buffer: Buffer): ImageType | null {
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(PNG_SIGNATURE)) {
    return 'image/png';
  }
  // JPEG: SOI-маркер в начале и EOI где-то дальше; промежуточные сегменты не разбираем.
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }
  // WEBP: контейнер RIFF, у которого четвёртое слово — `WEBP`.
  if (
    buffer.length >= 12 &&
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP'
  ) {
    return 'image/webp';
  }
  return null;
}

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
