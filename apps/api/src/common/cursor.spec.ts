import { describe, expect, it } from '@jest/globals';
import { clampLimit, decodeCursor, encodeCursor } from './cursor.js';

describe('Курсорная пагинация', () => {
  it('курсор переживает кодирование и разбор', () => {
    const cursor = encodeCursor(['8f3a', 'Сладкий лимит']);
    expect(decodeCursor(cursor, 2)).toEqual(['8f3a', 'Сладкий лимит']);
  });

  it('разделитель внутри значения курсор не ломает: свободный текст идёт последним', () => {
    const cursor = encodeCursor(['id-1', 'Проект | важный | очень']);
    expect(decodeCursor(cursor, 2)).toEqual(['id-1', 'Проект | важный | очень']);
  });

  it.each([
    ['мусор вместо base64', '!!!not-a-cursor!!!'],
    ['частей меньше, чем ждём', encodeCursor(['одна'])],
    ['пустая часть', encodeCursor(['', 'вторая'])],
  ])('не разбирает %s', (_case, raw) => {
    expect(decodeCursor(raw, 2)).toBeNull();
  });

  describe('clampLimit', () => {
    it('без значения берёт умолчание', () => {
      expect(clampLimit(undefined, 50, 100)).toBe(50);
    });

    it('обрезает сверху жёстким максимумом', () => {
      expect(clampLimit(1000, 50, 100)).toBe(100);
    });

    it('не опускается ниже единицы', () => {
      expect(clampLimit(0, 50, 100)).toBe(1);
      expect(clampLimit(-5, 50, 100)).toBe(1);
    });

    it('дробное значение усекается', () => {
      expect(clampLimit(10.9, 50, 100)).toBe(10);
    });
  });
});
