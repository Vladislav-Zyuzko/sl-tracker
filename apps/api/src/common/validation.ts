// Метаданные полей читаются и пишутся через Reflect: полифилл должен быть загружен
// и в боевом запуске (main.ts), и в unit-тесте этого файла.
import 'reflect-metadata';
import { BadRequestException, type ValidationError } from '@nestjs/common';

/**
 * Приведение отказов проверки DTO к общему виду ошибки.
 *
 * Стандартный формат NestJS (`{ message: ["title must be shorter …"], error: "Bad Request" }`)
 * наружу уходить не должен по двум причинам: в нём нет машиночитаемого кода, по которому
 * клиент выбирает текст для человека, и сам текст — английская фраза из библиотеки
 * проверки, а интерфейс у нас только русский (D-36).
 *
 * Итог: у **всех** ошибок 400 одна форма `{ code, message }` — и у пришедших из домена,
 * и у пришедших из DTO. Код берётся с поля (`@InvalidField`), а если поле его не объявило —
 * общий `invalid_request` с указанием, какое поле не понравилось.
 */

/** Ключ метаданных с кодом отказа. Хранится на классе DTO, а не на его экземпляре. */
const INVALID_FIELD = Symbol('sl:invalid-field');

/** Код и текст, которыми отвечает отказ по этому полю. */
export interface InvalidFieldReason {
  code: string;
  message: string;
}

/** Отказ, у которого своего кода на поле не нашлось. */
export const INVALID_REQUEST_CODE = 'invalid_request';

/**
 * Код и текст отказа для поля DTO.
 *
 * Ставится рядом с ограничениями поля, чтобы «слишком длинное название» и «пустое
 * название» отвечали одним кодом: для клиента это один и тот же отказ, и разделение
 * по тому, кто его заметил — проверка DTO или доменный код, — ему ничего не даёт.
 *
 * Текст берётся тот же, что у доменного отказа с этим кодом: два разных текста на один
 * код — это тот же разнобой, только менее заметный.
 */
export function InvalidField(reason: InvalidFieldReason): PropertyDecorator {
  return (target, property) => {
    const owner = target.constructor;
    const reasons = ownReasons(owner);
    reasons.set(String(property), reason);
    Reflect.defineMetadata(INVALID_FIELD, reasons, owner);
  };
}

/** Причина отказа, объявленная полем; наследование DTO учитывается. */
export function invalidFieldReason(
  target: object | undefined,
  property: string,
): InvalidFieldReason | undefined {
  const owner = target?.constructor;
  if (typeof owner !== 'function') {
    return undefined;
  }
  const reasons = Reflect.getMetadata(INVALID_FIELD, owner) as
    Map<string, InvalidFieldReason> | undefined;
  return reasons?.get(property);
}

/**
 * `exceptionFactory` глобального `ValidationPipe`.
 *
 * Отдаётся **первый** отказ, а не все сразу: форма ответа у ошибок трекера — один код
 * и один текст, и склеивать в неё список поломанных полей значило бы завести третий
 * формат вместо двух. Поля перебираются в порядке объявления в DTO, то есть ответ
 * устойчив и не зависит от порядка обхода.
 */
export function validationExceptionFactory(errors: ValidationError[]): BadRequestException {
  const leaf = firstLeaf(errors);
  if (!leaf) {
    return new BadRequestException({
      code: INVALID_REQUEST_CODE,
      message: 'Запрос содержит недопустимые данные',
    });
  }

  const declared = invalidFieldReason(leaf.error.target, leaf.error.property);
  if (declared) {
    return new BadRequestException(declared);
  }

  return new BadRequestException({
    code: INVALID_REQUEST_CODE,
    // Имя поля — то же, что в контракте: клиент показывает текст по коду, а разработчику
    // нужно понимать, какое поле не прошло. Английская фраза библиотеки не пересказывается.
    message: `Поле «${leaf.path}» заполнено неверно`,
  });
}

/** Первый отказ с ограничениями: вложенные объекты разворачиваются до листа. */
function firstLeaf(
  errors: ValidationError[],
  prefix = '',
  depth = 0,
): { error: ValidationError; path: string } | null {
  if (depth > 5) {
    return null;
  }

  for (const error of errors) {
    const path = prefix ? `${prefix}.${error.property}` : error.property;
    if (error.constraints && Object.keys(error.constraints).length > 0) {
      return { error, path };
    }
    const nested = error.children ? firstLeaf(error.children, path, depth + 1) : null;
    if (nested) {
      return nested;
    }
  }
  return null;
}

/**
 * Таблица причин самого класса. У наследника (`UpdateCommentDto extends CreateCommentDto`)
 * она своя, но начинается с копии родительской: `Reflect.defineMetadata` пишет на класс,
 * и без копии первое же объявление поля в наследнике скрыло бы родительские.
 */
function ownReasons(owner: object): Map<string, InvalidFieldReason> {
  const own = Reflect.getOwnMetadata(INVALID_FIELD, owner) as
    Map<string, InvalidFieldReason> | undefined;
  if (own) {
    return own;
  }
  const inherited = Reflect.getMetadata(INVALID_FIELD, owner) as
    Map<string, InvalidFieldReason> | undefined;
  return new Map(inherited ?? []);
}
