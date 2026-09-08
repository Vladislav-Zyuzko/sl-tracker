/**
 * Типы уведомлений и правила отбора получателей (stories/notifications.md).
 *
 * Здесь только словарь и чистые правила — без SQL и без HTTP: их удобно проверять
 * тестами, а именно в них живут обещания продукта «не более одного уведомления
 * на событие» и «никаких уведомлений о собственных действиях».
 */

/** Совпадает с enum `notification_type` в БД. Отключается каждый отдельно (US-103). */
export const NOTIFICATION_TYPES = [
  'issue_assigned',
  'issue_author_assigned',
  'issue_status_changed',
  'issue_commented',
  'issue_mentioned',
  'project_member_joined',
] as const;

export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

/** В MVP канал один — in-app (D-18). Поле есть, чтобы email не потребовал миграции настроек. */
export const NOTIFICATION_CHANNELS = ['in_app'] as const;
export type NotificationChannel = (typeof NOTIFICATION_CHANNELS)[number];

/**
 * Заготовка уведомления: кому предположительно, о чём и с каким снимком текста.
 * Кто из кандидатов получит запись, решает `selectRecipients`.
 */
export interface NotificationDraft {
  type: NotificationType;
  /** Кандидаты в получатели. Отсеиваются автор действия, дубли и отключившие тип. */
  candidateIds: readonly string[];
  issueId?: string | null;
  commentId?: string | null;
  payload: Record<string, unknown>;
}

export interface NotificationRow {
  recipientId: string;
  type: NotificationType;
  actorId: string;
  projectId: string;
  issueId: string | null;
  commentId: string | null;
  payload: Record<string, unknown>;
}

/**
 * Кто получит уведомления по одному действию пользователя.
 *
 * Правила (US-100 … US-104):
 *  - **никаких уведомлений о собственных действиях**: инициатор выбывает всегда,
 *    даже если он же автор, исполнитель и подписчик;
 *  - **не более одного уведомления на человека за одно действие**: заготовки
 *    перебираются по порядку, и человек, уже получивший запись, из следующих
 *    заготовок выпадает. Отсюда порядок вызова: упоминание идёт раньше комментария
 *    (US-104: упомянутый подписчик получает одно уведомление — об упоминании),
 *    назначение — раньше смены статуса;
 *  - **отключённый тип не создаёт ни записи, ни счётчика** (US-103): человек,
 *    выключивший тип, не «пропускается молча» — он просто не получатель.
 */
export function selectRecipients(
  drafts: readonly NotificationDraft[],
  context: {
    actorId: string;
    /** Кому этот тип уведомлений отключён: пара «пользователь + тип». */
    isDisabled: (userId: string, type: NotificationType) => boolean;
  },
): { draft: NotificationDraft; recipientIds: string[] }[] {
  const taken = new Set<string>([context.actorId]);
  const result: { draft: NotificationDraft; recipientIds: string[] }[] = [];

  for (const draft of drafts) {
    const recipientIds: string[] = [];
    for (const candidate of draft.candidateIds) {
      if (taken.has(candidate) || context.isDisabled(candidate, draft.type)) {
        continue;
      }
      taken.add(candidate);
      recipientIds.push(candidate);
    }
    if (recipientIds.length > 0) {
      result.push({ draft, recipientIds });
    }
  }

  return result;
}
