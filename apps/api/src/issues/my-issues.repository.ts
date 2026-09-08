import { Inject, Injectable } from '@nestjs/common';
import { and, desc, eq, ilike, ne, or, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import { issues, projectMembers, projects, queues, statuses } from '../database/schema/index.js';
import type { StatusCategory } from '../queues/status-category.js';

export type { StatusCategory };

/** Строка сайдбара: ключ, тема, приоритет, статус (US-81). */
export interface MyIssueRow {
  key: string;
  title: string;
  priority: number;
  statusKey: string;
  statusName: string;
  statusCategory: StatusCategory;
  updatedAt: Date;
  id: string;
}

export interface MyIssuesOptions {
  userId: string;
  limit: number;
  /** Подстрока в названии или в ключе (US-82, D-20). */
  query?: string;
  after?: { priority: number; updatedAt: Date; id: string };
}

/**
 * Активные задачи текущего пользователя (US-81).
 *
 * Условие ровно одно и оно определено продуктом: пользователь — исполнитель,
 * а категория статуса не `done`. Категория берётся из `statuses`, потому что
 * статусы — данные, а не enum в коде (ADR-0003): у команды может появиться свой
 * статус «Отменено» в категории `done`, и список обязан это учесть сам.
 *
 * Членство в проекте проверяется join'ом: исключённый из проекта перестаёт быть
 * исполнителем (D-31), но полагаться на одну лишь очистку поля здесь нельзя —
 * список задач не должен зависеть от аккуратности другого сценария.
 */
@Injectable()
export class MyIssuesRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  async list(options: MyIssuesOptions): Promise<MyIssueRow[]> {
    const conditions = [
      eq(issues.assigneeId, options.userId),
      ne(statuses.category, 'done'),
      eq(projectMembers.userId, options.userId),
    ];

    if (options.query) {
      // Поиск серверный: клиенту фильтровать этот список запрещено (D-20).
      const pattern = `%${escapeLike(options.query)}%`;
      conditions.push(or(ilike(issues.title, pattern), ilike(issues.key, pattern))!);
    }

    if (options.after) {
      conditions.push(
        sql`(issues.priority, issues.updated_at, issues.id)
            < (${options.after.priority}, ${options.after.updatedAt}, ${options.after.id}::uuid)`,
      );
    }

    return (
      this.db
        .select({
          id: issues.id,
          key: issues.key,
          title: issues.title,
          priority: issues.priority,
          statusKey: statuses.key,
          statusName: statuses.name,
          statusCategory: statuses.category,
          updatedAt: issues.updatedAt,
        })
        .from(issues)
        .innerJoin(statuses, eq(statuses.id, issues.statusId))
        .innerJoin(queues, eq(queues.id, issues.queueId))
        .innerJoin(projects, eq(projects.id, queues.projectId))
        .innerJoin(projectMembers, eq(projectMembers.projectId, projects.id))
        .where(and(...conditions))
        // Приоритет ↓, затем недавно изменённые (US-81); `id` — чтобы порядок был строгим.
        .orderBy(desc(issues.priority), desc(issues.updatedAt), desc(issues.id))
        .limit(options.limit)
    );
  }

  /** Число активных задач показывается рядом с заголовком списка (US-81). */
  async count(userId: string): Promise<number> {
    const [row] = await this.db
      .select({ value: sql<number>`count(*)::int` })
      .from(issues)
      .innerJoin(statuses, eq(statuses.id, issues.statusId))
      .innerJoin(queues, eq(queues.id, issues.queueId))
      .innerJoin(projectMembers, eq(projectMembers.projectId, queues.projectId))
      .where(
        and(
          eq(issues.assigneeId, userId),
          ne(statuses.category, 'done'),
          eq(projectMembers.userId, userId),
        ),
      );
    return row?.value ?? 0;
  }
}

/** `%` и `_` из пользовательского ввода не должны становиться шаблоном LIKE. */
function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, (match) => `\\${match}`);
}
