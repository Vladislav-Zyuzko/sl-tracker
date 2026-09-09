import { storyPointsLabel } from './issue-fields.js';

/** Что именно зафиксировано записью истории. Совпадает с enum `issue_history_kind`. */
export type IssueHistoryKind =
  | 'issue_created'
  | 'title_changed'
  | 'description_changed'
  | 'status_changed'
  | 'priority_changed'
  | 'story_points_changed'
  | 'author_changed'
  | 'assignee_changed'
  | 'attachment_added'
  | 'attachment_removed'
  | 'link_added'
  | 'link_removed'
  | 'comment_deleted';

/** Поля задачи, за изменением которых следит история. */
export interface IssueSnapshot {
  title: string;
  description: string | null;
  statusId: string;
  priority: number;
  storyPoints: number | null;
  authorId: string;
  assigneeId: string | null;
}

export type IssuePatch = Partial<IssueSnapshot>;

/** Заготовка записи истории: `issueId`, `groupId` и автора добавляет репозиторий. */
export interface HistoryEntryDraft {
  kind: IssueHistoryKind;
  oldValue: string | null;
  newValue: string | null;
  oldRefId: string | null;
  newRefId: string | null;
}

/**
 * Читаемые названия на момент изменения: статус может быть переименован, а история
 * обязана показывать то, что было (комментарий к таблице `issue_history`).
 */
export interface HistoryLabels {
  statusNames: ReadonlyMap<string, string>;
  userNames: ReadonlyMap<string, string>;
}

/** Значение поля в истории обрезается до размера колонки, а не роняет запись. */
const VALUE_MAX_LENGTH = 512;

/**
 * Сравнивает состояние задачи до и после изменения и возвращает записи истории
 * (US-90, US-91).
 *
 * Правила, которые здесь закодированы:
 *  - запись **не создаётся**, если значение фактически не изменилось: повторный выбор
 *    того же статуса или сохранение неизменённого названия истории не порождают;
 *  - у описания фиксируется только факт изменения, без старого и нового текста —
 *    diff в MVP не хранится (US-91, US-43);
 *  - «пусто» отображается как отсутствие значения (`null`), а не как пустая строка:
 *    снятие исполнителя — это «не назначен», снятие оценки — «не оценено»;
 *  - смена автора логируется отдельной записью и не путается с созданием задачи:
 *    создателя показывает самая первая запись `issue_created` (D-13).
 *
 * Порядок записей — порядок полей в панели задачи (US-92): так группа изменений
 * читается сверху вниз так же, как выглядит сама задача.
 */
export function diffIssue(
  before: IssueSnapshot,
  patch: IssuePatch,
  labels: HistoryLabels,
): HistoryEntryDraft[] {
  const entries: HistoryEntryDraft[] = [];

  if (patch.title !== undefined && patch.title !== before.title) {
    entries.push(plain('title_changed', before.title, patch.title));
  }

  if (patch.description !== undefined && patch.description !== before.description) {
    // Только факт: полные тексты старой и новой версии не хранятся (US-91).
    entries.push(plain('description_changed', null, null));
  }

  if (patch.statusId !== undefined && patch.statusId !== before.statusId) {
    entries.push({
      kind: 'status_changed',
      oldValue: labels.statusNames.get(before.statusId) ?? null,
      newValue: labels.statusNames.get(patch.statusId) ?? null,
      oldRefId: before.statusId,
      newRefId: patch.statusId,
    });
  }

  if (patch.priority !== undefined && patch.priority !== before.priority) {
    entries.push(plain('priority_changed', String(before.priority), String(patch.priority)));
  }

  if (patch.storyPoints !== undefined && patch.storyPoints !== before.storyPoints) {
    entries.push(
      plain(
        'story_points_changed',
        storyPointsLabel(before.storyPoints),
        storyPointsLabel(patch.storyPoints),
      ),
    );
  }

  if (patch.authorId !== undefined && patch.authorId !== before.authorId) {
    entries.push({
      kind: 'author_changed',
      oldValue: labels.userNames.get(before.authorId) ?? null,
      newValue: labels.userNames.get(patch.authorId) ?? null,
      oldRefId: before.authorId,
      newRefId: patch.authorId,
    });
  }

  if (patch.assigneeId !== undefined && patch.assigneeId !== before.assigneeId) {
    entries.push({
      kind: 'assignee_changed',
      oldValue: before.assigneeId ? (labels.userNames.get(before.assigneeId) ?? null) : null,
      newValue: patch.assigneeId ? (labels.userNames.get(patch.assigneeId) ?? null) : null,
      oldRefId: before.assigneeId,
      newRefId: patch.assigneeId,
    });
  }

  return entries;
}

/**
 * Какие идентификаторы понадобятся, чтобы подписать записи читаемыми названиями.
 * Собирается до похода в базу, чтобы вытащить их одним запросом, а не по одному
 * на поле.
 */
export function labelLookups(
  before: IssueSnapshot,
  patch: IssuePatch,
): { statusIds: string[]; userIds: string[] } {
  const statusIds = new Set<string>();
  const userIds = new Set<string>();

  if (patch.statusId !== undefined && patch.statusId !== before.statusId) {
    statusIds.add(before.statusId);
    statusIds.add(patch.statusId);
  }
  if (patch.authorId !== undefined && patch.authorId !== before.authorId) {
    userIds.add(before.authorId);
    userIds.add(patch.authorId);
  }
  if (patch.assigneeId !== undefined && patch.assigneeId !== before.assigneeId) {
    if (before.assigneeId) {
      userIds.add(before.assigneeId);
    }
    if (patch.assigneeId) {
      userIds.add(patch.assigneeId);
    }
  }

  return { statusIds: [...statusIds], userIds: [...userIds] };
}

/** Оставляет в патче только поля, которые действительно меняются. */
export function effectiveChanges(before: IssueSnapshot, patch: IssuePatch): IssuePatch {
  const changes: IssuePatch = {};
  for (const [field, value] of Object.entries(patch) as [keyof IssueSnapshot, never][]) {
    if (value !== undefined && value !== before[field]) {
      changes[field] = value;
    }
  }
  return changes;
}

/**
 * Имена изменившихся полей **так, как их зовёт API**.
 *
 * Внутри домена поле называется `statusId`, а в ответе `GET /api/issues/{key}` —
 * `status`. Живое обновление обязано называть его так же, как REST: разошедшиеся
 * имена одного и того же — вечный источник багов на клиенте.
 */
const API_FIELD_NAMES: Record<keyof IssueSnapshot, string> = {
  title: 'title',
  description: 'description',
  statusId: 'status',
  priority: 'priority',
  storyPoints: 'storyPoints',
  authorId: 'author',
  assigneeId: 'assignee',
};

export function changedApiFields(changes: IssuePatch): string[] {
  return (Object.keys(changes) as (keyof IssueSnapshot)[])
    .filter((field) => changes[field] !== undefined)
    .map((field) => API_FIELD_NAMES[field]);
}

function plain(
  kind: IssueHistoryKind,
  oldValue: string | null,
  newValue: string | null,
): HistoryEntryDraft {
  return {
    kind,
    oldValue: truncate(oldValue),
    newValue: truncate(newValue),
    oldRefId: null,
    newRefId: null,
  };
}

function truncate(value: string | null): string | null {
  if (value === null) {
    return null;
  }
  return value.length > VALUE_MAX_LENGTH ? value.slice(0, VALUE_MAX_LENGTH) : value;
}
