/**
 * Состояние приглашения не хранится в БД: оно вычисляется из `expires_at`
 * и `revoked_at` (см. комментарий к таблице `invitations`). Хранить его отдельно
 * значило бы завести фоновую задачу, переводящую приглашения в «истекло»,
 * и жить с расхождением между полем и часами.
 */
export type InvitationState = 'active' | 'expired' | 'revoked';

export interface InvitationLifetime {
  expiresAt: Date;
  revokedAt: Date | null;
}

/**
 * Отзыв важнее срока: отозванное приглашение остаётся отозванным и после того,
 * как истечёт его срок. Наружу эта разница всё равно не выходит — экран показывает
 * оба случая одинаково (design/screens/invite-accept.md, состояние 4).
 */
export function invitationState(row: InvitationLifetime, now: Date = new Date()): InvitationState {
  if (row.revokedAt !== null) {
    return 'revoked';
  }
  return row.expiresAt.getTime() <= now.getTime() ? 'expired' : 'active';
}

export function isUsable(row: InvitationLifetime, now: Date = new Date()): boolean {
  return invitationState(row, now) === 'active';
}

/** Сроки жизни из US-20: 1, 7 или 30 дней. Бессрочных приглашений нет. */
export const INVITATION_LIFETIMES_DAYS = [1, 7, 30] as const;
export const INVITATION_DEFAULT_LIFETIME_DAYS = 7;

export type InvitationLifetimeDays = (typeof INVITATION_LIFETIMES_DAYS)[number];

export function expiryFrom(days: number, now: Date = new Date()): Date {
  return new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
}
