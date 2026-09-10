import { BadRequestException } from '@nestjs/common';
import { describe, expect, it } from '@jest/globals';
import { NoNullBytesPipe, containsNullByte } from './no-null-bytes.pipe.js';

const NUL = String.fromCharCode(0);

describe('Нулевой символ в запросе (DEF-03)', () => {
  const pipe = new NoNullBytesPipe();
  const transform = (value: unknown) => pipe.transform(value);

  it('отклоняет строку с нулевым символом машиночитаемым кодом', () => {
    expect(() => transform({ title: `до${NUL}после` })).toThrow(BadRequestException);

    const error = (() => {
      try {
        transform({ title: NUL });
        return null;
      } catch (caught) {
        return caught as BadRequestException;
      }
    })();

    expect(error?.getStatus()).toBe(400);
    expect(error?.getResponse()).toMatchObject({ code: 'invalid_characters' });
  });

  it('находит нулевой символ во вложенном объекте и в массиве', () => {
    expect(() => transform({ link: { title: `а${NUL}б` } })).toThrow(BadRequestException);
    expect(() => transform({ items: ['чисто', `гряз${NUL}но`] })).toThrow(BadRequestException);
  });

  it('обычный запрос пропускает как есть', () => {
    const body = { title: 'Обычная задача', priority: 50, assigneeId: null };
    expect(transform(body)).toBe(body);
  });

  it('прочие «страшные» символы пропускает: их база хранит (Н-4, D-22)', () => {
    const scary = {
      sql: "'; drop table issues; --",
      html: '<script>alert(1)</script>',
      emoji: 'готово 🎉',
      bidi: 'файл‮gnp.exe',
      zeroWidth: 'сли​тно',
      markdown: 'строка\nстрока\tтабом',
    };
    expect(transform(scary)).toBe(scary);
  });

  it('разобранная строка запроса приходит с прототипом null и тоже проверяется', () => {
    const query = Object.assign(Object.create(null) as object, { q: `до${NUL}после` });
    expect(containsNullByte(query)).toBe(true);
    expect(() => transform(query)).toThrow(BadRequestException);
  });

  it('содержимое файла не обходит: нулевой байт в бинарнике законен', () => {
    expect(containsNullByte(Buffer.from([0x50, 0x00, 0x4b]))).toBe(false);
    expect(containsNullByte(new Date())).toBe(false);
  });

  it('слишком глубокую вложенность не разбирает бесконечно', () => {
    let value: unknown = `дно${NUL}`;
    for (let depth = 0; depth < 20; depth += 1) {
      value = { nested: value };
    }
    expect(containsNullByte(value)).toBe(false);
  });
});
