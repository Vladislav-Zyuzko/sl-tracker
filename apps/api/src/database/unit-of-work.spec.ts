import { describe, expect, it } from '@jest/globals';
import type { Database } from './database.types.js';
import { UnitOfWork, afterCommit } from './unit-of-work.js';

/**
 * Транзакция, ведущая себя как настоящая: тело выполняется, при исключении
 * изменения «откатываются», то есть наружу уходит та же ошибка.
 */
function fakeDb(): Database {
  return {
    transaction: async <T>(fn: (tx: object) => Promise<T>): Promise<T> => fn({ tx: true }),
  } as unknown as Database;
}

describe('UnitOfWork: действия после коммита', () => {
  it('выполняются после того, как транзакция завершилась', async () => {
    const order: string[] = [];
    const uow = new UnitOfWork(fakeDb());

    await uow.transaction(async (tx) => {
      afterCommit(tx, () => {
        order.push('после коммита');
      });
      order.push('внутри транзакции');
      return Promise.resolve();
    });

    // Порядок здесь и есть суть: событие, ушедшее раньше COMMIT, обгоняет свои данные.
    expect(order).toEqual(['внутри транзакции', 'после коммита']);
  });

  it('сохраняют порядок регистрации', async () => {
    const order: number[] = [];
    const uow = new UnitOfWork(fakeDb());

    await uow.transaction(async (tx) => {
      for (const n of [1, 2, 3]) {
        afterCommit(tx, () => {
          order.push(n);
        });
      }
      return Promise.resolve();
    });

    expect(order).toEqual([1, 2, 3]);
  });

  it('не выполняются при откате транзакции', async () => {
    const ran: string[] = [];
    const uow = new UnitOfWork(fakeDb());

    await expect(
      uow.transaction(async (tx) => {
        afterCommit(tx, () => {
          ran.push('не должно случиться');
        });
        await Promise.resolve();
        throw new Error('откат');
      }),
    ).rejects.toThrow('откат');

    expect(ran).toEqual([]);
  });

  it('ошибка отложенного действия не роняет транзакцию: данные уже записаны', async () => {
    const uow = new UnitOfWork(fakeDb());

    const result = await uow.transaction(async (tx) => {
      afterCommit(tx, () => {
        throw new Error('Redis недоступен');
      });
      return Promise.resolve('записано');
    });

    expect(result).toBe('записано');
  });

  it('вне транзакции действие выполняется само: откладывать нечего', async () => {
    const ran: string[] = [];
    const db = fakeDb();

    afterCommit(db, () => {
      ran.push('сразу');
    });

    // Немедленный путь асинхронный — иначе он бы менял порядок вызывающего кода.
    await Promise.resolve();
    await Promise.resolve();
    expect(ran).toEqual(['сразу']);
  });

  it('регистрация после выхода из транзакции идёт немедленным путём', async () => {
    const ran: string[] = [];
    const uow = new UnitOfWork(fakeDb());

    let escaped: Parameters<Parameters<typeof uow.transaction>[0]>[0] | null = null;
    await uow.transaction(async (tx) => {
      escaped = tx;
      return Promise.resolve();
    });

    afterCommit(escaped!, () => {
      ran.push('сразу');
    });
    await Promise.resolve();
    await Promise.resolve();
    expect(ran).toEqual(['сразу']);
  });
});
