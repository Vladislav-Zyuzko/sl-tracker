import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/issues/data/comments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_history_providers.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';

const _failure = ApiFailure(kind: ApiFailureKind.server, statusCode: 500);

Future<(ProviderContainer, FakeCommentsRepository)> boot({
  List<CommentDto>? items,
  bool canComment = true,
  String? earlierCursor,
}) async {
  final repository = FakeCommentsRepository(
    items: items ?? [fakeComment(id: 'c1')],
    canComment: canComment,
  )..earlierCursor = earlierCursor;

  final container = ProviderContainer(
    overrides: [commentsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await container.read(issueCommentsProvider('DEV-42').future);

  return (container, repository);
}

void main() {
  group('лента комментариев', () {
    test('порядок и права приезжают из ответа', () async {
      final (container, _) = await boot(canComment: false);
      final page = container.read(issueCommentsProvider('DEV-42')).value!;

      expect(page.items, hasLength(1));
      expect(page.canComment, isFalse);
    });

    test('отправленный комментарий виден сразу, до ответа сервера', () async {
      final (container, _) = await boot();
      final notifier = container.read(
        issueCommentsProvider('DEV-42').notifier,
      );

      final pending = notifier.send('Новый текст', fakeIssueUser());

      expect(
        container.read(issueCommentsProvider('DEV-42')).value!.pending,
        hasLength(1),
      );

      await pending;
      final page = container.read(issueCommentsProvider('DEV-42')).value!;
      expect(page.pending, isEmpty);
      expect(page.items.last.body, 'Новый текст');
      expect(page.total, 2);
    });

    test('при ошибке отправки текст остаётся на экране', () async {
      final (container, repository) = await boot();
      repository.createFailure = _failure;

      await container
          .read(issueCommentsProvider('DEV-42').notifier)
          .send('Важный текст', fakeIssueUser());

      final page = container.read(issueCommentsProvider('DEV-42')).value!;
      expect(page.pending, hasLength(1));
      expect(page.pending.single.failed, isTrue);
      // Главное требование US-71: набранное не теряется.
      expect(page.pending.single.body, 'Важный текст');
    });

    test('повтор после ошибки доводит комментарий до ленты', () async {
      final (container, repository) = await boot();
      final notifier = container.read(
        issueCommentsProvider('DEV-42').notifier,
      );

      repository.createFailure = _failure;
      await notifier.send('Текст', fakeIssueUser());

      repository.createFailure = null;
      final localId = container
          .read(issueCommentsProvider('DEV-42'))
          .value!
          .pending
          .single
          .localId;

      await notifier.retrySend(localId);

      final page = container.read(issueCommentsProvider('DEV-42')).value!;
      expect(page.pending, isEmpty);
      expect(page.items.last.body, 'Текст');
    });

    test('«Удалить» убирает неотправленный комментарий', () async {
      final (container, repository) = await boot();
      final notifier = container.read(
        issueCommentsProvider('DEV-42').notifier,
      );

      repository.createFailure = _failure;
      await notifier.send('Черновик', fakeIssueUser());

      notifier.discardPending(
        container
            .read(issueCommentsProvider('DEV-42'))
            .value!
            .pending
            .single
            .localId,
      );

      expect(
        container.read(issueCommentsProvider('DEV-42')).value!.pending,
        isEmpty,
      );
    });

    test('более ранние встают в начало ленты', () async {
      final (container, repository) = await boot(
        items: [fakeComment(id: 'new', body: 'Новый')],
        earlierCursor: 'cursor-1',
      );

      repository.items = [fakeComment(id: 'old', body: 'Старый')];
      await container
          .read(issueCommentsProvider('DEV-42').notifier)
          .loadEarlier();

      final page = container.read(issueCommentsProvider('DEV-42')).value!;
      expect(page.items.first.body, 'Старый');
      expect(page.items.last.body, 'Новый');
      expect(page.hasEarlier, isFalse);
    });

    test('сорвавшаяся подгрузка не роняет уже прочитанное', () async {
      final (container, repository) = await boot(
        items: [fakeComment(id: 'c1')],
        earlierCursor: 'cursor-1',
      );

      repository.listFailure = _failure;
      await container
          .read(issueCommentsProvider('DEV-42').notifier)
          .loadEarlier();

      final page = container.read(issueCommentsProvider('DEV-42')).value!;
      expect(page.items, hasLength(1));
      expect(page.loadEarlierFailed, isTrue);
    });

    test('удаление возвращает комментарий на своё место при отказе', () async {
      final (container, repository) = await boot(
        items: [
          fakeComment(id: 'c1', body: 'Первый'),
          fakeComment(id: 'c2', body: 'Второй'),
          fakeComment(id: 'c3', body: 'Третий'),
        ],
      );

      repository.removeFailure = _failure;

      await expectLater(
        container.read(issueCommentsProvider('DEV-42').notifier).remove('c2'),
        throwsA(isA<ApiFailure>()),
      );

      final bodies = container
          .read(issueCommentsProvider('DEV-42'))
          .value!
          .items
          .map((item) => item.body)
          .toList();

      // Именно на своё место, а не в конец ленты.
      expect(bodies, ['Первый', 'Второй', 'Третий']);
    });
  });

  group('история изменений', () {
    test('точка «свежие изменения» зажигается за последний час', () async {
      final repository = FakeIssuesRepository()
        ..historyGroups = [
          fakeHistoryGroup(
            createdAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 10),
            ),
          ),
        ];

      final container = ProviderContainer(
        overrides: [issuesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final page = await container.read(issueHistoryProvider('DEV-42').future);
      expect(page.hasRecentChanges(), isTrue);
    });

    test('старая история точку не зажигает', () async {
      final repository = FakeIssuesRepository()
        ..historyGroups = [
          fakeHistoryGroup(createdAt: DateTime.utc(2026, 1, 1)),
        ];

      final container = ProviderContainer(
        overrides: [issuesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final page = await container.read(issueHistoryProvider('DEV-42').future);
      expect(page.hasRecentChanges(now: DateTime.utc(2026, 2, 12)), isFalse);
    });
  });
}
