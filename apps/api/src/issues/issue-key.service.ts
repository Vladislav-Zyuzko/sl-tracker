import { Injectable, NotFoundException } from '@nestjs/common';
import { eq, sql } from 'drizzle-orm';
import type { Executor } from '../database/index.js';
import { queues } from '../database/schema/index.js';

/** Выданный номер и собранный из него ключ задачи. */
export interface AllocatedIssueKey {
  queueId: string;
  /** Ключ очереди, например `DEV`. */
  queueKey: string;
  /** Номер внутри очереди, начиная с 1. */
  number: number;
  /** Полный ключ задачи, например `DEV-42`. */
  key: string;
}

/** Ключ очереди: латинские заглавные и цифры, 2–10 символов, первый символ — буква. */
export const QUEUE_KEY_PATTERN = /^[A-Z][A-Z0-9]{1,9}$/;

/** Ключ задачи целиком. В URL регистр не важен, поэтому разбор регистронезависим. */
const ISSUE_KEY_PATTERN = /^([A-Za-z][A-Za-z0-9]{1,9})-(\d{1,10})$/;

/**
 * Выдача номеров и ключей задач (ADR-0004).
 *
 * Номер выдаётся инкрементом счётчика в строке очереди **в той же транзакции**,
 * что и вставка задачи:
 *
 *   UPDATE queues SET last_issue_number = last_issue_number + 1
 *    WHERE id = $1 RETURNING last_issue_number, key
 *
 * `UPDATE` берёт строчную блокировку, поэтому параллельные транзакции выстраиваются
 * в очередь на этой строке и получают разные номера. `SELECT max(number) + 1`
 * категорически запрещён: два одновременных создания дают одинаковый ключ.
 *
 * Номер удалённой задачи не переиспользуется: счётчик не уменьшается при удалении.
 * Иначе старая ссылка `DEV-42` откроет совершенно другую задачу — и человек этого
 * не заметит, что хуже, чем «страница не найдена».
 *
 * Откат транзакции, наоборот, возвращает номер: счётчик — обычная колонка, и UPDATE
 * откатывается вместе со всем остальным. Это отличие от последовательности (sequence),
 * которая после отката оставила бы дыру (ADR-0004, раздел «Альтернативы»).
 */
@Injectable()
export class IssueKeyService {
  /**
   * Выдаёт следующий номер задачи в очереди.
   *
   * Вызывать **только** внутри транзакции, вместе со вставкой задачи: иначе при ошибке
   * вставки номер будет потрачен впустую, а при параллельных вызовах пропадёт смысл
   * блокировки строки.
   */
  async allocate(tx: Executor, queueId: string): Promise<AllocatedIssueKey> {
    const [row] = await tx
      .update(queues)
      .set({ lastIssueNumber: sql`${queues.lastIssueNumber} + 1` })
      .where(eq(queues.id, queueId))
      .returning({ number: queues.lastIssueNumber, key: queues.key });

    if (!row) {
      throw new NotFoundException('Очередь не найдена');
    }

    return {
      queueId,
      queueKey: row.key,
      number: row.number,
      key: IssueKeyService.format(row.key, row.number),
    };
  }

  /** Собирает ключ задачи. Хранится и отображается в верхнем регистре. */
  static format(queueKey: string, issueNumber: number): string {
    return `${queueKey.toUpperCase()}-${issueNumber}`;
  }

  /**
   * Разбирает ключ задачи из адреса. Регистр не важен: `/issues/dev-42` и `/issues/DEV-42`
   * открывают одну и ту же задачу (ADR-0004). Возвращает `null`, если это не ключ.
   */
  static parse(raw: string): { queueKey: string; number: number; key: string } | null {
    const match = ISSUE_KEY_PATTERN.exec(raw.trim());
    if (!match) {
      return null;
    }

    const queueKey = match[1]!.toUpperCase();
    const number = Number(match[2]);
    if (!Number.isSafeInteger(number) || number < 1) {
      return null;
    }

    return { queueKey, number, key: IssueKeyService.format(queueKey, number) };
  }

  /** Нормализует ключ очереди к хранимому виду и проверяет формат. */
  static normalizeQueueKey(raw: string): string | null {
    const normalized = raw.trim().toUpperCase();
    return QUEUE_KEY_PATTERN.test(normalized) ? normalized : null;
  }
}
