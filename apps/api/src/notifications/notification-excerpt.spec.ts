import { describe, expect, it } from '@jest/globals';
import { mentionToken } from '../mentions/index.js';
import { NOTIFICATION_EXCERPT_MAX_LENGTH, notificationExcerpt } from './notification-excerpt.js';

const ANNA = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';

describe('Начало текста в уведомлении (US-102, US-104)', () => {
  it('короткий текст отдаётся целиком', () => {
    expect(notificationExcerpt('Поправил отступы, посмотри')).toBe('Поправил отступы, посмотри');
  });

  it('переводы строк схлопываются: строка в ленте одна', () => {
    expect(notificationExcerpt('Первая строка\n\nвторая строка')).toBe(
      'Первая строка вторая строка',
    );
  });

  it('упоминание разворачивается в `@Имя`, а не остаётся токеном', () => {
    expect(notificationExcerpt(`${mentionToken(ANNA, 'Анна')}, какой размер порции?`)).toBe(
      '@Анна, какой размер порции?',
    );
  });

  it('длинный текст обрезается примерно до ста символов и оканчивается многоточием', () => {
    const excerpt = notificationExcerpt('слово '.repeat(60));

    expect(excerpt.length).toBeLessThanOrEqual(NOTIFICATION_EXCERPT_MAX_LENGTH + 1);
    expect(excerpt.endsWith('…')).toBe(true);
  });

  it('обрезка не рвёт слово посередине, если граница слова близко к лимиту', () => {
    const excerpt = notificationExcerpt(`${'а'.repeat(60)} ${'б'.repeat(80)}`);
    expect(excerpt).toBe(`${'а'.repeat(60)}…`);
  });

  it('но и не выбрасывает половину превью ради одного раннего пробела', () => {
    // Пробел на 20-м символе: обрезать по нему значило бы показать пятую часть.
    const excerpt = notificationExcerpt(`${'а'.repeat(20)} ${'б'.repeat(200)}`);
    expect(excerpt).toHaveLength(NOTIFICATION_EXCERPT_MAX_LENGTH + 1);
  });

  it('разметка Markdown остаётся: её снимает клиент', () => {
    expect(notificationExcerpt('**жирный** текст')).toBe('**жирный** текст');
  });
});
