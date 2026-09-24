import 'reflect-metadata';
import { describe, expect, it } from '@jest/globals';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { validationExceptionFactory } from '../../common/index.js';
import { PAT_DEFAULT_EXPIRES_IN_DAYS, PAT_MAX_EXPIRES_IN_DAYS } from '../tokens.service.js';
import { CreateTokenDto, ListTokensQueryDto } from './create-token.dto.js';

/** Повторяет настройки глобального `ValidationPipe` из `app.setup.ts`. */
function validate(dto: object, value: object): { code?: string } | null {
  const errors = validateSync(plainToInstance(dto as never, value), {
    whitelist: true,
    forbidNonWhitelisted: true,
    forbidUnknownValues: false,
  });

  if (errors.length === 0) {
    return null;
  }

  return validationExceptionFactory(errors).getResponse() as { code?: string };
}

describe('CreateTokenDto', () => {
  it('принимает имя и срок в границах', () => {
    expect(validate(CreateTokenDto, { name: 'dsh-mcp', expiresInDays: 365 })).toBeNull();
    expect(validate(CreateTokenDto, { name: 'a', expiresInDays: 1 })).toBeNull();
    expect(
      validate(CreateTokenDto, { name: 'я'.repeat(64), expiresInDays: PAT_MAX_EXPIRES_IN_DAYS }),
    ).toBeNull();
  });

  it.each([{}, { name: '' }, { name: 'x'.repeat(65) }, { name: 42 }])(
    'отклоняет имя в %p своим кодом',
    (value) => {
      expect(validate(CreateTokenDto, value)).toMatchObject({ code: 'invalid_token_name' });
    },
  );

  it('без срока запрос проходит: значение по умолчанию подставляет сервис', () => {
    const dto = plainToInstance(CreateTokenDto, { name: 'ноутбук' });

    expect(validate(CreateTokenDto, { name: 'ноутбук' })).toBeNull();
    expect(dto.expiresInDays).toBeUndefined();
    expect(dto.expiresInDays ?? PAT_DEFAULT_EXPIRES_IN_DAYS).toBe(365);
  });

  it('отклоняет явный null: бессрочных токенов не бывает', () => {
    expect(validate(CreateTokenDto, { name: 'dsh-mcp', expiresInDays: null })).toMatchObject({
      code: 'invalid_expires_in_days',
    });
  });

  it.each([0, -1, PAT_MAX_EXPIRES_IN_DAYS + 1, 1.5, '365'])(
    'отклоняет срок %p',
    (expiresInDays) => {
      expect(validate(CreateTokenDto, { name: 'dsh-mcp', expiresInDays })).toMatchObject({
        code: 'invalid_expires_in_days',
      });
    },
  );

  it('не пропускает посторонние поля — в том числе попытку выдать токен другому', () => {
    expect(validate(CreateTokenDto, { name: 'dsh-mcp', userId: 'кто-то-другой' })).not.toBeNull();
  });
});

describe('ListTokensQueryDto', () => {
  it('строка из query превращается в булево', () => {
    expect(plainToInstance(ListTokensQueryDto, { includeRevoked: 'true' }).includeRevoked).toBe(
      true,
    );
    expect(plainToInstance(ListTokensQueryDto, { includeRevoked: 'false' }).includeRevoked).toBe(
      false,
    );
  });

  it('без параметра отозванные не запрашиваются', () => {
    expect(validate(ListTokensQueryDto, {})).toBeNull();
    expect(plainToInstance(ListTokensQueryDto, {}).includeRevoked).toBeUndefined();
  });

  it('мусор вместо флага отклоняется', () => {
    expect(validate(ListTokensQueryDto, { includeRevoked: 'ага' })).not.toBeNull();
  });
});
