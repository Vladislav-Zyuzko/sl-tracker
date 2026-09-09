import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';

/// Поднимает контроллер задачи на подставном репозитории.
Future<(ProviderContainer, FakeIssuesRepository)> boot({
  IssueDto? issue,
}) async {
  final repository = FakeIssuesRepository()..issue = issue ?? fakeIssue();
  final container = ProviderContainer(
    overrides: [issuesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await container.read(issueProvider('DEV-42').future);

  return (container, repository);
}

void main() {
  group('правки полей задачи', () {
    test('смена статуса применяется сразу, до ответа сервера', () async {
      final (container, repository) = await boot();
      final notifier = container.read(issueProvider('DEV-42').notifier);

      const target = IssueStatusRef(
        id: 'status-closed',
        key: 'closed',
        name: 'Закрыт',
        category: IssueStatusCategory.done,
      );

      final pending = notifier.changeStatus(target);

      // Ещё до `await`: значение уже на экране.
      expect(
        container.read(issueProvider('DEV-42')).value!.status.key,
        'closed',
      );

      await pending;
      expect(repository.patches, contains('status'));
    });

    test('при ошибке возвращается прежнее значение поля', () async {
      final (container, repository) = await boot();
      final notifier = container.read(issueProvider('DEV-42').notifier);

      repository.patchFailure = const ApiFailure(
        kind: ApiFailureKind.server,
        statusCode: 500,
      );

      await expectLater(
        notifier.changePriority(20),
        throwsA(isA<ApiFailure>()),
      );

      // Откат именно поля: приоритет вернулся к исходным 80.
      expect(
        container.read(issueProvider('DEV-42')).value!.priority.value,
        80,
      );
    });

    test('откат не стирает соседнее поле, изменённое тем временем', () async {
      final (container, repository) = await boot();
      final notifier = container.read(issueProvider('DEV-42').notifier);

      repository.patchFailure = const ApiFailure(
        kind: ApiFailureKind.server,
        statusCode: 500,
      );

      final failing = notifier.changePriority(20);

      // Пока запрос «летит», название поменял кто-то ещё — и оно обязано
      // пережить откат приоритета.
      final current = container.read(issueProvider('DEV-42')).value!;
      container.read(issueProvider('DEV-42').notifier).state = AsyncData(
        current.copyWith(title: 'Новое название извне'),
      );

      await expectLater(failing, throwsA(isA<ApiFailure>()));

      final result = container.read(issueProvider('DEV-42')).value!;
      expect(result.priority.value, 80);
      expect(result.title, 'Новое название извне');
    });

    test('снятие исполнителя доезжает как очистка поля', () async {
      final (container, repository) = await boot(
        issue: fakeIssue(assignee: fakeIssueUser(id: 'user-2')),
      );

      await container
          .read(issueProvider('DEV-42').notifier)
          .changeAssignee(null);

      expect(repository.patches, contains('assignee'));
      expect(container.read(issueProvider('DEV-42')).value!.assignee, isNull);
    });

    test('снятие оценки сложности возвращает «не оценено»', () async {
      final (container, _) = await boot(
        issue: fakeIssue(storyPoints: IssueDtoStoryPoints.value8),
      );

      await container
          .read(issueProvider('DEV-42').notifier)
          .changeStoryPoints(null);

      expect(
        container.read(issueProvider('DEV-42')).value!.storyPoints,
        isNull,
      );
    });

    test('повтор того же значения запроса не порождает', () async {
      final (container, repository) = await boot();

      await container
          .read(issueProvider('DEV-42').notifier)
          .changePriority(80);

      expect(repository.patches, isEmpty);
    });

    test('пустое название не сохраняется', () async {
      final (container, repository) = await boot();

      await container
          .read(issueProvider('DEV-42').notifier)
          .changeTitle('   ');

      expect(repository.patches, isEmpty);
    });

    test('удаление ссылки убирает строку сразу и возвращает при отказе', () async {
      final link = IssueLinkDto(
        id: 'link-1',
        url: 'https://example.com/spec',
        title: 'Спека',
        createdBy: fakeIssueUser(),
        createdAt: DateTime.utc(2026, 2, 12),
      );

      final (container, repository) = await boot(
        issue: fakeIssue(links: [link]),
      );
      repository.patchFailure = const ApiFailure(
        kind: ApiFailureKind.server,
        statusCode: 500,
      );

      await expectLater(
        container.read(issueProvider('DEV-42').notifier).removeLink('link-1'),
        throwsA(isA<ApiFailure>()),
      );

      expect(container.read(issueProvider('DEV-42')).value!.links, hasLength(1));
    });
  });

  group('подсказка участников', () {
    test('email второй строкой нужен только при совпадении имён', () {
      final unique = [
        fakeSuggestion(id: 'a', displayName: 'Анна Иванова'),
        fakeSuggestion(id: 'b', displayName: 'Пётр Смирнов'),
      ];
      expect(ambiguousNames(unique), isEmpty);

      final duplicates = [
        fakeSuggestion(id: 'a', displayName: 'Анна Иванова'),
        fakeSuggestion(id: 'b', displayName: 'анна иванова'),
      ];
      expect(ambiguousNames(duplicates), contains('анна иванова'));
    });
  });
}
