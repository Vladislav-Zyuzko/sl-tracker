import { describe, expect, it } from '@jest/globals';
import { parseBootstrapEmails } from './access-bootstrap.service.js';

/**
 * Разбор `ACCESS_LIST_BOOTSTRAP_EMAILS` (ADR-0006, п. 2; US-06). Сама вставка
 * идемпотентна за счёт уникального индекса по `lower(email)` и проверяется e2e.
 */
describe('parseBootstrapEmails', () => {
  it('пустое значение — пустой список, а не ошибка старта', () => {
    expect(parseBootstrapEmails(undefined)).toEqual({ emails: [], rejected: 0 });
    expect(parseBootstrapEmails('')).toEqual({ emails: [], rejected: 0 });
  });

  it('разбирает адреса через запятую, пробелы и переводы строк', () => {
    const parsed = parseBootstrapEmails('anna@example.com, petr@yandex.ru\n maria@yandex.ru');
    expect(parsed.emails).toEqual(['anna@example.com', 'petr@yandex.ru', 'maria@yandex.ru']);
  });

  it('приводит к нижнему регистру и схлопывает дубликаты внутри переменной', () => {
    const parsed = parseBootstrapEmails('Anna@Example.com, anna@example.COM');
    expect(parsed.emails).toEqual(['anna@example.com']);
  });

  it('пропускает мусор и считает его, не раскрывая значения', () => {
    const parsed = parseBootstrapEmails('anna@example.com, не-адрес, @, x@y');
    expect(parsed.emails).toEqual(['anna@example.com']);
    expect(parsed.rejected).toBe(3);
  });
});
