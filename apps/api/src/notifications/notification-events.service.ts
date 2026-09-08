import { Injectable } from '@nestjs/common';
import type { Executor } from '../database/index.js';
import { notificationExcerpt } from './notification-excerpt.js';
import { NotificationsRepositoryPort } from './notifications.port.js';
import {
  type NotificationDraft,
  type NotificationRow,
  type NotificationType,
  selectRecipients,
} from './notification-types.js';

/** Снимок задачи в тексте уведомления: ключ и название на момент события. */
export interface IssueEventRef {
  id: string;
  key: string;
  title: string;
  projectId: string;
}

/**
 * Создание уведомлений о событиях (US-100 … US-104, US-23).
 *
 * Вызывается **из транзакции того изменения, которое породило событие**, и принимает
 * её исполнителем: иначе бывает «уведомление ушло, а изменение откатилось» — и наоборот.
 * Тяжёлой работы здесь нет: канал один, in-app (D-18), и запись строки стоит дешевле,
 * чем очередь ради неё. Когда появится рассылка по WebSocket и email, она будет читать
 * уже записанные строки (комментарий к таблице `notifications`).
 *
 * Правила «не более одного уведомления на событие на человека» и «никаких уведомлений
 * о собственных действиях» живут в `selectRecipients` и проверяются unit-тестами:
 * здесь только сбор кандидатов и снимков текста.
 */
@Injectable()
export class NotificationEventsService {
  constructor(private readonly repository: NotificationsRepositoryPort) {}

  /**
   * События по задаче, вызванные одним действием пользователя.
   *
   * Порядок заготовок задаёт приоритет: назначение исполнителем и автором важнее
   * смены статуса, упоминание важнее нового комментария (US-104). Человек, попавший
   * в более раннюю заготовку, из последующих выпадает — одно действие даёт ему
   * не больше одного уведомления (US-101).
   */
  async emit(
    tx: Executor,
    context: { actorId: string; projectId: string },
    drafts: readonly NotificationDraft[],
  ): Promise<void> {
    const meaningful = drafts.filter((draft) => draft.candidateIds.length > 0);
    if (meaningful.length === 0) {
      return;
    }

    const candidates = [...new Set(meaningful.flatMap((draft) => [...draft.candidateIds]))].filter(
      (userId) => userId !== context.actorId,
    );
    if (candidates.length === 0) {
      return;
    }

    const disabled = await this.repository.disabledPairs(tx, candidates);
    const selected = selectRecipients(meaningful, {
      actorId: context.actorId,
      isDisabled: (userId, type) => disabled.has(`${userId}:${type}`),
    });

    const rows: NotificationRow[] = selected.flatMap(({ draft, recipientIds }) =>
      recipientIds.map((recipientId) => ({
        recipientId,
        type: draft.type,
        actorId: context.actorId,
        projectId: context.projectId,
        issueId: draft.issueId ?? null,
        commentId: draft.commentId ?? null,
        payload: draft.payload,
      })),
    );

    await this.repository.insertMany(tx, rows);
  }

  /** Подписчики задачи (D-17), уже пересечённые с участниками проекта. */
  subscribersOf(tx: Executor, issueId: string): Promise<string[]> {
    return this.repository.subscribersOf(tx, issueId);
  }

  /** Администраторы проекта — единственные получатели уведомления о новом участнике. */
  projectAdmins(tx: Executor, projectId: string): Promise<string[]> {
    return this.repository.projectAdmins(tx, projectId);
  }

  /** Заготовка «назначили исполнителем» (US-100). */
  assigned(issue: IssueEventRef, assigneeId: string): NotificationDraft {
    return draft('issue_assigned', [assigneeId], issue, {});
  }

  /** Заготовка «указали автором» (US-100). */
  authorAssigned(issue: IssueEventRef, authorId: string): NotificationDraft {
    return draft('issue_author_assigned', [authorId], issue, {});
  }

  /** Заготовка «сменился статус» — всем подписчикам, кроме инициатора (US-101). */
  statusChanged(
    issue: IssueEventRef,
    recipients: readonly string[],
    statuses: { from: string | null; to: string | null },
  ): NotificationDraft {
    return draft('issue_status_changed', recipients, issue, {
      fromStatusName: statuses.from,
      toStatusName: statuses.to,
    });
  }

  /** Заготовка «новый комментарий» — всем подписчикам, кроме автора (US-102). */
  commented(
    issue: IssueEventRef,
    recipients: readonly string[],
    comment: { id: string; body: string },
  ): NotificationDraft {
    return {
      ...draft('issue_commented', recipients, issue, {
        excerpt: notificationExcerpt(comment.body),
      }),
      commentId: comment.id,
    };
  }

  /**
   * Заготовка «упомянули» (US-104). `commentId = null` — упоминание в описании задачи:
   * клиент по нему понимает, куда прокручивать.
   */
  mentioned(
    issue: IssueEventRef,
    recipients: readonly string[],
    source: { commentId: string | null; body: string },
  ): NotificationDraft {
    return {
      ...draft('issue_mentioned', recipients, issue, {
        excerpt: notificationExcerpt(source.body),
        source: source.commentId ? 'comment' : 'description',
      }),
      commentId: source.commentId,
    };
  }

  /** Заготовка «новый участник проекта» — только администраторам (US-23). */
  memberJoined(
    project: { id: string; slug: string; name: string },
    adminIds: readonly string[],
    member: { displayName: string },
  ): NotificationDraft {
    return {
      type: 'project_member_joined',
      candidateIds: adminIds,
      issueId: null,
      commentId: null,
      payload: {
        projectSlug: project.slug,
        projectName: project.name,
        memberName: member.displayName,
      },
    };
  }
}

function draft(
  type: NotificationType,
  candidateIds: readonly string[],
  issue: IssueEventRef,
  payload: Record<string, unknown>,
): NotificationDraft {
  return {
    type,
    candidateIds,
    issueId: issue.id,
    commentId: null,
    // Снимок текста: ключ и название задачи на момент события. Без него старое
    // уведомление менялось бы задним числом вслед за переименованием задачи.
    payload: { issueKey: issue.key, issueTitle: issue.title, ...payload },
  };
}
