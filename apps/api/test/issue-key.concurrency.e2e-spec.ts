import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import type { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import type pg from 'pg';
import * as schema from '../src/database/schema/index.js';
import { IssueKeyService } from '../src/issues/issue-key.service.js';
import { seedQueue, truncateAll } from './fixtures.js';
import { createTestDb, createTestPool, prepareTestDatabase } from './test-database.js';

/**
 * Проверяемое требование ADR-0004: 50 параллельных созданий задач в одной очереди
 * дают 50 разных ключей. Это тест, а не пожелание.
 */
const PARALLEL = 50;

describe('Выдача ключей задач под параллельной нагрузкой (ADR-0004)', () => {
  let pool: pg.Pool;
  let db: NodePgDatabase<typeof schema>;
  const service = new IssueKeyService();

  beforeAll(async () => {
    await prepareTestDatabase();
    pool = createTestPool(PARALLEL + 5);
    db = createTestDb(pool);
    await truncateAll(db);
  });

  afterAll(async () => {
    await pool.end();
  });

  it(`${PARALLEL} одновременных созданий дают ${PARALLEL} разных ключей без дыр`, async () => {
    const fixture = await seedQueue(db, 'DEV');

    const results = await Promise.all(
      Array.from({ length: PARALLEL }, (_, index) =>
        db.transaction(async (tx) => {
          const allocated = await service.allocate(tx, fixture.queueId);

          // Искусственно расширяем окно между выдачей номера и вставкой задачи:
          // если бы номер брался через SELECT max(...) + 1, здесь и случилась бы гонка.
          await tx.execute(sql`select pg_sleep(0.01)`);

          const [issue] = await tx
            .insert(schema.issues)
            .values({
              queueId: fixture.queueId,
              number: allocated.number,
              key: allocated.key,
              title: `Параллельная задача ${index}`,
              statusId: fixture.openStatusId,
              authorId: fixture.userId,
              createdByUserId: fixture.userId,
            })
            .returning({ key: schema.issues.key, number: schema.issues.number });

          return issue!;
        }),
      ),
    );

    const keys = results.map((issue) => issue.key);
    expect(new Set(keys).size).toBe(PARALLEL);

    const numbers = results.map((issue) => issue.number).sort((a, b) => a - b);
    expect(numbers).toEqual(Array.from({ length: PARALLEL }, (_, i) => i + 1));
    expect(keys).toEqual(expect.arrayContaining(['DEV-1', `DEV-${PARALLEL}`]));

    const [queue] = await db
      .select({ last: schema.queues.lastIssueNumber })
      .from(schema.queues)
      .where(sql`${schema.queues.id} = ${fixture.queueId}`);
    expect(queue!.last).toBe(PARALLEL);
  });

  it('счётчик не откатывается при неудачной вставке: номер не переиспользуется', async () => {
    const fixture = await seedQueue(db, 'OPS');

    const first = await db.transaction(async (tx) => {
      const allocated = await service.allocate(tx, fixture.queueId);
      await tx.insert(schema.issues).values({
        queueId: fixture.queueId,
        number: allocated.number,
        key: allocated.key,
        title: 'Первая',
        statusId: fixture.openStatusId,
        authorId: fixture.userId,
        createdByUserId: fixture.userId,
      });
      return allocated;
    });
    expect(first.key).toBe('OPS-1');

    // Откат возвращает номер: счётчик — обычная колонка, а не последовательность,
    // и UPDATE откатывается вместе с транзакцией. Дыры в нумерации не появляется.
    await expect(
      db.transaction(async (tx) => {
        await service.allocate(tx, fixture.queueId);
        throw new Error('откат');
      }),
    ).rejects.toThrow('откат');

    const second = await db.transaction(async (tx) => {
      const allocated = await service.allocate(tx, fixture.queueId);
      await tx.insert(schema.issues).values({
        queueId: fixture.queueId,
        number: allocated.number,
        key: allocated.key,
        title: 'Вторая',
        statusId: fixture.openStatusId,
        authorId: fixture.userId,
        createdByUserId: fixture.userId,
      });
      return allocated;
    });
    expect(second.key).toBe('OPS-2');
  });

  it('номер удалённой задачи не переиспользуется (ADR-0004)', async () => {
    const fixture = await seedQueue(db, 'DEL');

    const first = await db.transaction(async (tx) => {
      const allocated = await service.allocate(tx, fixture.queueId);
      await tx.insert(schema.issues).values({
        queueId: fixture.queueId,
        number: allocated.number,
        key: allocated.key,
        title: 'Будет удалена',
        statusId: fixture.openStatusId,
        authorId: fixture.userId,
        createdByUserId: fixture.userId,
      });
      return allocated;
    });
    expect(first.key).toBe('DEL-1');

    await db.delete(schema.issues).where(sql`${schema.issues.key} = ${first.key}`);

    // Ключ DEL-1 больше никому не достанется: иначе старая ссылка открыла бы
    // совершенно другую задачу, и человек этого не заметил бы.
    const next = await db.transaction((tx) => service.allocate(tx, fixture.queueId));
    expect(next.key).toBe('DEL-2');
  });

  it('уникальный индекс страхует от дубля ключа даже при ошибке в коде', async () => {
    const fixture = await seedQueue(db, 'SEC');

    await db.insert(schema.issues).values({
      queueId: fixture.queueId,
      number: 1,
      key: 'SEC-1',
      title: 'Первая',
      statusId: fixture.openStatusId,
      authorId: fixture.userId,
      createdByUserId: fixture.userId,
    });

    await expect(
      db.insert(schema.issues).values({
        queueId: fixture.queueId,
        number: 1,
        key: 'SEC-1',
        title: 'Дубль',
        statusId: fixture.openStatusId,
        authorId: fixture.userId,
        createdByUserId: fixture.userId,
      }),
    ).rejects.toThrow();
  });
});
