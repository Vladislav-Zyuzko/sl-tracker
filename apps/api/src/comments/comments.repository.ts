import { randomUUID } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { and, asc, desc, eq, sql } from 'drizzle-orm';
import { DB, UnitOfWork, type Database, type Executor } from '../database/index.js';
import { comments, issueHistory, users } from '../database/schema/index.js';
import type { UserRef } from '../issues/index.js';
import { MentionsRepository } from '../mentions/index.js';
import { NotificationEventsService, type IssueEventRef } from '../notifications/index.js';
// Конкретные файлы, а не бочка realtime: та тянет gateway, который сам зависит
// от домена задач, — получился бы цикл модулей.
import { issueTopic } from '../realtime/realtime.events.js';
import { RealtimePublisher } from '../realtime/realtime.publisher.js';

export interface CommentRow {
  id: string;
  issueId: string;
  body: string;
  author: UserRef;
  /** Не `null` — комментарий правили: в ленте он помечен «изменён» (US-72). */
  editedAt: Date | null;
  createdAt: Date;
  /** Упомянутые участники: имена актуальные, а не те, что были в момент написания. */
  mentions: UserRef[];
}

export interface CommentPageOptions {
  issueId: string;
  limit: number;
  /** Курсор идёт **назад по времени**: лента читается снизу, «показать более ранние». */
  before?: { createdAt: Date; id: string };
}

/**
 * SQL комментариев.
 *
 * Правило, за которое отвечает этот файл: **комментарий, упоминания и уведомления
 * о них пишутся в одной транзакции**. Иначе бывает «уведомление об упоминании есть,
 * комментария нет» — и наоборот.
 *
 * Автор комментария приезжает join'ом, упомянутые — одним запросом на страницу:
 * лента на 100 комментариев не должна превращаться в 200 запросов.
 */
@Injectable()
export class CommentsRepository {
  constructor(
    @Inject(DB) private readonly db: Database,
    private readonly uow: UnitOfWork,
    private readonly mentions: MentionsRepository,
    private readonly events: NotificationEventsService,
    private readonly realtime: RealtimePublisher,
  ) {}

  /**
   * Создание комментария вместе с упоминаниями и уведомлениями (US-71, US-74, US-102).
   *
   * Порядок внутри транзакции важен:
   *  1. комментарий вставляется — с этого момента его автор становится подписчиком
   *     задачи (D-17), и отдельной таблицы подписок для этого не нужно;
   *  2. сохраняются упоминания — только участников проекта (D-41);
   *  3. считаются подписчики и создаются уведомления. Упоминание идёт первой
   *     заготовкой: упомянутый подписчик получает **одно** уведомление — об упоминании
   *     (US-104).
   */
  async create(input: {
    issue: IssueEventRef;
    authorId: string;
    body: string;
  }): Promise<CommentRow> {
    return this.uow.transaction(async (tx) => {
      const [created] = await tx
        .insert(comments)
        .values({ issueId: input.issue.id, authorId: input.authorId, body: input.body })
        .returning({
          id: comments.id,
          issueId: comments.issueId,
          body: comments.body,
          editedAt: comments.editedAt,
          createdAt: comments.createdAt,
        });

      const mentioned = await this.mentions.sync(
        tx,
        { issueId: input.issue.id, commentId: created!.id },
        input.body,
        { projectId: input.issue.projectId, actorId: input.authorId },
      );

      const subscribers = await this.events.subscribersOf(tx, input.issue.id);
      const mentionedIds = mentioned.filter((row) => row.isNew).map((row) => row.id);

      await this.events.emit(tx, { actorId: input.authorId, projectId: input.issue.projectId }, [
        this.events.mentioned(input.issue, mentionedIds, {
          commentId: created!.id,
          body: input.body,
        }),
        this.events.commented(input.issue, subscribers, {
          id: created!.id,
          body: input.body,
        }),
      ]);

      const author = await readUser(tx, input.authorId);

      this.announce(tx, input.issue, 'comment.created', created!.id, input.authorId);

      return {
        ...created!,
        author,
        mentions: mentioned.map(({ isNew: _isNew, ...user }) => user),
      };
    });
  }

