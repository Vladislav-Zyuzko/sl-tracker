import { ForbiddenException, Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/index.js';
import { clampLimit } from '../common/index.js';
import { MentionsRepository } from '../mentions/index.js';
import { IssueAccessService } from './issue-access.service.js';

/** Подсказка `@` — короткий список: длиннее десяти строк в неё всё равно не влезает. */
export const MENTION_SUGGESTIONS_DEFAULT_LIMIT = 10;
export const MENTION_SUGGESTIONS_MAX_LIMIT = 20;

export interface MentionSuggestion {
  id: string;
  displayName: string;
  email: string;
  avatarUrl: string | null;
}

/**
 * Подсказка упоминаний (US-74, D-41).
 *
 * Здесь два независимых ограничения, и оба обязательны:
 *  1. **выборка идёт только по участникам проекта задачи**. Подсказка, показывающая
 *     всех пользователей трекера, раскрыла бы состав организации любому участнику
 *     любого проекта: достаточно ввести `@а` и посмотреть, кто выпадет
 *     (ADR-0006, п. 6);
 *  2. **спрашивать может только тот, кто вообще создаёт тексты**. Читатель не пишет
 *     ни комментариев, ни описаний, значит и упоминать не может (D-29) — 403.
 *     Заодно это закрывает перебор состава проекта из роли, которой он не нужен.
 *
 * Ограничение частоты стоит на маршруте: подсказка — это поиск, а поиск без лимита
 * это бесплатный перебор.
 */
@Injectable()
export class MentionSuggestionsService {
  constructor(
    private readonly access: IssueAccessService,
    private readonly mentions: MentionsRepository,
  ) {}

  async suggest(
    issueKey: string,
    actor: AuthenticatedUser,
    options: { query?: string; limit?: number },
  ): Promise<MentionSuggestion[]> {
    const context = await this.access.require(issueKey, actor);
    if (context.role === 'reader') {
      throw new ForbiddenException({
        code: 'mention_forbidden',
        message: 'У вас нет прав упоминать участников в этом проекте',
      });
    }

    return this.mentions.suggest({
      projectId: context.detail.projectId,
      query: options.query,
      limit: clampLimit(
        options.limit,
        MENTION_SUGGESTIONS_DEFAULT_LIMIT,
        MENTION_SUGGESTIONS_MAX_LIMIT,
      ),
    });
  }
}
