import { describe, expect, it } from '@jest/globals';
import {
  type NotificationDraft,
  type NotificationType,
  selectRecipients,
} from './notification-types.js';

const ANNA = 'anna';
const BORIS = 'boris';
const VERA = 'vera';

function draft(type: NotificationType, candidateIds: string[]): NotificationDraft {
  return { type, candidateIds, payload: {} };
}

const nothingDisabled = () => false;

describe('Отбор получателей уведомлений (US-100 … US-104)', () => {
  it('никаких уведомлений о собственных действиях', () => {
    const selected = selectRecipients([draft('issue_status_changed', [ANNA, BORIS])], {
      actorId: ANNA,
      isDisabled: nothingDisabled,
    });

    expect(selected).toHaveLength(1);
    expect(selected[0]!.recipientIds).toEqual([BORIS]);
  });

  it('инициатор не получает уведомления, даже если он же автор и исполнитель', () => {
    const selected = selectRecipients(
      [draft('issue_assigned', [ANNA]), draft('issue_status_changed', [ANNA])],
      { actorId: ANNA, isDisabled: nothingDisabled },
    );

    expect(selected).toEqual([]);
  });

  it('один человек получает не более одного уведомления на одно действие', () => {
    const selected = selectRecipients(
      [draft('issue_assigned', [BORIS]), draft('issue_status_changed', [BORIS, VERA])],
      { actorId: ANNA, isDisabled: nothingDisabled },
    );

    expect(selected.map((entry) => [entry.draft.type, entry.recipientIds])).toEqual([
      ['issue_assigned', [BORIS]],
      ['issue_status_changed', [VERA]],
    ]);
  });

  it('упомянутый подписчик получает уведомление об упоминании, а не о комментарии', () => {
    const selected = selectRecipients(
      [draft('issue_mentioned', [BORIS]), draft('issue_commented', [BORIS, VERA])],
      { actorId: ANNA, isDisabled: nothingDisabled },
    );

    expect(selected.map((entry) => [entry.draft.type, entry.recipientIds])).toEqual([
      ['issue_mentioned', [BORIS]],
      ['issue_commented', [VERA]],
    ]);
  });

  it('повторный кандидат внутри одной заготовки не удваивает уведомление', () => {
    const selected = selectRecipients([draft('issue_commented', [BORIS, BORIS])], {
      actorId: ANNA,
      isDisabled: nothingDisabled,
    });

    expect(selected[0]!.recipientIds).toEqual([BORIS]);
  });

  it('отключённый тип не создаёт записи', () => {
    const selected = selectRecipients([draft('issue_commented', [BORIS, VERA])], {
      actorId: ANNA,
      isDisabled: (userId, type) => userId === BORIS && type === 'issue_commented',
    });

    expect(selected[0]!.recipientIds).toEqual([VERA]);
  });

  it('отключённый «комментарий» не мешает уведомлению об упоминании: типы независимы', () => {
    const selected = selectRecipients(
      [draft('issue_mentioned', [BORIS]), draft('issue_commented', [BORIS])],
      {
        actorId: ANNA,
        isDisabled: (_userId, type) => type === 'issue_commented',
      },
    );

    expect(selected.map((entry) => [entry.draft.type, entry.recipientIds])).toEqual([
      ['issue_mentioned', [BORIS]],
    ]);
  });

  it('отключивший упоминания подписчик всё равно узнаёт о комментарии', () => {
    const selected = selectRecipients(
      [draft('issue_mentioned', [BORIS]), draft('issue_commented', [BORIS])],
      {
        actorId: ANNA,
        isDisabled: (_userId, type) => type === 'issue_mentioned',
      },
    );

    expect(selected.map((entry) => [entry.draft.type, entry.recipientIds])).toEqual([
      ['issue_commented', [BORIS]],
    ]);
  });

  it('пустая заготовка в результат не попадает', () => {
    const selected = selectRecipients([draft('issue_assigned', [])], {
      actorId: ANNA,
      isDisabled: nothingDisabled,
    });

    expect(selected).toEqual([]);
  });
});
