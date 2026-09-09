import { describe, expect, it } from '@jest/globals';
import { containsPattern, normalizeSearchTerm } from './search.js';

describe('normalizeSearchTerm', () => {
  it('пустая строка и пробелы равны отсутствию запроса', () => {
    expect(normalizeSearchTerm(undefined)).toBeUndefined();
    expect(normalizeSearchTerm('')).toBeUndefined();
    expect(normalizeSearchTerm('   ')).toBeUndefined();
  });

  it('обрезает края, середину не трогает', () => {
    expect(normalizeSearchTerm('  анна ив ')).toBe('анна ив');
  });
});

describe('containsPattern', () => {
  it('оборачивает запрос в подстрочный шаблон', () => {
    expect(containsPattern('анна')).toBe('%анна%');
  });

  it('обезвреживает подстановочные знаки LIKE', () => {
    // Без экранирования запрос `_` совпал бы с любым участником, а `%` — со всеми.
    expect(containsPattern('_')).toBe('%\\_%');
    expect(containsPattern('100%')).toBe('%100\\%%');
    expect(containsPattern('a_b%c')).toBe('%a\\_b\\%c%');
  });

  it('экранирует сам символ экранирования', () => {
    expect(containsPattern('a\\b')).toBe('%a\\\\b%');
  });
});
