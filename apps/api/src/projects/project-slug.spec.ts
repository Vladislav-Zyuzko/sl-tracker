import { describe, expect, it } from '@jest/globals';
import {
  FALLBACK_SLUG_BASE,
  RESERVED_SLUGS,
  SLUG_MAX_LENGTH,
  SLUG_PATTERN,
  slugBase,
  slugCandidate,
  slugify,
  transliterate,
  validateSlug,
} from './project-slug.js';

describe('Короткое имя проекта в адресе (D-35, US-18)', () => {
  describe('slugify', () => {
    it('проверочный пример из D-35: «Сладкий Лимит 2026!» → sladkiy-limit-2026', () => {
      expect(slugify('Сладкий Лимит 2026!')).toBe('sladkiy-limit-2026');
    });

    it.each([
      ['латиница и пробелы', 'Sweet Limit', 'sweet-limit'],
      ['знаки препинания становятся дефисом', 'Веб-сайт: лендинг', 'veb-sayt-lending'],
      ['повторные дефисы схлопываются', 'а   —   б', 'a-b'],
      ['крайние дефисы обрезаются', '  Проект  ', 'proekt'],
      ['ь и ъ пропадают', 'Мальчик подъезд', 'malchik-podezd'],
      ['шипящие', 'Жучок Щавель Чай Шум', 'zhuchok-schavel-chay-shum'],
      ['ю и я', 'Юля Яна', 'yulya-yana'],
      ['ё как е', 'Ёлка', 'elka'],
      ['цифры сохраняются', 'Релиз 2', 'reliz-2'],
      ['латинская диакритика упрощается', 'Café Déjà', 'cafe-deja'],
    ])('%s', (_case, name, expected) => {
      expect(slugify(name)).toBe(expected);
    });

    it('обрезает длинное название до 40 символов и не оставляет дефис на конце', () => {
      const slug = slugify('Очень длинное название проекта про автоматизацию отчётности');
      expect(slug.length).toBeLessThanOrEqual(SLUG_MAX_LENGTH);
      expect(slug.endsWith('-')).toBe(false);
      expect(SLUG_PATTERN.test(slug)).toBe(true);
    });

    it('из названия без допустимых символов не выходит ничего', () => {
      expect(slugify('🎉🎉🎉')).toBe('');
      expect(slugify('!!! ???')).toBe('');
    });

    it('любой результат проходит проверку формата', () => {
      for (const name of ['Проект №1', 'A/B тесты', '2026', 'Ж', 'Sweet   Limit!!!']) {
        const slug = slugify(name);
        expect(slug === '' || SLUG_PATTERN.test(slug)).toBe(true);
      }
    });
  });

  describe('transliterate', () => {
    it('кириллица переводится посимвольно, латиница проходит как есть', () => {
      expect(transliterate('Абв xyz')).toBe('abv xyz');
    });
  });

  describe('slugBase', () => {
    it('название из эмодзи даёт запасную базу — из неё выйдет имя вида project-7', () => {
      expect(slugBase('🎉')).toBe(FALLBACK_SLUG_BASE);
    });

    it('обычное название даёт себя', () => {
      expect(slugBase('Сладкий лимит')).toBe('sladkiy-limit');
    });
  });

  describe('slugCandidate', () => {
    it('первая попытка — сама база', () => {
      expect(slugCandidate('sweet-limit', 1)).toBe('sweet-limit');
    });

    it('при коллизии добавляется числовой суффикс', () => {
      expect(slugCandidate('sweet-limit', 2)).toBe('sweet-limit-2');
      expect(slugCandidate('sweet-limit', 7)).toBe('sweet-limit-7');
    });

    it('системное имя не выдаётся даже первой попыткой', () => {
      expect(slugCandidate('projects', 1)).toBe('projects-2');
      expect(RESERVED_SLUGS.has(slugCandidate('issues', 1))).toBe(false);
    });

    it('с суффиксом длина всё равно не превышает 40 символов', () => {
      const base = 'a'.repeat(SLUG_MAX_LENGTH);
      const candidate = slugCandidate(base, 12);
      expect(candidate.length).toBeLessThanOrEqual(SLUG_MAX_LENGTH);
      expect(candidate.endsWith('-12')).toBe(true);
    });
  });

  describe('validateSlug: ручной ввод администратора', () => {
    it.each(['sladkiy-limit', 'a', 'project-2026', 'a-b-c'])('принимает %s', (value) => {
      expect(validateSlug(value)).toBeNull();
    });

    it.each([
      ['пустое', ''],
      ['кириллица', 'сладкий'],
      ['пробел', 'sweet limit'],
      ['заглавные', 'Sweet'],
      ['двойной дефис', 'sweet--limit'],
      ['дефис в начале', '-sweet'],
      ['дефис в конце', 'sweet-'],
      ['подчёркивание', 'sweet_limit'],
      ['слэш', 'sweet/limit'],
      ['длиннее 40 символов', 'a'.repeat(SLUG_MAX_LENGTH + 1)],
    ])('отклоняет %s как invalid_slug', (_case, value) => {
      expect(validateSlug(value)).toBe('invalid_slug');
    });

    it.each([...RESERVED_SLUGS])('отклоняет системный адрес %s', (value) => {
      expect(validateSlug(value)).toBe('reserved_slug');
    });
  });
});
