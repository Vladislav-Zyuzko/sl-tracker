import { NotFoundException } from '@nestjs/common';
import { describe, expect, it } from '@jest/globals';
import { whileIssueExists } from './issue-writes.js';

/** Ошибка драйвера pg: код и имя ограничения — всё, по чему её можно узнать. */
function pgError(code: string, constraint?: string): Error {
  return Object.assign(new Error('insert or update violates foreign key constraint'), {
    code,
    constraint,
  });
}

/** Так ошибку заворачивает Drizzle: наружу видно только «Failed query: …». */
function wrapped(cause: Error): Error {
  return new Error('Failed query: insert into "comments" …', { cause });
}

describe('Запись в задачу, которую могли удалить (DEF-02)', () => {
  it('успешная запись отдаёт свой результат', async () => {
    await expect(whileIssueExists(() => Promise.resolve('готово'))).resolves.toBe('готово');
  });

  it('нарушение внешнего ключа на задачу — это 404, а не 500', async () => {
    const write = () => Promise.reject(pgError('23503', 'comments_issue_id_issues_id_fk'));
    await expect(whileIssueExists(write)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('видит ошибку внутри обёртки Drizzle', async () => {
    const write = () =>
      Promise.reject(wrapped(pgError('23503', 'attachments_issue_id_issues_id_fk')));

    const error = await whileIssueExists(write).catch((caught: unknown) => caught);

    expect(error).toBeInstanceOf(NotFoundException);
    expect((error as NotFoundException).getResponse()).toMatchObject({ code: 'issue_not_found' });
  });

  it('чужой внешний ключ 404-ом не притворяется: исчез автор, а не задача', async () => {
    const write = () => Promise.reject(pgError('23503', 'comments_author_id_users_id_fk'));
    await expect(whileIssueExists(write)).rejects.not.toBeInstanceOf(NotFoundException);
  });

  it('прочие ошибки базы проходят наружу как были', async () => {
    const unique = pgError('23505', 'issues_key_unique');
    await expect(whileIssueExists(() => Promise.reject(unique))).rejects.toBe(unique);
  });

  it('ошибка без кода pg остаётся собой', async () => {
    const boom = new Error('соединение потеряно');
    await expect(whileIssueExists(() => Promise.reject(boom))).rejects.toBe(boom);
  });
});
