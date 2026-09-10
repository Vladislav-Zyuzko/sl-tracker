import { isForeignKeyViolation } from '../common/index.js';
import { issueNotFound } from './issue-access.service.js';

/**
 * Хвост имени внешнего ключа на `issues.id`: Drizzle строит их как
 * `<таблица>_issue_id_issues_id_fk` — так подписаны связи `comments`, `issue_links`,
 * `attachments`, `mentions` и `issue_history`.
 */
const ISSUE_FK_SUFFIX = '_issue_id_issues_id_fk';

/**
 * Запись в задачу, которую в этот момент могут удалять.
 *
 * Между проверкой прав (она читает задачу) и самой вставкой задача может исчезнуть:
 * администратор удаляет её, пока участник пишет комментарий. Это не сбой сервера,
 * а обычная гонка «проверил и сделал», и ответ на неё — тот же 404, что и на
 * «задачи нет»: другого осмысленного исхода у клиента нет.
 *
 * Почему обёртка, а не проверка «а задача ещё на месте?» перед вставкой: такая проверка
 * ничего не гарантирует — между ней и вставкой окно остаётся. Единственный, кто знает
 * правду, — база, и она сообщает её нарушением внешнего ключа.
 *
 * Изменение задачи (`PATCH`) этого не требует: `update … returning` сам видит, что
 * строки нет, и отвечает 404.
 */
export async function whileIssueExists<T>(write: () => Promise<T>): Promise<T> {
  try {
    return await write();
  } catch (error) {
    if (isForeignKeyViolation(error, ISSUE_FK_SUFFIX)) {
      throw issueNotFound();
    }
    throw error;
  }
}
