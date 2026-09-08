import { describe, expect, it } from '@jest/globals';
import { COMMENT_BODY_MAX_LENGTH, normalizeCommentBody } from './comment-body.js';

describe('Текст комментария (US-71)', () => {
  it('обрезает края, но не трогает разметку внутри', () => {
    expect(normalizeCommentBody('  Первая строка\n\n- пункт  ')).toBe('Первая строка\n\n- пункт');
  });

  it('пустой комментарий и комментарий из пробелов отправить нельзя', () => {
    expect(normalizeCommentBody('')).toBeNull();
    expect(normalizeCommentBody('   \n\t  ')).toBeNull();
  });

  it('текст на 10 000 символов допустим, на 10 001 — уже нет', () => {
    expect(normalizeCommentBody('я'.repeat(COMMENT_BODY_MAX_LENGTH))).toHaveLength(
      COMMENT_BODY_MAX_LENGTH,
    );
    expect(normalizeCommentBody('я'.repeat(COMMENT_BODY_MAX_LENGTH + 1))).toBeNull();
  });
});
