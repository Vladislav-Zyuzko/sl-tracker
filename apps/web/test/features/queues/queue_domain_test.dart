import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/features/queues/domain/queue_key.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';

void main() {
  group('QueueKey', () {
    test('ввод приводится к виду ключа', () {
      expect(QueueKey.normalize('dev-1'), 'DEV1');
      expect(QueueKey.normalize('  web  '), 'WEB');
      // Первым символом цифра быть не может — она просто не попадает в ключ.
      expect(QueueKey.normalize('1dev'), 'DEV');
      // Длина обрезается полем, а не ответом сервера.
      expect(QueueKey.normalize('abcdefghijkl'), 'ABCDEFGHIJ');
      expect(QueueKey.normalize('Разработка'), '');
    });

    test('годность ключа проверяется до отправки', () {
      expect(QueueKey.isValid('DEV'), isTrue);
      expect(QueueKey.isValid('D'), isFalse);
      expect(QueueKey.isValid('DEV1'), isTrue);
      expect(QueueKey.isValid('1DEV'), isFalse);
    });

    test('пустое поле не считается ошибкой', () {
      expect(QueueKey.validationError(''), isNull);
      expect(QueueKey.validationError('D'), isNotNull);
      expect(QueueKey.validationError('DEV'), isNull);
    });
  });

  group('IssueSort', () {
    test('незнакомое значение из адреса не роняет экран', () {
      expect(IssueSort.parse('newest'), IssueSort.newest);
      expect(IssueSort.parse('priority'), IssueSort.priority);
      expect(IssueSort.parse('rubbish'), IssueSort.initial);
      expect(IssueSort.parse(null), IssueSort.initial);
    });
  });

  group('QueueIssuesQuery', () {
    test('пустые значения фильтра отбрасываются', () {
      expect(QueueIssuesQuery.parseStatuses(null), isEmpty);
      expect(QueueIssuesQuery.parseStatuses(''), isEmpty);
      expect(QueueIssuesQuery.parseStatuses(','), isEmpty);
      expect(QueueIssuesQuery.parseStatuses('open, review'), [
        'open',
        'review',
      ]);
    });

    test('порядок ключей не создаёт второй запрос', () {
      final a = QueueIssuesQuery(
        queueKey: 'DEV',
        statusKeys: const ['review', 'in_progress'],
      );
      final b = QueueIssuesQuery(
        queueKey: 'DEV',
        statusKeys: const ['in_progress', 'review'],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('повторы схлопываются, фильтр сбрасывается целиком', () {
      final query = QueueIssuesQuery(
        queueKey: 'DEV',
        statusKeys: const ['open', 'open'],
      );

      expect(query.statusKeys, ['open']);
      expect(query.isFiltered, isTrue);
      expect(query.withoutFilters.isFiltered, isFalse);
    });
  });

  group('IssueStatusRef', () {
    test('незнакомый ключ статуса берёт палитру из категории', () {
      const custom = IssueStatusRef(
        key: 'waiting_for_release',
        name: 'Ждёт релиза',
        category: IssueStatusCategory.inProgress,
      );

      expect(custom.palette, IssueStatus.inProgress);
      expect(custom.isDone, isFalse);
    });

    test('известный ключ берёт свою палитру', () {
      const closed = IssueStatusRef(
        key: 'closed',
        name: 'Закрыт',
        category: IssueStatusCategory.done,
      );

      expect(closed.palette, IssueStatus.closed);
      expect(closed.isDone, isTrue);
    });
  });
}
