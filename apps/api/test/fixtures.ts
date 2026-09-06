import { randomUUID } from 'node:crypto';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import * as schema from '../src/database/schema/index.js';

type Db = NodePgDatabase<typeof schema>;

/** Пять статусов по умолчанию (glossary.md, раздел 5). Пока создаются тестом. */
const DEFAULT_STATUSES = [
  { key: 'open', name: 'Открыт', category: 'open' as const, position: 1 },
  { key: 'in_progress', name: 'В работе', category: 'in_progress' as const, position: 2 },
  { key: 'review', name: 'Ревью', category: 'in_progress' as const, position: 3 },
  { key: 'testing', name: 'Тестирование', category: 'in_progress' as const, position: 4 },
  { key: 'closed', name: 'Закрыт', category: 'done' as const, position: 5 },
];

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
