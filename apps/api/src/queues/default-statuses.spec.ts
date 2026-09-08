import { describe, expect, it } from '@jest/globals';
import { DEFAULT_STATUSES } from './default-statuses.js';
import { STATUS_CATEGORIES } from './status-category.js';

describe('Статусы очереди по умолчанию (US-60, glossary.md, раздел 5)', () => {
  it('их ровно пять и в фиксированном порядке', () => {
    expect(DEFAULT_STATUSES.map((status) => status.name)).toEqual([
      'Открыт',
      'В работе',
      'Ревью',
      'Тестирование',
      'Закрыт',
    ]);
  });

  it('машинные имена совпадают с глоссарием', () => {
    expect(DEFAULT_STATUSES.map((status) => status.key)).toEqual([
      'open',
      'in_progress',
      'review',
      'testing',
      'closed',
    ]);
  });

  it('категории расставлены по D-09: одна open, три in_progress, одна done', () => {
    expect(DEFAULT_STATUSES.map((status) => status.category)).toEqual([
      'open',
      'in_progress',
      'in_progress',
      'in_progress',
      'done',
    ]);
  });

  it('завершённой считается ровно одна категория, и это категория «Закрыт»', () => {
    const done = DEFAULT_STATUSES.filter((status) => status.category === 'done');
    expect(done).toHaveLength(1);
    expect(done[0]!.key).toBe('closed');
  });

  it('позиции идут подряд с единицы: первый статус — умолчание новой задачи', () => {
    expect(DEFAULT_STATUSES.map((status) => status.position)).toEqual([1, 2, 3, 4, 5]);
    expect(DEFAULT_STATUSES[0]!.key).toBe('open');
  });

  it('все категории берутся из словаря категорий, а не выдумываются рядом', () => {
    for (const status of DEFAULT_STATUSES) {
      expect(STATUS_CATEGORIES).toContain(status.category);
    }
  });
});
