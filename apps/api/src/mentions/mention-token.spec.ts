import { describe, expect, it } from '@jest/globals';
import { mentionToken, parseMentions, renderMentionsAsText } from './mention-token.js';

const ANNA = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';
const BORIS = '11111111-2222-3333-4444-555555555555';

describe('Упоминания в тексте (US-74)', () => {
  it('находит упоминание и берёт из него идентификатор пользователя', () => {
    expect(parseMentions(`Посмотри, ${mentionToken(ANNA, 'Анна Иванова')}`)).toEqual([
      { userId: ANNA, displayName: 'Анна Иванова' },
    ]);
  });

  it('повторное упоминание того же человека в одном тексте считается один раз', () => {
    const body = `${mentionToken(ANNA, 'Анна')} и ещё раз ${mentionToken(ANNA, 'Анна')}`;
    expect(parseMentions(body)).toHaveLength(1);
  });

  it('находит несколько разных упоминаний в порядке появления', () => {
    const body = `${mentionToken(BORIS, 'Борис')}, ${mentionToken(ANNA, 'Анна')}`;
    expect(parseMentions(body).map((mention) => mention.userId)).toEqual([BORIS, ANNA]);
  });

  it('набранный вручную `@ivan` упоминанием не является', () => {
    expect(parseMentions('@ivan, посмотри @анна и @[Анна](user:не-uuid)')).toEqual([]);
  });

  it('регистр идентификатора не создаёт второго упоминания', () => {
    const body = `${mentionToken(ANNA.toUpperCase(), 'Анна')} ${mentionToken(ANNA, 'Анна')}`;
    expect(parseMentions(body)).toEqual([{ userId: ANNA, displayName: 'Анна' }]);
  });

  it('разворачивает упоминание в `@Имя` — для превью уведомления', () => {
    const body = `Готово, ${mentionToken(ANNA, 'Анна Иванова')}!`;
    expect(renderMentionsAsText(body)).toBe('Готово, @Анна Иванова!');
  });

  it('текст без упоминаний не меняется', () => {
    expect(renderMentionsAsText('Обычный текст с @собакой')).toBe('Обычный текст с @собакой');
  });
});
