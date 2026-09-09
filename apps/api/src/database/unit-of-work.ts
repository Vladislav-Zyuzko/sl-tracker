import { Inject, Injectable, Logger } from '@nestjs/common';
import { DB } from './database.tokens.js';
import type { Database, Executor, Transaction } from './database.types.js';

/** Действие, которое должно выполниться **после** фиксации транзакции. */
export type AfterCommitHook = () => void | Promise<void>;

/**
 * Отложенные действия текущей транзакции.
 *
 * `WeakMap`, а не поле в объекте транзакции: тип транзакции принадлежит Drizzle,
 * дописывать в него свои поля нельзя. Ключ живёт ровно столько, сколько сам объект
 * транзакции, — утечки нет.
 */
const pendingHooks = new WeakMap<object, AfterCommitHook[]>();

/**
 * Отложить действие до фиксации транзакции.
 *
 * Зачем это нужно: рассылка события по WebSocket **обязана** уходить после `COMMIT`.
 * Опубликованное изнутри транзакции событие обгоняет её: клиент приходит за данными,
 * которых ещё нет, а при откате получает сигнал о том, чего не случилось. Баг при этом
 * плавающий — он зависит от того, кто успел раньше.
 *
 * Если исполнитель — не транзакция, а само соединение, откладывать нечего: запрос уже
 * зафиксирован, и действие выполняется сразу. Такой вызов не ждут — он не должен
 * задерживать и тем более ронять вызывающий код.
 */
export function afterCommit(executor: Executor, hook: AfterCommitHook): void {
  const hooks = pendingHooks.get(executor);
  if (hooks) {
    hooks.push(hook);
    return;
  }

  void Promise.resolve()
    .then(hook)
    .catch((error: unknown) => {
      Logger.warn(`Действие после коммита не выполнено: ${message(error)}`, UnitOfWork.name);
    });
}

/**
 * Транзакция с действиями «после коммита».
 *
 * Тонкая обёртка над `db.transaction`, но обязательная: в самом Drizzle точки
 * «транзакция зафиксирована» нет, а она нужна всем, кто рассылает события.
 *
 * Ошибка отложенного действия **не отменяет** транзакцию и не ломает запрос: данные
 * уже записаны, а недоставленное живое обновление клиент восполнит обычным запросом.
 */
@Injectable()
export class UnitOfWork {
  private readonly logger = new Logger(UnitOfWork.name);

  constructor(@Inject(DB) private readonly db: Database) {}

  async transaction<T>(fn: (tx: Transaction) => Promise<T>): Promise<T> {
    const hooks: AfterCommitHook[] = [];

    const result = await this.db.transaction(async (tx) => {
      pendingHooks.set(tx, hooks);
      try {
        return await fn(tx);
      } finally {
        // Регистрировать действия после выхода из транзакции уже нельзя:
        // объект транзакции мёртв, и такой вызов должен пойти немедленным путём.
        pendingHooks.delete(tx);
      }
    });

    for (const hook of hooks) {
      try {
        await hook();
      } catch (error) {
        this.logger.warn(`Действие после коммита не выполнено: ${message(error)}`);
      }
    }

    return result;
  }
}

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
