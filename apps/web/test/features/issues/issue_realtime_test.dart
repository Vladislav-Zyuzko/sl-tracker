import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';
import 'package:sl_tracker_web/features/issues/data/comments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_realtime.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/fake_realtime.dart';
import '../../helpers/fake_repositories.dart';

const _issueKey = 'DEV-42';

/// Поднимает живые обновления открытой задачи на подставном транспорте.
Future<
  ({
    ProviderContainer container,
    FakeRealtimeSocketFactory realtime,
    FakeIssuesRepository issues,
    FakeCommentsRepository comments,
  })
>
boot({String currentUserId = 'user-1'}) async {
  final realtime = FakeRealtimeSocketFactory();
  final issues = FakeIssuesRepository()..issue = fakeIssue(key: _issueKey);
  final comments = FakeCommentsRepository(
    items: [fakeComment(id: 'c1', body: 'первый')],
  );

  final container = ProviderContainer(
    overrides: [
      realtimeSocketFactoryProvider.overrideWithValue(realtime),
      issuesRepositoryProvider.overrideWithValue(issues),
      commentsRepositoryProvider.overrideWithValue(comments),
      signedIn(user: fakeMe(id: currentUserId)),
    ],
  );
  addTearDown(container.dispose);

  // Экран задачи держит и задачу, и ленту, и подписку. Именно держит:
  // провайдер живых обновлений самоочищается, и без слушателя подписка
  // снялась бы сразу — как и должна при уходе с экрана.
  container.listen(issueProvider(_issueKey), (_, _) {});
  container.listen(issueCommentsProvider(_issueKey), (_, _) {});
  container.listen(issueRealtimeProvider(_issueKey), (_, _) {});
  await container.read(issueProvider(_issueKey).future);
  await container.read(issueCommentsProvider(_issueKey).future);

  await Future<void>.delayed(Duration.zero);
  realtime.last.emitReady();
  await Future<void>.delayed(Duration.zero);
  realtime.last.emitSubscribed(
    id: RealtimeTopics.issue(_issueKey),
    topic: RealtimeTopics.issue(_issueKey),
  );
  await Future<void>.delayed(Duration.zero);

  return (
    container: container,
    realtime: realtime,
    issues: issues,
    comments: comments,
  );
}

void main() {
  group('живые обновления задачи', () {
    test('подписка уходит на тему задачи', () async {
      final setup = await boot();

      expect(
        setup.realtime.last.commands('subscribe').single['topic'],
        'issue:DEV-42',
      );
    });

    test('чужая правка перечитывает задачу и подсвечивает поле', () async {
      final setup = await boot();
      final before = setup.issues.byKeyCalls;

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.issueUpdated,
        actorId: 'someone-else',
        data: {
          'key': _issueKey,
          'changedFields': ['status'],
        },
      );
      await Future<void>.delayed(Duration.zero);

      final live = setup.container.read(issueRealtimeProvider(_issueKey));
      expect(live.flashingFields, contains(IssueFieldNames.status));

      // Полные данные едут обычным запросом: событие — только сигнал.
      await setup.container.read(issueProvider(_issueKey).future);
      expect(setup.issues.byKeyCalls, greaterThan(before));

      // Подсветка гаснет сама.
      await Future<void>.delayed(const Duration(milliseconds: 320));
      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).flashingFields,
        isEmpty,
      );
    });

    test('своя правка не подсвечивается как внешняя', () async {
      final setup = await boot();

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.issueUpdated,
        actorId: 'user-1',
        data: {
          'key': _issueKey,
          'changedFields': ['status'],
        },
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).flashingFields,
        isEmpty,
      );
    });

    test('чужой комментарий считается для плашки, свой — нет', () async {
      final setup = await boot();

      setup.comments.items = [
        ...setup.comments.items,
        fakeComment(id: 'c2', body: 'второй'),
      ];
      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.commentCreated,
        actorId: 'someone-else',
        data: {'id': 'c2', 'issueKey': _issueKey},
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).newComments,
        1,
      );
      // Лента перечитана обычным запросом.
      expect(
        setup.container
            .read(issueCommentsProvider(_issueKey))
            .requireValue
            .items
            .map((item) => item.id),
        ['c1', 'c2'],
      );

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.commentCreated,
        actorId: 'user-1',
        data: {'id': 'c3', 'issueKey': _issueKey},
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).newComments,
        1,
        reason: 'свой комментарий человек и так видит',
      );

      setup.container
          .read(issueRealtimeProvider(_issueKey).notifier)
          .clearNewComments();
      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).newComments,
        0,
      );
    });

    test('удалённый другим комментарий исчезает из ленты точечно', () async {
      final setup = await boot();

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.commentDeleted,
        actorId: 'someone-else',
        data: {'id': 'c1', 'issueKey': _issueKey},
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.container
            .read(issueCommentsProvider(_issueKey))
            .requireValue
            .items,
        isEmpty,
      );
    });

    test('удаление задачи закрывает экран', () async {
      final setup = await boot();

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: RealtimeEvents.issueDeleted,
        actorId: 'someone-else',
        data: {'key': _issueKey},
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).deleted,
        isTrue,
      );
    });

    test('после переподключения данные перечитываются целиком', () async {
      final setup = await boot();
      final issueCalls = setup.issues.byKeyCalls;

      // Обрыв и восстановление: подписка та же, а события за это время
      // потеряны безвозвратно.
      setup.realtime.last.emitClose(1006);
      await Future<void>.delayed(const Duration(milliseconds: 1700));

      setup.realtime.last
        ..emitReady()
        ..emitSubscribed(
          id: RealtimeTopics.issue(_issueKey),
          topic: RealtimeTopics.issue(_issueKey),
        );
      await Future<void>.delayed(Duration.zero);
      await setup.container.read(issueProvider(_issueKey).future);

      expect(setup.issues.byKeyCalls, greaterThan(issueCalls));
    });

    test('незнакомое событие ничего не ломает и не дёргает сервер', () async {
      final setup = await boot();
      final calls = setup.issues.byKeyCalls;

      setup.realtime.last.emitEvent(
        topic: RealtimeTopics.issue(_issueKey),
        event: 'issue.teleported',
        actorId: 'someone-else',
      );
      await Future<void>.delayed(Duration.zero);

      expect(setup.issues.byKeyCalls, calls);
      expect(
        setup.container.read(issueRealtimeProvider(_issueKey)).deleted,
        isFalse,
      );
    });
  });
}
