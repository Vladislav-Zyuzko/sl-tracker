import { describe, expect, it } from '@jest/globals';
import {
  CANONICAL_USER_LABEL,
  canonicalIssueLabel,
  canonicalProjectLabel,
  parseClientCommand,
  parseTopicLabel,
} from './realtime.protocol.js';

/**
 * Протокол сокета. Разбор кадра клиента — публичная граница: сюда прилетает всё,
 * что угодно, и ни один вход не должен приводить к исключению.
 */
describe('parseClientCommand', () => {
  it('разбирает подписку вместе с идентификатором запроса', () => {
    expect(parseClientCommand('{"type":"subscribe","id":"1","topic":"issue:DEV-42"}')).toEqual({
      command: { type: 'subscribe', id: '1', topic: 'issue:DEV-42' },
    });
  });

  it('разбирает отписку и прикладной ping', () => {
    expect(parseClientCommand('{"type":"unsubscribe","topic":"user:me"}').command).toEqual({
      type: 'unsubscribe',
      id: null,
      topic: 'user:me',
    });
    expect(parseClientCommand('{"type":"ping","id":"7"}').command).toEqual({
      type: 'ping',
      id: '7',
    });
  });

  it('не бросает исключение ни на каком мусоре', () => {
    for (const raw of ['', 'не json', '[]', 'null', '42', '"строка"', '{}']) {
      expect(() => parseClientCommand(raw)).not.toThrow();
      expect(parseClientCommand(raw).command).toBeUndefined();
    }
  });

  it('неизвестная команда — это ошибка протокола, а не молчание', () => {
    expect(parseClientCommand('{"type":"publish","topic":"issue:DEV-1"}').error?.code).toBe(
      'unknown_command',
    );
  });

  it('подписка без темы отклоняется', () => {
    expect(parseClientCommand('{"type":"subscribe","id":"1"}').error).toEqual({
      code: 'invalid_topic',
      message: 'Тема не указана',
      id: '1',
    });
  });

  it('слишком длинная тема отклоняется, а не режется', () => {
    const long = `issue:${'A'.repeat(200)}-1`;
    expect(parseClientCommand(JSON.stringify({ type: 'subscribe', topic: long })).error?.code).toBe(
      'invalid_topic',
    );
  });
});

describe('parseTopicLabel', () => {
  it('ключ задачи регистронезависим, канонический вид — верхний регистр (ADR-0004)', () => {
    expect(parseTopicLabel('issue:dev-42')).toEqual({ kind: 'issue', key: 'DEV-42' });
    expect(parseTopicLabel('issue:DEV-42')).toEqual({ kind: 'issue', key: 'DEV-42' });
  });

  it('короткое имя проекта разбирается как есть', () => {
    expect(parseTopicLabel('project:my-team')).toEqual({ kind: 'project', slug: 'my-team' });
  });

  it('своя тема — только `user:me`, чужой идентификатор не принимается вовсе', () => {
    expect(parseTopicLabel(CANONICAL_USER_LABEL)).toEqual({ kind: 'user' });
    expect(parseTopicLabel('user:2a8f7c1e-0000-0000-0000-000000000000')).toBeNull();
    expect(parseTopicLabel('user:someone')).toBeNull();
  });

  it('всё остальное — неизвестная тема', () => {
    for (const label of [
      '',
      'issue:',
      'issue:DEV',
      'issue:-1',
      'issue:DEV-42-1',
      'project:',
      'project:Верхний',
      'queue:DEV',
      'issue:DEV-42 ',
    ]) {
      expect(parseTopicLabel(label)).toBeNull();
    }
  });
});

describe('канонические ярлыки', () => {
  it('совпадают с тем, что принимает разбор: ответ сервера можно слать обратно', () => {
    expect(parseTopicLabel(canonicalIssueLabel('DEV-42'))).toEqual({
      kind: 'issue',
      key: 'DEV-42',
    });
    expect(parseTopicLabel(canonicalProjectLabel('my-team'))).toEqual({
      kind: 'project',
      slug: 'my-team',
    });
  });
});
