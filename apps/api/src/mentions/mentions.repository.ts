import { Inject, Injectable } from '@nestjs/common';
import { and, asc, eq, inArray, isNull, sql } from 'drizzle-orm';
import { DB, type Database, type Executor } from '../database/index.js';
import { mentions, projectMembers, users } from '../database/schema/index.js';
import type { UserRef } from '../issues/index.js';
import { parseMentions } from './mention-token.js';

/** Упоминание, которое действительно сохранено: пользователь есть и он в проекте. */
export interface ResolvedMention extends UserRef {
  /** Упоминание появилось в этом тексте только что — значит, нужно уведомление (US-74). */
  isNew: boolean;
}

export interface MentionTarget {
  issueId: string;
  /** `null` — упоминание в описании задачи, а не в комментарии. */
  commentId: string | null;
}

/**
 * SQL упоминаний.
 *
 * Главное правило домена, за которое отвечает этот файл: **связь создаётся только
 * для участника проекта задачи** (D-41, ADR-0006, п. 6). Упоминание постороннего,
 * пришедшее прямо в API, не сохраняется и не порождает уведомления — молча,
 * без ошибки: текст остаётся текстом (permissions.md, раздел 5).
 */
@Injectable()
export class MentionsRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Сохранить упоминания текста и сказать, кто из них упомянут впервые.
   *
   * Работает в транзакции вызывающего кода: упоминание, комментарий и уведомление
   * об упоминании — одно событие, разъезжаться им нельзя.
   *
   * Ранее сохранённые упоминания при правке текста **не удаляются**: подписка
   * на задачу у человека остаётся, а уже отправленное уведомление отзыву не подлежит
   * (US-74). Повторное упоминание того же человека нового уведомления не создаёт.
   */
  async sync(
    tx: Executor,
    target: MentionTarget,
    body: string,
    context: { projectId: string; actorId: string },
  ): Promise<ResolvedMention[]> {
    const parsed = parseMentions(body);
    if (parsed.length === 0) {
      return [];
    }

    // Отсев посторонних одним запросом: он же приносит актуальные имена и аватары.
    const members = await tx
      .select({
        id: users.id,
        displayName: users.displayName,
        avatarUrl: users.avatarUrl,
      })
      .from(projectMembers)
      .innerJoin(users, eq(users.id, projectMembers.userId))
      .where(
        and(
          eq(projectMembers.projectId, context.projectId),
          inArray(
            projectMembers.userId,
            parsed.map((mention) => mention.userId),
          ),
        ),
      );

    if (members.length === 0) {
      return [];
    }

    const inserted = await tx
      .insert(mentions)
      .values(
        members.map((member) => ({
          issueId: target.issueId,
          commentId: target.commentId,
          mentionedUserId: member.id,
          createdByUserId: context.actorId,
        })),
      )
      // Тот же человек в том же тексте — уже сохранённая связь, а не ошибка (US-74).
      .onConflictDoNothing()
      .returning({ mentionedUserId: mentions.mentionedUserId });

    const fresh = new Set(inserted.map((row) => row.mentionedUserId));

    return members.map((member) => ({
      id: member.id,
      displayName: member.displayName,
      avatarUrl: member.avatarUrl,
      isNew: fresh.has(member.id),
    }));
  }

  /**
   * Упомянутые в перечисленных комментариях — одним запросом на всю страницу ленты,
   * а не по запросу на комментарий.
   */
  async forComments(commentIds: string[]): Promise<Map<string, UserRef[]>> {
    const result = new Map<string, UserRef[]>();
    if (commentIds.length === 0) {
      return result;
    }

    const rows = await this.db
      .select({
        commentId: mentions.commentId,
        id: users.id,
        displayName: users.displayName,
        avatarUrl: users.avatarUrl,
      })
      .from(mentions)
      .innerJoin(users, eq(users.id, mentions.mentionedUserId))
      .where(inArray(mentions.commentId, commentIds))
      .orderBy(asc(users.displayName), asc(users.id));

    for (const row of rows) {
      const list = result.get(row.commentId!) ?? [];
      list.push({ id: row.id, displayName: row.displayName, avatarUrl: row.avatarUrl });
      result.set(row.commentId!, list);
    }

    return result;
  }

  /** Упомянутые в описании задачи (`comment_id is null`). */
  async forIssueDescription(issueId: string): Promise<UserRef[]> {
    return this.db
      .select({
        id: users.id,
        displayName: users.displayName,
        avatarUrl: users.avatarUrl,
      })
      .from(mentions)
      .innerJoin(users, eq(users.id, mentions.mentionedUserId))
      .where(and(eq(mentions.issueId, issueId), isNull(mentions.commentId)))
      .orderBy(asc(users.displayName), asc(users.id));
  }

  /**
   * Подсказка `@`: **только участники проекта задачи** (D-41).
   *
   * Ни одного пути, по которому сюда попал бы посторонний, здесь нет: выборка идёт
   * от `project_members`, а не от `users`. Поиск по имени и по email без учёта
   * регистра (US-74); email наружу отдаётся, потому что подсказка показывает его
   * при совпадении имён — но только по участникам проекта, где он и так виден
   * на вкладке «Участники».
   */
  async suggest(options: {
    projectId: string;
    query?: string;
    limit: number;
  }): Promise<{ id: string; displayName: string; email: string; avatarUrl: string | null }[]> {
    const conditions = [eq(projectMembers.projectId, options.projectId)];

    const query = options.query?.trim();
    if (query) {
      // Экранируем спецсимволы LIKE: `%` и `_` от пользователя не должны становиться
      // подстановочными знаками.
      const pattern = `%${query.replace(/[\\%_]/g, (char) => `\\${char}`)}%`;
      conditions.push(
        sql`(${users.displayName} ilike ${pattern} escape '\\' or ${users.email} ilike ${pattern} escape '\\')`,
      );
    }

    return this.db
      .select({
        id: users.id,
        displayName: users.displayName,
        email: users.email,
        avatarUrl: users.avatarUrl,
      })
      .from(projectMembers)
      .innerJoin(users, eq(users.id, projectMembers.userId))
      .where(and(...conditions))
      .orderBy(asc(users.displayName), asc(users.id))
      .limit(options.limit);
  }
}
