import 'reflect-metadata';
import { describe, expect, it } from '@jest/globals';
import { plainToInstance } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, ValidateNested, validateSync } from 'class-validator';
import { Type } from 'class-transformer';
import { INVALID_REQUEST_CODE, InvalidField, validationExceptionFactory } from './validation.js';

const TITLE_REASON = { code: 'invalid_issue_title', message: 'Название задачи обязательно' };

class NestedDto {
  @IsString()
  @Length(1, 5)
  @InvalidField(TITLE_REASON)
  title!: string;
}

class SampleDto {
  @IsString()
  @Length(1, 5)
  @InvalidField(TITLE_REASON)
  title!: string;

  @IsOptional()
  @IsInt()
  priority?: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => NestedDto)
  nested?: NestedDto;
}

/** Наследник DTO: коды родительских полей должны продолжать работать. */
class HeirDto extends SampleDto {
  @IsOptional()
  @IsString()
  @Length(1, 3)
  suffix?: string;
}

function reject(dto: object, value: object): { code?: string; message?: string } {
  const errors = validateSync(plainToInstance(dto as never, value), {
    whitelist: true,
    forbidNonWhitelisted: true,
    forbidUnknownValues: false,
  });
  expect(errors.length).toBeGreaterThan(0);
  return validationExceptionFactory(errors).getResponse() as { code?: string; message?: string };
}

describe('Отказ проверки DTO приводится к общему виду (DEF-04)', () => {
  it('поле со своим кодом отвечает им — как доменный отказ', () => {
    expect(reject(SampleDto, { title: 'слишком длинное' })).toEqual(TITLE_REASON);
  });

  it('тот же код и на пустом значении: для клиента это один отказ', () => {
    expect(reject(SampleDto, { title: '' })).toEqual(TITLE_REASON);
  });

  it('поле без своего кода отвечает общим и называет поле по-русски', () => {
    const body = reject(SampleDto, { title: 'ок', priority: 'много' });
    expect(body.code).toBe(INVALID_REQUEST_CODE);
    expect(body.message).toContain('priority');
  });

  it('английский текст библиотеки наружу не уходит', () => {
    const body = reject(SampleDto, { title: 'слишком длинное' });
    expect(JSON.stringify(body)).not.toContain('must be');
  });

  it('неизвестное поле отклоняется общим кодом, а не списком строк', () => {
    const body = reject(SampleDto, { title: 'ок', hacker: 1 });
    expect(body.code).toBe(INVALID_REQUEST_CODE);
  });

  it('вложенный объект разворачивается до поля, которое не понравилось', () => {
    expect(reject(SampleDto, { title: 'ок', nested: { title: 'слишком длинное' } })).toEqual(
      TITLE_REASON,
    );
  });

  it('наследник DTO наследует и коды полей родителя', () => {
    expect(reject(HeirDto, { title: '' })).toEqual(TITLE_REASON);
    expect(reject(HeirDto, { title: 'ок', suffix: 'длинный' }).code).toBe(INVALID_REQUEST_CODE);
  });

  it('пустой список ошибок всё равно даёт ответ нашей формы', () => {
    const body = validationExceptionFactory([]).getResponse() as { code?: string };
    expect(body.code).toBe(INVALID_REQUEST_CODE);
  });
});