  /**
   * Правка своего комментария (US-72).
   *
   * Уведомление создаётся **только вновь упомянутым**: ранее упомянутые повторно
   * не уведомляются, и нового уведомления о комментарии правка не порождает (US-74,
   * US-102).
   */
  async update(input: {
    commentId: string;
    issue: IssueEventRef;
    actorId: string;
    body: string;
  }): Promise<CommentRow | null> {
    return this.uow.transaction(async (tx) => {
      const [updated] = await tx
        .update(comments)
        .set({ body: input.body, editedAt: new Date() })
        .where(eq(comments.id, input.commentId))
        .returning({
          id: comments.id,
          issueId: comments.issueId,
          authorId: comments.authorId,
          body: comments.body,
          editedAt: comments.editedAt,
          createdAt: comments.createdAt,
        });

      if (!updated) {
        return null;
      }

      const mentioned = await this.mentions.sync(
        tx,
        { issueId: input.issue.id, commentId: updated.id },
        input.body,
        { projectId: input.issue.projectId, actorId: input.actorId },
      );

      const freshlyMentioned = mentioned.filter((row) => row.isNew).map((row) => row.id);
      await this.events.emit(tx, { actorId: input.actorId, projectId: input.issue.projectId }, [
        this.events.mentioned(input.issue, freshlyMentioned, {
          commentId: updated.id,
          body: input.body,
        }),
      ]);

      const author = await readUser(tx, updated.authorId);

      this.announce(tx, input.issue, 'comment.updated', updated.id, input.actorId);

      return {
        id: updated.id,
        issueId: updated.issueId,
        body: updated.body,
        editedAt: updated.editedAt,
        createdAt: updated.createdAt,
        author,
        mentions: mentioned.map(({ isNew: _isNew, ...user }) => user),
      };
    });
  }

  /**
   * Удаление комментария вместе с записью истории — в одной транзакции (US-73, US-91).
   *
   * Удаление физическое: текст не должен остаться нигде, включая историю. В историю
   * попадает, **кто удалил и чей** комментарий, без текста. Уведомления, ссылавшиеся
   * на комментарий, остаются в центре, но теряют ссылку (`comment_id` → NULL,
   * внешний ключ `on delete set null`) — US-102.
   */
  async delete(input: {
    commentId: string;
    issue: IssueEventRef;
    actorId: string;
  }): Promise<boolean> {
    return this.uow.transaction(async (tx) => {
      const deleted = await tx
        .delete(comments)
        .where(and(eq(comments.id, input.commentId), eq(comments.issueId, input.issue.id)))
        .returning({ authorId: comments.authorId });

      if (deleted.length === 0) {
        return false;
      }

      const author = await readUser(tx, deleted[0]!.authorId);

      await tx.insert(issueHistory).values({
        issueId: input.issue.id,
        actorId: input.actorId,
        kind: 'comment_deleted',
        groupId: randomUUID(),
        // Чей комментарий — да; что в нём было — нет (US-73).
        oldValue: author.displayName,
        newValue: null,
        oldRefId: author.id,
        newRefId: null,
      });

      this.announce(tx, input.issue, 'comment.deleted', input.commentId, input.actorId);
      return true;
    });
  }

  /**
   * Живое обновление ленты комментариев (D-26).
   *
   * Уходит **после фиксации** транзакции: событие, опубликованное изнутри неё,
   * обгоняет собственные данные, и клиент приходит за комментарием, которого ещё нет.
   *
   * В событии — сигнал и идентификатор комментария, а не его текст: тело комментария
   * клиент забирает тем же запросом, что и всегда, и получает ровно тот же формат,
   * что отдаёт REST.
   */
  private announce(
    tx: Executor,
    issue: IssueEventRef,
    event: 'comment.created' | 'comment.updated' | 'comment.deleted',
    commentId: string,
    actorId: string,
  ): void {
    this.realtime.after(tx, [
      {
        topic: issueTopic(issue.id),
        event,
        projectId: issue.projectId,
        actorId,
        data: { id: commentId, issueKey: issue.key },
      },
    ]);
  }

