import { describe, expect, it } from '@jest/globals';
import {
  formatSessionToken,
  generateSessionId,
  generateSessionVerifier,
  hashSessionVerifier,
  parseSessionToken,
  tokenPrefix,
  verifierMatches,
} from './session-token.js';

const PEPPER = 'x'.repeat(32);

describe('Секрет сессии', () => {
  it('разбирается обратно в идентификатор и верификатор', () => {
    const id = generateSessionId();
    const verifier = generateSessionVerifier();

    expect(parseSessionToken(formatSessionToken(id, verifier))).toEqual({ id, verifier });
  });

  it('верификатор непредсказуем: два вызова не совпадают', () => {
    expect(generateSessionVerifier()).not.toBe(generateSessionVerifier());
  });

  it.each([undefined, null, '', 'мусор', 'не-uuid.verifier', `${generateSessionId()}.короткий`])(
    'не принимает %s',
    (value) => {
      expect(parseSessionToken(value)).toBeNull();
    },
  );

  it('хеш укладывается в колонку char(64) и зависит от секрета приложения', () => {
    const verifier = generateSessionVerifier();
    const hash = hashSessionVerifier(verifier, PEPPER);

    expect(hash).toHaveLength(64);
    expect(hash).not.toBe(hashSessionVerifier(verifier, 'y'.repeat(32)));
  });

  it('сравнение принимает свой верификатор и отвергает чужой', () => {
    const verifier = generateSessionVerifier();
    const hash = hashSessionVerifier(verifier, PEPPER);

    expect(verifierMatches(verifier, PEPPER, hash)).toBe(true);
    expect(verifierMatches(generateSessionVerifier(), PEPPER, hash)).toBe(false);
  });
});

describe('Префикс токена', () => {
  it('всегда 8 символов и не зависит от длины верификатора', () => {
    const id = generateSessionId();

    const short = tokenPrefix(formatSessionToken(id, generateSessionVerifier()));
    const long = tokenPrefix(formatSessionToken(id, `${generateSessionVerifier()}xxxxxxxx`));

    expect(short).toHaveLength(8);
    expect(short).toBe(long);
  });

  it('берётся из идентификатора сессии, а не из секрета', () => {
    const id = generateSessionId();
    const verifier = generateSessionVerifier();

    // Префикс виден в списке токенов, поэтому он обязан быть частью идентификатора,
    // а не секрета: иначе список раздавал бы начало верификатора.
    expect(tokenPrefix(formatSessionToken(id, verifier))).toBe(id.slice(0, 8));
    expect(tokenPrefix(formatSessionToken(id, 'A'.repeat(43)))).toBe(id.slice(0, 8));
  });

  it('у двух токенов префиксы разные: их назначение — различать строки в списке', () => {
    const first = tokenPrefix(formatSessionToken(generateSessionId(), generateSessionVerifier()));
    const second = tokenPrefix(formatSessionToken(generateSessionId(), generateSessionVerifier()));

    expect(first).not.toBe(second);
  });

  it('укладывается в колонку varchar(12) при любом входе', () => {
    expect(tokenPrefix('').length).toBeLessThanOrEqual(12);
    expect(tokenPrefix('x'.repeat(200)).length).toBeLessThanOrEqual(12);
  });
});
