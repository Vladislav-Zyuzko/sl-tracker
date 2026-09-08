import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, inArray, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import { issueHistory, users } from '../database/schema/index.js';
import type { UserRef } from './issues.repository.js';
import type { IssueHistoryKind } from './issue-history.js';

/** Одно изменённое поле внутри группы. */
export interface HistoryChangeRow {
  id: string;
  kind: IssueHistoryKind;
  oldValue: string | null;
  newValue: string | null;
  oldRefId: string | null;
  newRefId: string | null;
}

/**
 * Одно действие пользователя. Внутри — все поля, изменённые этим действием (US-90):
 * лента истории показывает их одной группой с общим временем и автором.
 */
export interface HistoryGroupRow {
  groupId: string;
  createdAt: Date;
  /** `null` — изменение системное (например, очистка исполнителя), а не человеческое. */
  actor: UserRef | null;
  changes: HistoryChangeRow[];
}

export interface HistoryPageOptions {
  issueId: string;
  limit: number;
  after?: { createdAt: Date; groupId: string };
}

/**
 * Чтение истории задачи (US-90).
 *
 * Страница считается **по группам, а не по записям**: иначе одно действие, изменившее
 * три поля, могло бы разорваться границей страницы и показаться как два разных события.
 * Отсюда два запроса — сначала идентификаторы групп текущей страницы, потом их записи
 * одним `in`. Это не N+1: число запросов не зависит от размера страницы.
 *
 * История не редактируется и не удаляется, поэтому методов записи здесь нет: записи
 * добавляются только в транзакции самого изменения (`IssuesRepository`).
 */
@Injectable()
export class IssueHistoryRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  async page(options: HistoryPageOptions): Promise<HistoryGroupRow[]> {
    const conditions = [eq(issueHistory.issueId, options.issueId)];
    if (options.after) {
      conditions.push(
        sql`(${issueHistory.createdAt}, ${issueHistory.groupId}) < (${options.after.createdAt}, ${options.after.groupId}::uuid)`,
      );
    }

    // Группа целиком пишется одним `insert`, поэтому `created_at` внутри неё одинаков;
    // `min` здесь — способ вытащить его в агрегате, а не признак разнобоя.
    const groups = await this.db
      .select({
        groupId: issueHistory.groupId,
        createdAt: sql<Date>`min(${issueHistory.createdAt})`,
      })
      .from(issueHistory)
      .where(and(...conditions))
      .groupBy(issueHistory.groupId)
      .orderBy(desc(sql`min(${issueHistory.createdAt})`), desc(issueHistory.groupId))
      .limit(options.limit);

    if (groups.length === 0) {
      return [];
    }

    const rows = await this.db
      .select({
        id: issueHistory.id,
        groupId: issueHistory.groupId,
        kind: issueHistory.kind,
        oldValue: issueHistory.oldValue,
        newValue: issueHistory.newValue,
        oldRefId: issueHistory.oldRefId,
        newRefId: issueHistory.newRefId,
        createdAt: issueHistory.createdAt,
        actorId: users.id,
        actorDisplayName: users.displayName,
        actorAvatarUrl: users.avatarUrl,
      })
      .from(issueHistory)
      .leftJoin(users, eq(users.id, issueHistory.actorId))
      .where(
        and(
          eq(issueHistory.issueId, options.issueId),
          inArray(
            issueHistory.groupId,
            groups.map((group) => group.groupId),
          ),
        ),
      )
      .orderBy(desc(issueHistory.createdAt), desc(issueHistory.id));

    const byGroup = new Map<string, HistoryGroupRow>();
    for (const group of groups) {
      byGroup.set(group.groupId, {
        groupId: group.groupId,
        createdAt: new Date(group.createdAt),
        actor: null,
        changes: [],
      });
    }

    for (const row of rows) {
      const group = byGroup.get(row.groupId);
      if (!group) {
        continue;
      }
      if (row.actorId) {
        group.actor = {
          id: row.actorId,
          displayName: row.actorDisplayName!,
          avatarUrl: row.actorAvatarUrl,
        };
      }
      group.changes.push({
        id: row.id,
        kind: row.kind,
        oldValue: row.oldValue,
        newValue: row.newValue,
        oldRefId: row.oldRefId,
        newRefId: row.newRefId,
      });
    }

    // Порядок групп задаёт первый запрос: сначала новые (US-90).
    return groups.map((group) => byGroup.get(group.groupId)!);
  }

  /** Всего действий по задаче. Минимум одно есть всегда — «Задача создана» (US-90). */
  async countGroups(issueId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(distinct ${issueHistory.groupId})::int` })
      .from(issueHistory)
      .where(eq(issueHistory.issueId, issueId));
    return row?.value ?? 0;
  }
}
