import { BadRequestException, Injectable, type PipeTransform } from '@nestjs/common';

/**
 * Нулевой символ `U+0000` — единственный символ, который PostgreSQL не хранит
 * в `text` ни при каких условиях: драйвер отвечает ошибкой на любую строку с ним.
 * Из буфера обмена он попадает в поле легко и незаметно.
 */
const NUL = String.fromCharCode(0);

/** Тела запросов у нас неглубокие; предел нужен на случай подсунутой вложенности. */
const MAX_DEPTH = 8;

/**
 * Отказ на нулевой символ в любом текстовом поле запроса.
 *
 * Стоит **до** проверки DTO и общим фильтром на все аргументы обработчика (тело,
 * строка запроса, параметры пути), а не в нормализации каждого поля: иначе то же
 * самое пришлось бы вспоминать в каждом новом поле, а забытое поле снова роняло бы
 * запрос в 500.
 *
 * Прочие «страшные» символы — символы нулевой ширины, управляющие BiDi, эмодзи —
 * пропускаются намеренно (D-22, наблюдение Н-4 в реестре дефектов): база их хранит,
 * а обезвреживание при показе — дело клиента.
 */
@Injectable()
export class NoNullBytesPipe implements PipeTransform {
  transform(value: unknown): unknown {
    if (containsNullByte(value)) {
      throw new BadRequestException({
        code: 'invalid_characters',
        message: 'Текст содержит недопустимый символ',
      });
    }
    return value;
  }
}

/**
 * Есть ли нулевой символ где-нибудь внутри значения.
 *
 * Обходятся строки, массивы и объекты — в том числе с прототипом `null`: разобранная
 * строка запроса приходит именно таким, и проверка «только простой объект» пропустила бы
 * её мимо. Не обходятся двоичные значения (`Buffer`, типизированные массивы), `Date`
 * и потоки: содержимое файла — это байты, а не текст, и нулевой байт в нём законен.
 */
export function containsNullByte(value: unknown, depth = 0): boolean {
  if (typeof value === 'string') {
    return value.includes(NUL);
  }
  if (value === null || typeof value !== 'object' || depth >= MAX_DEPTH) {
    return false;
  }
  if (Array.isArray(value)) {
    return value.some((item) => containsNullByte(item, depth + 1));
  }
  if (isBinaryOrStream(value)) {
    return false;
  }
  return Object.values(value).some((item) => containsNullByte(item, depth + 1));
}

/** Значения, внутри которых текста нет и искать нечего. */
function isBinaryOrStream(value: object): boolean {
  return (
    Buffer.isBuffer(value) ||
    ArrayBuffer.isView(value) ||
    value instanceof ArrayBuffer ||
    value instanceof Date ||
    typeof (value as { pipe?: unknown }).pipe === 'function'
  );
}
