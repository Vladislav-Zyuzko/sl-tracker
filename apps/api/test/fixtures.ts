import { randomUUID } from 'node:crypto';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import * as schema from '../src/database/schema/index.js';
import { DEFAULT_STATUSES } from '../src/queues/default-statuses.js';

type Db = NodePgDatabase<typeof schema>;

export interface QueueFixture {
  userId: string;
  projectId: string;
  queueId: string;
  queueKey: string;
  openStatusId: string;
}

/** Полностью очищает тестовую базу между прогонами. */
export async function truncateAll(db: Db): Promise<void> {
  await db.execute(sql`
    truncate table
      issue_history, mentions, attachments, issue_links, comments, notifications,
      notification_settings, issues, statuses, queues, queue_keys, invitations,
      project_members, projects, project_slugs, sessions, access_entries, identities, users
    restart identity cascade
  `);
}

/** Создаёт пользователя, проект и очередь с пятью статусами. */
export async function seedQueue(db: Db, queueKey: string): Promise<QueueFixture> {
  const [user] = await db
    .insert(schema.users)
    .values({ displayName: 'Тестовый пользователь', email: `${randomUUID()}@example.com` })
    .returning({ id: schema.users.id });

  const slug = `project-${randomUUID().slice(0, 8)}`;
  const projectId = randomUUID();

  // Короткое имя бронируется до вставки проекта: внешний ключ projects.slug смотрит сюда.
  await db.insert(schema.projectSlugs).values({ slug, projectId: null, isCurrent: false });
  await db
    .insert(schema.projects)
    .values({ id: projectId, name: 'Тестовый проект', slug, createdByUserId: user!.id });
  await db
    .update(schema.projectSlugs)
    .set({ projectId, isCurrent: true })
    .where(sql`${schema.projectSlugs.slug} = ${slug}`);

  await db.insert(schema.projectMembers).values({ projectId, userId: user!.id, role: 'admin' });

  // Ключ очереди бронируется до вставки очереди: внешний ключ queues.key смотрит сюда.
  const queueId = randomUUID();
  await db.insert(schema.queueKeys).values({ key: queueKey, queueId: null });
  await db.insert(schema.queues).values({
    id: queueId,
    projectId,
    key: queueKey,
    name: 'Тестовая очередь',
    createdByUserId: user!.id,
  });
  await db
    .update(schema.queueKeys)
    .set({ queueId })
    .where(sql`${schema.queueKeys.key} = ${queueKey}`);

  const statuses = await db
    .insert(schema.statuses)
    .values(DEFAULT_STATUSES.map((status) => ({ ...status, queueId })))
    .returning({ id: schema.statuses.id, key: schema.statuses.key });

  const open = statuses.find((status) => status.key === 'open');

  return {
    userId: user!.id,
    projectId,
    queueId,
    queueKey,
    openStatusId: open!.id,
  };
}

/** Пользователь трекера. Роль в проектах выдаётся отдельно. */
export async function seedUser(
  db: Db,
  displayName: string,
  email = `${randomUUID()}@example.com`,
): Promise<{ id: string; displayName: string; email: string }> {
  const [user] = await db
    .insert(schema.users)
    .values({ displayName, email })
    .returning({ id: schema.users.id });
  return { id: user!.id, displayName, email };
}

/** Запись списка доступа: без неё человек не вошёл бы в трекер (ADR-0006). */
export async function grantTrackerAccess(
  db: Db,
  email: string,
  source: 'config' | 'manual' | 'invitation' = 'manual',
): Promise<void> {
  await db
    .insert(schema.accessEntries)
    .values({ email: email.toLowerCase(), source })
    .onConflictDoNothing();
}

/** Проект с одним администратором. Короткое имя бронируется до вставки проекта. */
export async function seedProject(
  db: Db,
  options: { name: string; slug: string; adminId: string; description?: string | null },
): Promise<{ id: string; slug: string }> {
  const projectId = randomUUID();
  await db
    .insert(schema.projectSlugs)
    .values({ slug: options.slug, projectId: null, isCurrent: false });
  await db.insert(schema.projects).values({
    id: projectId,
    name: options.name,
    description: options.description ?? null,
    slug: options.slug,
    createdByUserId: options.adminId,
  });
  await db
    .update(schema.projectSlugs)
    .set({ projectId, isCurrent: true })
    .where(sql`${schema.projectSlugs.slug} = ${options.slug}`);
  await db
    .insert(schema.projectMembers)
    .values({ projectId, userId: options.adminId, role: 'admin' });

  return { id: projectId, slug: options.slug };
}

export async function addProjectMember(
  db: Db,
  projectId: string,
  userId: string,
  role: 'admin' | 'member' | 'reader',
): Promise<void> {
  await db.insert(schema.projectMembers).values({ projectId, userId, role });
}

/** Очередь с пятью статусами по умолчанию внутри уже созданного проекта. */
export async function seedQueueInProject(
  db: Db,
  projectId: string,
  queueKey: string,
  createdByUserId: string,
): Promise<{ queueId: string; statusIds: Record<string, string> }> {
  const queueId = randomUUID();
  await db.insert(schema.queueKeys).values({ key: queueKey, queueId: null });
  await db.insert(schema.queues).values({
    id: queueId,
    projectId,
    key: queueKey,
    name: `Очередь ${queueKey}`,
    createdByUserId,
  });
  await db
    .update(schema.queueKeys)
    .set({ queueId })
    .where(sql`${schema.queueKeys.key} = ${queueKey}`);

  const statuses = await db
    .insert(schema.statuses)
    .values(DEFAULT_STATUSES.map((status) => ({ ...status, queueId })))
    .returning({ id: schema.statuses.id, key: schema.statuses.key });

  const statusIds: Record<string, string> = {};
  for (const status of statuses) {
    statusIds[status.key] = status.id;
  }

  return { queueId, statusIds };
}

/** Задача с уже выданным номером: эндпоинтов создания задач ещё нет. */
export async function seedIssue(
  db: Db,
  options: {
    queueId: string;
    queueKey: string;
    number: number;
    title: string;
    statusId: string;
    authorId: string;
    assigneeId?: string | null;
    priority?: number;
  },
): Promise<{ id: string; key: string }> {
  const key = `${options.queueKey}-${options.number}`;
  const [issue] = await db
    .insert(schema.issues)
    .values({
      queueId: options.queueId,
      number: options.number,
      key,
      title: options.title,
      statusId: options.statusId,
      priority: options.priority ?? 50,
      authorId: options.authorId,
      createdByUserId: options.authorId,
      assigneeId: options.assigneeId ?? null,
    })
    .returning({ id: schema.issues.id });

  return { id: issue!.id, key };
}