  /** Комментарий вместе с автором — нужен проверке прав перед правкой и удалением. */
  async findById(
    issueId: string,
    commentId: string,
  ): Promise<{ id: string; authorId: string } | null> {
    const [row] = await this.db
      .select({ id: comments.id, authorId: comments.authorId })
      .from(comments)
      .where(and(eq(comments.id, commentId), eq(comments.issueId, issueId)))
      .limit(1);
    return row ?? null;
  }

  /**
   * Порция ленты. Наружу отдаётся **в хронологическом порядке, сначала старые**
   * (US-70), а выбирается с конца: страница по умолчанию — последние комментарии,
   * а кнопка «Показать более ранние» уводит курсором назад по времени.
   *
   * Читается на один комментарий больше запрошенного: так узнаём, есть ли ещё
   * более ранние, не считая их отдельным запросом.
   */
  async page(options: CommentPageOptions): Promise<CommentRow[]> {
    const conditions = [eq(comments.issueId, options.issueId)];
    if (options.before) {
      conditions.push(
        sql`(${comments.createdAt}, ${comments.id}) < (${options.before.createdAt}, ${options.before.id}::uuid)`,
      );
    }

    const rows = await this.db
      .select({
        id: comments.id,
        issueId: comments.issueId,
        body: comments.body,
        editedAt: comments.editedAt,
        createdAt: comments.createdAt,
        authorId: users.id,
        authorDisplayName: users.displayName,
        authorAvatarUrl: users.avatarUrl,
      })
      .from(comments)
      .innerJoin(users, eq(users.id, comments.authorId))
      .where(and(...conditions))
      .orderBy(desc(comments.createdAt), desc(comments.id))
      .limit(options.limit);

    const mentionsByComment = await this.mentions.forComments(rows.map((row) => row.id));

    return rows.map(({ authorId, authorDisplayName, authorAvatarUrl, ...row }) => ({
      ...row,
      author: { id: authorId, displayName: authorDisplayName, avatarUrl: authorAvatarUrl },
      mentions: mentionsByComment.get(row.id) ?? [],
    }));
  }

  /** Счётчик на вкладке «Комментарии N». */
  async count(issueId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(comments)
      .where(eq(comments.issueId, issueId));
    return row?.value ?? 0;
  }

  /** Один комментарий целиком — ответ на создание и на правку. */
  async view(issueId: string, commentId: string): Promise<CommentRow | null> {
    const [row] = await this.db
      .select({
        id: comments.id,
        issueId: comments.issueId,
        body: comments.body,
        editedAt: comments.editedAt,
        createdAt: comments.createdAt,
        authorId: users.id,
        authorDisplayName: users.displayName,
        authorAvatarUrl: users.avatarUrl,
      })
      .from(comments)
      .innerJoin(users, eq(users.id, comments.authorId))
      .where(and(eq(comments.id, commentId), eq(comments.issueId, issueId)))
      .orderBy(asc(comments.createdAt))
      .limit(1);

    if (!row) {
      return null;
    }

    const mentionsByComment = await this.mentions.forComments([row.id]);
    const { authorId, authorDisplayName, authorAvatarUrl, ...rest } = row;

    return {
      ...rest,
      author: { id: authorId, displayName: authorDisplayName, avatarUrl: authorAvatarUrl },
      mentions: mentionsByComment.get(row.id) ?? [],
    };
  }
}

/** Автор комментария для ответа. Внутри транзакции: имя должно быть тем же, что записали. */
async function readUser(tx: Executor, userId: string): Promise<UserRef> {
  const [row] = await tx
    .select({ id: users.id, displayName: users.displayName, avatarUrl: users.avatarUrl })
    .from(users)
    .where(eq(users.id, userId))
    .limit(1);
  return row!;
}
