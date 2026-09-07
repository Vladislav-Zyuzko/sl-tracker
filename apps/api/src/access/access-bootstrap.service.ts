import { Inject, Injectable, Logger, type OnApplicationBootstrap } from '@nestjs/common';
import { toStorableEmail } from '../common/index.js';
import { ENV, type Env } from '../config/index.js';
import { AccessListRepository } from './access-list.repository.js';

export interface ParsedBootstrapEmails {
  emails: string[];
  /** Сколько значений отброшено как непохожие на адрес. Сами значения в лог не идут. */
  rejected: number;
}

/**
 * Разбирает `ACCESS_LIST_BOOTSTRAP_EMAILS`: адреса через запятую, пробелы и переводы
 * строк допустимы. Дубликаты внутри переменной схлопываются — иначе вставка одной
 * пачкой падает на уникальном индексе.
 */
export function parseBootstrapEmails(raw: string | undefined): ParsedBootstrapEmails {
  if (!raw) {
    return { emails: [], rejected: 0 };
  }

  const unique = new Set<string>();
  let rejected = 0;

  for (const candidate of raw.split(/[,;\s]+/)) {
    if (candidate.length === 0) {
      continue;
    }
    const email = toStorableEmail(candidate);
    if (email) {
      unique.add(email);
    } else {
      rejected += 1;
    }
  }

  return { emails: [...unique], rejected };
}

/**
 * Начальное наполнение списка доступа при старте (ADR-0006, п. 2; US-06).
 *
 * Смысл переменной — только первый запуск: в пустом инстансе иначе некому создать
 * первый проект и некого пригласить. Дальше источник правды — таблица:
 *
 *   - повторный запуск с той же конфигурацией дубликатов не создаёт;
 *   - удаление адреса из переменной запись **не** удаляет — отзыв делается на экране;
 *   - уже существующая запись не переписывается: перезапуск не возвращает снятый
 *     признак владельца и не меняет источник.
 *
 * Адреса — персональные данные, в лог уходит только количество.
 */
@Injectable()
export class AccessBootstrapService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AccessBootstrapService.name);

  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly repository: AccessListRepository,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    await this.run();
  }

  /** Отдельным методом — чтобы тест мог вызвать наполнение повторно и проверить идемпотентность. */
  async run(): Promise<number> {
    const { emails, rejected } = parseBootstrapEmails(this.env.ACCESS_LIST_BOOTSTRAP_EMAILS);

    if (rejected > 0) {
      this.logger.warn(
        `ACCESS_LIST_BOOTSTRAP_EMAILS: ${rejected} значений не похожи на адрес и пропущены`,
      );
    }

    if (emails.length === 0) {
      return 0;
    }

    const inserted = await this.repository.insertBootstrap(emails);
    this.logger.log(
      `Список доступа: в конфигурации ${emails.length} адресов, добавлено новых ${inserted}`,
    );
    return inserted;
  }
}
