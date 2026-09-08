import { describe, expect, it } from '@jest/globals';
import {
  INVITATION_DEFAULT_LIFETIME_DAYS,
  INVITATION_LIFETIMES_DAYS,
  expiryFrom,
  invitationState,
  isUsable,
} from './invitation-state.js';

const NOW = new Date('2026-02-12T10:00:00.000Z');

describe('Состояние приглашения (US-20, US-22)', () => {
  it('действует, пока срок не истёк и не отозвано', () => {
    const row = { expiresAt: new Date('2026-02-19T10:00:00.000Z'), revokedAt: null };
    expect(invitationState(row, NOW)).toBe('active');
    expect(isUsable(row, NOW)).toBe(true);
  });

  it('истекает ровно в момент срока, а не позже', () => {
    const row = { expiresAt: NOW, revokedAt: null };
    expect(invitationState(row, NOW)).toBe('expired');
    expect(isUsable(row, NOW)).toBe(false);
  });

  it('отозванное остаётся отозванным, даже если срок ещё не вышел', () => {
    const row = {
      expiresAt: new Date('2026-02-19T10:00:00.000Z'),
      revokedAt: new Date('2026-02-13T10:00:00.000Z'),
    };
    expect(invitationState(row, NOW)).toBe('revoked');
    expect(isUsable(row, NOW)).toBe(false);
  });

  it('отзыв важнее срока: истёкшее и отозванное показывается как отозванное', () => {
    const row = {
      expiresAt: new Date('2026-02-01T10:00:00.000Z'),
      revokedAt: new Date('2026-01-30T10:00:00.000Z'),
    };
    expect(invitationState(row, NOW)).toBe('revoked');
  });

  it.each([...INVITATION_LIFETIMES_DAYS])(
    'срок жизни %s дней считается от момента выдачи',
    (days) => {
      expect(expiryFrom(days, NOW).getTime() - NOW.getTime()).toBe(days * 24 * 60 * 60 * 1000);
    },
  );

  it('срок по умолчанию — 7 дней (US-20)', () => {
    expect(INVITATION_DEFAULT_LIFETIME_DAYS).toBe(7);
  });
});
