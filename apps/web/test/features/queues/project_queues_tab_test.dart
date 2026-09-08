import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/projects/presentation/tabs/project_queues_tab.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/queue_row.dart';

import '../../helpers/fake_platform.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/pump_widget.dart';

Future<GoRouter> pumpQueuesTab(
  WidgetTester tester, {
  required FakeQueuesRepository queues,
  bool canManage = true,
  RecordingBrowserNavigator? navigator,
}) => pumpWithRouter(
  tester,
  initialLocation: '/projects/sweet-limit',
  overrides: [
    queuesRepositoryProvider.overrideWithValue(queues),
    browserNavigatorProvider.overrideWithValue(
      navigator ?? RecordingBrowserNavigator(),
    ),
  ],
  routes: [
    GoRoute(
      path: '/projects/:slug',
      builder: (context, state) => Scaffold(
        body: ProjectQueuesTab(
          slug: state.pathParameters['slug']!,
          canManage: canManage,
        ),
      ),
    ),
    GoRoute(
      path: '/queues/:key',
      builder: (context, state) =>
          Scaffold(body: Text('очередь ${state.pathParameters['key']}')),
    ),
  ],
);

void main() {
  group('вкладка «Очереди»', () {
    testWidgets('загрузка показывает строки-скелетоны', (tester) async {
      final queues = FakeQueuesRepository()..gate = Completer<void>();

      await pumpQueuesTab(tester, queues: queues);
      await tester.pump();

      expect(find.byType(QueueRow), findsNothing);
      expect(find.text('Разработка'), findsNothing);

      queues.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(QueueRow), findsOneWidget);
    });

    testWidgets('строка очереди показывает ключ, название и счётчик', (
      tester,
    ) async {
      await pumpQueuesTab(
        tester,
        queues: FakeQueuesRepository(
          queues: [
            fakeQueue(openIssueCount: 12),
            fakeQueue(key: 'WEB', name: 'Веб-сайт', openIssueCount: 3),
            fakeQueue(key: 'OPS', name: 'Инфраструктура', openIssueCount: 0),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEV'), findsOneWidget);
      expect(find.text('Разработка'), findsOneWidget);
      // Склонение обязательно: «12 задача» видно всем.
      expect(find.text('12 задач'), findsOneWidget);
      expect(find.text('3 задачи'), findsOneWidget);
      expect(find.text('0 задач'), findsOneWidget);
    });

    testWidgets('клик по строке ведёт в очередь', (tester) async {
      final router = await pumpQueuesTab(
        tester,
        queues: FakeQueuesRepository(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(QueueRow));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/queues/DEV',
      );
    });

    testWidgets('пусто: администратору предлагают создать очередь', (
      tester,
    ) async {
      await pumpQueuesTab(tester, queues: FakeQueuesRepository(queues: []));
      await tester.pumpAndSettle();

      expect(find.text('Очередей пока нет'), findsOneWidget);
      expect(find.text('Создать очередь'), findsOneWidget);
    });

    testWidgets('пусто: участнику советуют попросить администратора', (
      tester,
    ) async {
      await pumpQueuesTab(
        tester,
        queues: FakeQueuesRepository(queues: []),
        canManage: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Очередей пока нет'), findsOneWidget);
      expect(
        find.text('Попросите администратора проекта создать очередь.'),
        findsOneWidget,
      );
      expect(find.text('Создать очередь'), findsNothing);
    });

    testWidgets('у участника нет меню действий со строкой', (tester) async {
      await pumpQueuesTab(
        tester,
        queues: FakeQueuesRepository(),
        canManage: false,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
      expect(find.text('Создать очередь'), findsNothing);
    });

    testWidgets('ошибка предлагает повторить', (tester) async {
      final queues = FakeQueuesRepository()
        ..listFailure = const ApiFailure(kind: ApiFailureKind.network);

      await pumpQueuesTab(tester, queues: queues);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить очереди'), findsOneWidget);

      queues.listFailure = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.byType(QueueRow), findsOneWidget);
    });

    testWidgets('удаление непустой очереди объясняет отказ', (tester) async {
      // Сервер отвечает 409: удалить можно только пустую очередь (D-24).
      final queues = FakeQueuesRepository()
        ..removeFailure = const ApiFailure(
          kind: ApiFailureKind.conflict,
          code: 'queue_not_empty',
        );

      await pumpQueuesTab(tester, queues: queues);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Удалить').last);
      await tester.pumpAndSettle();

      expect(find.text('Очередь не пуста'), findsOneWidget);
      expect(
        find.textContaining('Сначала удалите задачи очереди'),
        findsOneWidget,
      );
      expect(queues.removedQueues, isEmpty);
    });
  });
}
