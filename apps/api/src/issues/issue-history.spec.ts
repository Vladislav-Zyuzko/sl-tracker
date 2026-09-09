import { describe, expect, it } from '@jest/globals';
import {
  type HistoryLabels,
  type IssueSnapshot,
  changedApiFields,
  diffIssue,
  effectiveChanges,
  labelLookups,
} from './issue-history.js';

const OPEN = '11111111-1111-1111-1111-111111111111';
const IN_PROGRESS = '22222222-2222-2222-2222-222222222222';
const ANNA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const BORIS = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

const before: IssueSnapshot = {
  title: 'Починить экспорт',
  description: 'Падает на больших выгрузках',
  statusId: OPEN,
  priority: 50,
  storyPoints: null,
  authorId: ANNA,
  assigneeId: null,
};

const labels: HistoryLabels = {
  statusNames: new Map([
    [OPEN, 'Открыт'],
    [IN_PROGRESS, 'В работе'],
  ]),
  userNames: new Map([
    [ANNA, 'Анна Иванова'],
    [BORIS, 'Борис Петров'],
  ]),
};

describe('Что попадает в историю (US-91)', () => {
  it('изменение названия фиксируется со старым и новым значением', () => {
    const entries = diffIssue(before, { title: 'Починить экспорт CSV' }, labels);
    expect(entries).toEqual([
      {
        kind: 'title_changed',
        oldValue: 'Починить экспорт',
        newValue: 'Починить экспорт CSV',
        oldRefId: null,
        newRefId: null,
      },
    ]);
  });

  it('у описания фиксируется только факт изменения, без текстов', () => {
    const entries = diffIssue(before, { description: 'Совсем другой текст' }, labels);
    expect(entries).toHaveLength(1);
    expect(entries[0]!.kind).toBe('description_changed');
    expect(entries[0]!.oldValue).toBeNull();
    expect(entries[0]!.newValue).toBeNull();
  });

  it('смена статуса хранит читаемые названия и идентификаторы', () => {
    const entries = diffIssue(before, { statusId: IN_PROGRESS }, labels);
    expect(entries).toEqual([
      {
        kind: 'status_changed',
        oldValue: 'Открыт',
        newValue: 'В работе',
        oldRefId: OPEN,
        newRefId: IN_PROGRESS,
      },
    ]);
  });

  it('назначение исполнителя: «не назначен» — это отсутствие значения, а не пустая строка', () => {
    const entries = diffIssue(before, { assigneeId: BORIS }, labels);
    expect(entries[0]).toEqual({
      kind: 'assignee_changed',
      oldValue: null,
      newValue: 'Борис Петров',
      oldRefId: null,
      newRefId: BORIS,
    });
  });

  it('снятие исполнителя тоже логируется', () => {
    const entries = diffIssue({ ...before, assigneeId: BORIS }, { assigneeId: null }, labels);
    expect(entries[0]).toMatchObject({
      kind: 'assignee_changed',
      oldValue: 'Борис Петров',
      newValue: null,
      newRefId: null,
    });
  });

  it('снятие оценки сложности отображается как переход в «не оценено»', () => {
    const entries = diffIssue({ ...before, storyPoints: 8 }, { storyPoints: null }, labels);
    expect(entries[0]).toMatchObject({
      kind: 'story_points_changed',
      oldValue: '8',
      newValue: null,
    });
  });

  it('смена автора — отдельная запись, создателя она не касается (D-13)', () => {
    const entries = diffIssue(before, { authorId: BORIS }, labels);
    expect(entries).toEqual([
      {
        kind: 'author_changed',
        oldValue: 'Анна Иванова',
        newValue: 'Борис Петров',
        oldRefId: ANNA,
        newRefId: BORIS,
      },
    ]);
  });

  it('запись не создаётся, если значение фактически не изменилось', () => {
    expect(
      diffIssue(before, { statusId: OPEN, priority: 50, title: before.title }, labels),
    ).toEqual([]);
  });

  it('одно действие с несколькими полями даёт несколько записей в порядке панели задачи', () => {
    const entries = diffIssue(
      before,
      { title: 'Новое', statusId: IN_PROGRESS, priority: 80, assigneeId: BORIS },
      labels,
    );
    expect(entries.map((entry) => entry.kind)).toEqual([
      'title_changed',
      'status_changed',
      'priority_changed',
      'assignee_changed',
    ]);
  });

  it('слишком длинное значение обрезается, а не роняет запись', () => {
    const entries = diffIssue(before, { title: 'я'.repeat(600) }, labels);
    expect(entries[0]!.newValue).toHaveLength(512);
  });
});

describe('Отбор изменившихся полей', () => {
  it('оставляет только поля с новым значением', () => {
    expect(effectiveChanges(before, { title: before.title, priority: 80 })).toEqual({
      priority: 80,
    });
  });

  it('пустой патч не порождает изменений', () => {
    expect(effectiveChanges(before, {})).toEqual({});
  });

  it('различает null и «поле не передано» у сложности', () => {
    const withPoints = { ...before, storyPoints: 5 };
    expect(effectiveChanges(withPoints, { storyPoints: null })).toEqual({ storyPoints: null });
    expect(effectiveChanges(withPoints, {})).toEqual({});
  });
});

describe('Сбор идентификаторов для подписи записей', () => {
  it('запрашивает только те статусы и тех людей, которые действительно меняются', () => {
    const lookups = labelLookups(before, {
      statusId: IN_PROGRESS,
      assigneeId: BORIS,
      priority: 80,
    });
    expect(lookups.statusIds.sort()).toEqual([OPEN, IN_PROGRESS].sort());
    expect(lookups.userIds).toEqual([BORIS]);
  });

  it('ничего не запрашивает, когда меняются только простые поля', () => {
    expect(labelLookups(before, { title: 'Другое', priority: 10 })).toEqual({
      statusIds: [],
      userIds: [],
    });
  });
});

/**
 * Имена полей в живом обновлении обязаны совпадать с именами полей в ответе REST:
 * клиент по ним решает, что перечитывать, и разошедшиеся имена он молча пропустит.
 */
describe('changedApiFields', () => {
  it('переводит внутренние имена полей в имена ответа API', () => {
    expect(
      changedApiFields({
        statusId: IN_PROGRESS,
        assigneeId: BORIS,
        authorId: ANNA,
        title: 'Другое',
        description: null,
        priority: 80,
        storyPoints: 5,
      }).sort(),
    ).toEqual(
      ['status', 'assignee', 'author', 'title', 'description', 'priority', 'storyPoints'].sort(),
    );
  });

  it('пустое изменение не даёт ни одного поля: событию неоткуда взяться', () => {
    expect(changedApiFields({})).toEqual([]);
  });

  it('снятый исполнитель — это изменение поля `assignee`, а не его отсутствие', () => {
    expect(changedApiFields({ assigneeId: null })).toEqual(['assignee']);
  });
});
