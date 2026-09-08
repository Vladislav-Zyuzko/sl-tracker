import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';

import '../../helpers/fake_queue_repositories.dart';

void main() {
  ProviderContainer containerWith(FakeIssuesRepository repository) {
    final container = ProviderContainer(
      overrides: [issuesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  final query = QueueIssuesQuery(queueKey: 'DEV');

  test('первая страница приходит с ролью и счётчиком', () async {
    final repository = FakeIssuesRepository(
      issues: [for (var i = 1; i <= 120; i++) fakeIssueRow(key: 'DEV-$i')],
      role: IssueListDtoRole.member,
    );
    final container = containerWith(repository);

    final page = await container.read(queueIssuesProvider(query).future);

    expect(page.items, hasLength(50));
    expect(page.total, 120);
    expect(page.role, SLRole.member);
    expect(page.canEdit, isTrue);
    expect(page.hasMore, isTrue);
  });

  test('роли нет в ответе — считаем читателем', () async {
    final repository = FakeIssuesRepository(
      issues: [fakeIssueRow(key: 'DEV-1')],
    );
    final container = containerWith(repository);

    final page = await container.read(queueIssuesProvider(query).future);

    expect(page.role, SLRole.reader);
    expect(page.canEdit, isFalse);
  });

  test('догрузка добавляет строки, а не заменяет их', () async {
    final repository = FakeIssuesRepository(
      issues: [for (var i = 1; i <= 120; i++) fakeIssueRow(key: 'DEV-$i')],
      role: IssueListDtoRole.admin,
    );
    final container = containerWith(repository);
    await container.read(queueIssuesProvider(query).future);

    await container.read(queueIssuesProvider(query).notifier).loadMore();

    final page = container.read(queueIssuesProvider(query)).value!;
    expect(page.items, hasLength(100));
    expect(page.items.first.key, 'DEV-1');
    expect(page.items.last.key, 'DEV-100');
  });

  test('сорвавшаяся догрузка не роняет уже загруженные строки', () async {
    final repository = FakeIssuesRepository(
      issues: [for (var i = 1; i <= 120; i++) fakeIssueRow(key: 'DEV-$i')],
      role: IssueListDtoRole.admin,
    )..loadMoreFailure = const ApiFailure(kind: ApiFailureKind.network);
    final container = containerWith(repository);
    await container.read(queueIssuesProvider(query).future);

    await container.read(queueIssuesProvider(query).notifier).loadMore();

    final page = container.read(queueIssuesProvider(query)).value!;
    expect(page.items, hasLength(50));
    expect(page.loadMoreFailed, isTrue);
    expect(page.isLoadingMore, isFalse);

    // «Повторить» после починки сети добирает страницу.
    repository.loadMoreFailure = null;
    await container.read(queueIssuesProvider(query).notifier).retryLoadMore();

    expect(
      container.read(queueIssuesProvider(query)).value!.items,
      hasLength(100),
    );
  });

  test('фильтр по статусу уходит на сервер ключами', () async {
    final repository = FakeIssuesRepository(
      issues: [
        fakeIssueRow(key: 'DEV-1'),
        fakeIssueRow(key: 'DEV-2', statusKey: 'open', statusName: 'Открыт'),
      ],
      role: IssueListDtoRole.admin,
    );
    final container = containerWith(repository);

    final filtered = QueueIssuesQuery(
      queueKey: 'DEV',
      statusKeys: const ['open'],
      sort: IssueSort.newest,
    );
    final page = await container.read(queueIssuesProvider(filtered).future);

    expect(repository.requestedStatusKeys.single, ['open']);
    expect(repository.requestedSorts.single, IssueSort.newest);
    expect(page.items.single.key, 'DEV-2');
    expect(page.total, 1);
  });

  test('смена статуса применяется сразу', () async {
    final repository = FakeIssuesRepository(
      issues: [fakeIssueRow(key: 'DEV-1')],
      role: IssueListDtoRole.admin,
    );
    final container = containerWith(repository);
    await container.read(queueIssuesProvider(query).future);

    final closed = fakeStatuses().last;
    final future = container
        .read(queueIssuesProvider(query).notifier)
        .changeStatus('DEV-1', closed);

    // До ответа сервера строка уже показывает новый статус.
    expect(
      container.read(queueIssuesProvider(query)).value!.items.single.status.key,
      'closed',
    );

    await future;

    expect(
      container.read(queueIssuesProvider(query)).value!.items.single.status.key,
      'closed',
    );
  });

  test('отказ сервера возвращает прежний статус', () async {
    final repository = FakeIssuesRepository(
      issues: [fakeIssueRow(key: 'DEV-1')],
      role: IssueListDtoRole.admin,
    )..changeStatusFailure = const ApiFailure(kind: ApiFailureKind.forbidden);
    final container = containerWith(repository);
    await container.read(queueIssuesProvider(query).future);

    await expectLater(
      container
          .read(queueIssuesProvider(query).notifier)
          .changeStatus('DEV-1', fakeStatuses().last),
      throwsA(isA<ApiFailure>()),
    );

    final page = container.read(queueIssuesProvider(query)).value!;
    expect(page.items.single.status.key, 'in_progress');
  });
}
