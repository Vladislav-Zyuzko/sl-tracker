import { describe, expect, it } from '@jest/globals';
import {
  formatSessionToken,
  generateSessionId,
  generateSessionVerifier,
  hashSessionVerifier,
  parseSessionToken,
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
