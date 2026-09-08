import { describe, expect, it } from '@jest/globals';
import {
  ISSUE_PRIORITY_DEFAULT,
  ISSUE_PRIORITY_VALUES,
  ISSUE_TITLE_MAX_LENGTH,
  isValidPriority,
  isValidStoryPoints,
  normalizeDescription,
  normalizeTitle,
  storyPointsLabel,
} from './issue-fields.js';

describe('Приоритет задачи (US-50, D-15)', () => {
  it('принимает ровно 11 значений от 0 до 100 с шагом 10', () => {
    expect(ISSUE_PRIORITY_VALUES).toHaveLength(11);
    for (const value of ISSUE_PRIORITY_VALUES) {
      expect(isValidPriority(value)).toBe(true);
    }
  });

  it('отклоняет промежуточные значения', () => {
    expect(isValidPriority(55)).toBe(false);
    expect(isValidPriority(1)).toBe(false);
    expect(isValidPriority(99)).toBe(false);
  });

  it('отклоняет значения за границами шкалы', () => {
    expect(isValidPriority(-10)).toBe(false);
    expect(isValidPriority(110)).toBe(false);
  });

  it('ноль — это «Низкий», а не «пусто»: значение допустимо', () => {
    expect(isValidPriority(0)).toBe(true);
  });

  it('пустого приоритета не существует: null и undefined недопустимы', () => {
    expect(isValidPriority(null)).toBe(false);
    expect(isValidPriority(undefined)).toBe(false);
  });

  it('дробное значение не проходит', () => {
    expect(isValidPriority(50.5)).toBe(false);
  });

  it('умолчание — середина шкалы', () => {
    expect(ISSUE_PRIORITY_DEFAULT).toBe(50);
    expect(isValidPriority(ISSUE_PRIORITY_DEFAULT)).toBe(true);
  });
});

describe('Сложность задачи (US-51, D-16)', () => {
  it('принимает шкалу Фибоначчи', () => {
    for (const value of [1, 2, 3, 5, 8, 13]) {
      expect(isValidStoryPoints(value)).toBe(true);
    }
  });

  it('принимает «не оценено» как null', () => {
    expect(isValidStoryPoints(null)).toBe(true);
  });

  it('отклоняет значения вне шкалы', () => {
    for (const value of [0, 4, 6, 7, 21, -1]) {
      expect(isValidStoryPoints(value)).toBe(false);
    }
  });

  it('«не оценено» показывается отсутствием значения, а не пустой строкой', () => {
    expect(storyPointsLabel(null)).toBeNull();
    expect(storyPointsLabel(8)).toBe('8');
  });
});

describe('Название задачи (US-42)', () => {
  it('обрезает пробелы по краям', () => {
    expect(normalizeTitle('  Починить экспорт  ')).toBe('Починить экспорт');
  });

  it('пустое название сохранить нельзя', () => {
    expect(normalizeTitle('')).toBeNull();
    expect(normalizeTitle('   ')).toBeNull();
  });

  it('длина ограничена 255 символами', () => {
    expect(normalizeTitle('a'.repeat(ISSUE_TITLE_MAX_LENGTH))).toHaveLength(ISSUE_TITLE_MAX_LENGTH);
    expect(normalizeTitle('a'.repeat(ISSUE_TITLE_MAX_LENGTH + 1))).toBeNull();
  });
});

describe('Описание задачи (US-43, D-22)', () => {
  it('пустое описание — это null, а не пустая строка', () => {
    expect(normalizeDescription('')).toBeNull();
    expect(normalizeDescription('   \n  ')).toBeNull();
    expect(normalizeDescription(null)).toBeNull();
    expect(normalizeDescription(undefined)).toBeNull();
  });

  it('markdown сохраняется дословно, включая ведущие пробелы и переносы', () => {
    const markdown = '# Заголовок\n\n- пункт\n- пункт\n\n```js\nconst a = 1;\n```\n';
    expect(normalizeDescription(markdown)).toBe(markdown);
  });

  it('сервер ничего не вырезает: санитизация — обязанность клиента при рендере', () => {
    const raw = '<script>alert(1)</script>';
    expect(normalizeDescription(raw)).toBe(raw);
  });
});
