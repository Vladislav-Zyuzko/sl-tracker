import { describe, expect, it } from '@jest/globals';
import { IssueKeyService } from './issue-key.service.js';

describe('IssueKeyService: формат и разбор ключей (ADR-0004)', () => {
  describe('format', () => {
    it('собирает ключ из ключа очереди и номера', () => {
      expect(IssueKeyService.format('DEV', 42)).toBe('DEV-42');
    });

    it('приводит ключ очереди к верхнему регистру: хранится и отображается он так', () => {
      expect(IssueKeyService.format('dev', 1)).toBe('DEV-1');
    });
  });

  describe('parse', () => {
    it('разбирает ключ из адреса', () => {
      expect(IssueKeyService.parse('DEV-42')).toEqual({
        queueKey: 'DEV',
        number: 42,
        key: 'DEV-42',
      });
    });

    it('регистр в адресе не важен: /issues/dev-42 открывает ту же задачу', () => {
      expect(IssueKeyService.parse('dev-42')?.key).toBe('DEV-42');
    });

    it.each([
      ['без номера', 'DEV-'],
      ['без ключа очереди', '-42'],
      ['номер ноль', 'DEV-0'],
      ['ключ очереди из одной буквы', 'D-1'],
      ['ключ очереди начинается с цифры', '1DEV-1'],
      ['кириллица', 'РАЗ-1'],
      ['пробел внутри', 'DE V-1'],
      ['лишний хвост', 'DEV-42/edit'],
      ['ключ очереди длиннее 10 символов', 'ABCDEFGHIJK-1'],
    ])('не разбирает %s', (_case, raw) => {
      expect(IssueKeyService.parse(raw)).toBeNull();
    });
  });

  describe('normalizeQueueKey', () => {
    it.each([
      ['dev', 'DEV'],
      ['  ops  ', 'OPS'],
      ['A1', 'A1'],
      ['ABCDEFGHIJ', 'ABCDEFGHIJ'],
    ])('приводит %s к %s', (raw, expected) => {
      expect(IssueKeyService.normalizeQueueKey(raw)).toBe(expected);
    });

    it.each([['A'], ['ABCDEFGHIJK'], ['1DEV'], ['DE-V'], ['РАЗ']])(
      'отклоняет недопустимый ключ %s',
      (raw) => {
        expect(IssueKeyService.normalizeQueueKey(raw)).toBeNull();
      },
    );
  });
});
