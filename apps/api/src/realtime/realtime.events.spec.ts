import { describe, expect, it } from '@jest/globals';
import {
  REALTIME_CONTROL_CHANNEL,
  type RealtimeEvent,
  decodeControl,
  decodeEnvelope,
  encodeEnvelope,
  issueTopic,
  projectTopic,
  realtimeChannel,
  userTopic,
} from './realtime.events.js';

const EVENT: RealtimeEvent = {
  topic: issueTopic('2a8f7c1e-0000-4000-8000-000000000001'),
  event: 'comment.created',
  projectId: '2a8f7c1e-0000-4000-8000-000000000002',
  actorId: '2a8f7c1e-0000-4000-8000-000000000003',
  data: { id: 'c-1', issueKey: 'DEV-42' },
};

describe('каналы', () => {
  it('тема раскладывается в канал по виду и идентификатору', () => {
    expect(realtimeChannel(issueTopic('i-1'))).toBe('sl:rt:issue:i-1');
    expect(realtimeChannel(projectTopic('p-1'))).toBe('sl:rt:project:p-1');
    expect(realtimeChannel(userTopic('u-1'))).toBe('sl:rt:user:u-1');
  });

  it('служебный канал отличается от любого канала темы', () => {
    expect(REALTIME_CONTROL_CHANNEL).toBe('sl:rt:control');
    expect(realtimeChannel(userTopic('control'))).not.toBe(REALTIME_CONTROL_CHANNEL);
  });
});

describe('конверт события', () => {
  it('переживает круг «записали — прочитали» без потерь', () => {
    const at = new Date('2026-09-09T10:00:00.000Z');
    expect(decodeEnvelope(encodeEnvelope(EVENT, at))).toEqual({ ...EVENT, at: at.toISOString() });
  });

  it('проект сохраняется: по нему право проверяется ещё раз при рассылке', () => {
    const decoded = decodeEnvelope(encodeEnvelope(EVENT));
    expect(decoded?.projectId).toBe(EVENT.projectId);
  });

  it('мусор и чужой формат дают null, а не исключение', () => {
    for (const raw of [
      '',
      'не json',
      '[]',
      '{}',
      '{"topic":{"kind":"queue","id":"q"},"event":"comment.created","at":"x","data":{}}',
      '{"topic":{"kind":"issue","id":"i"},"event":"issue.exploded","at":"x","data":{}}',
      '{"topic":{"kind":"issue","id":"i"},"event":"issue.updated","at":"x"}',
      '{"topic":"issue:DEV-1","event":"issue.updated","at":"x","data":{}}',
    ]) {
      expect(() => decodeEnvelope(raw)).not.toThrow();
      expect(decodeEnvelope(raw)).toBeNull();
    }
  });
});

describe('служебные сообщения', () => {
  it('разбираются оба вида отзыва', () => {
    expect(decodeControl('{"type":"user_revoked","userId":"u-1"}')).toEqual({
      type: 'user_revoked',
      userId: 'u-1',
    });
    expect(decodeControl('{"type":"session_revoked","sessionId":"s-1"}')).toEqual({
      type: 'session_revoked',
      sessionId: 's-1',
    });
  });

  it('неполное и незнакомое сообщение игнорируется', () => {
    for (const raw of ['{"type":"user_revoked"}', '{"type":"boom","userId":"u-1"}', 'x']) {
      expect(decodeControl(raw)).toBeNull();
    }
  });
});
