import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_screen.dart';
import 'package:sl_tracker_web/features/notifications/presentation/widgets/notification_row.dart';
import 'package:sl_tracker_web/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

import '../../helpers/fake_notification_repositories.dart';
import '../../helpers/fake_platform.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает центр уведомлений внутри роутера: экран уводит на задачу,
/// и проверять надо именно адрес.
Future<GoRouter> pumpNotifications(
  WidgetTester tester, {
  required FakeNotificationsRepository notifications,
  RecordingBrowserNavigator? navigator,
  Size windowSize = const Size(1280, 800),
}) async {
  final router = await pumpWithRouter(
    tester,
    initialLocation: '/notifications',
    windowSize: windowSize,
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/issues/:key',
        builder: (context, state) => Text(
          'задача ${state.pathParameters['key']} '
          'комментарий ${state.uri.queryParameters['comment'] ?? '—'}',
        ),
      ),
      GoRoute(path: '/me', builder: (context, state) => const Text('профиль')),
      GoRoute(
        path: '/projects/:slug',
        builder: (context, state) => Text(
          'проект ${state.pathParameters['slug']} '
          'вкладка ${state.uri.queryParameters['tab'] ?? '—'}',
        ),
      ),
    ],
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(notifications),
      signedIn(),
      if (navigator != null)
        browserNavigatorProvider.overrideWithValue(navigator),
    ],
  );

  await tester.pump();
  await tester.pump();

  return router;
}

void main() {
  group('центр уведомлений', () {
    testWidgets('скелетон повторяет геометрию строки, а не спиннер', (
      tester,
    ) async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification()],
      );
      await pumpWithRouter(
        tester,
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          signedIn(),
        ],
      );

      // Первый кадр: данных ещё нет.
      expect(find.byType(NotificationsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byType(SLSkeletonBox),
        findsAtLeast(NotificationsSkeleton.rows),
      );

      await tester.pump();
      await tester.pump();
    });

    testWidgets('строка собирается из типа, инициатора и снимка события', (
      tester,
    ) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(
              id: 'n1',
              type: NotificationDtoType.issueStatusChanged,
              payload: const NotificationPayloadDto(
                issueKey: 'DEV-38',
                fromStatusName: 'в работе',
                toStatusName: 'ревью',
              ),
              issueKey: 'DEV-38',
            ),
            fakeNotification(
              id: 'n2',
              type: NotificationDtoType.issueCommented,
              commentId: 'c1',
              payload: const NotificationPayloadDto(
                issueKey: 'DEV-35',
                excerpt: '**Поправил** отступы, посмотри',
              ),
              issueKey: 'DEV-35',
            ),
          ],
        ),
      );

      // Статусы — в кавычках и с заглавной, как в глоссарии.
      expect(
        find.textContaining('перевёл', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('«В работе»', findRichText: true),
        findsOneWidget,
      );
      // Разметка Markdown в превью не показывается символами (US-102).
      expect(find.text('Поправил отступы, посмотри'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
    });

    testWidgets('клик по строке уводит к задаче и гасит точку', (tester) async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1', issueKey: 'DEV-42')],
      );
      final router = await pumpNotifications(tester, notifications: repository);

      await tester.tap(find.byType(NotificationRow));
      await tester.pumpAndSettle();

      expect(repository.markedRead, ['n1']);
      expect(router.state.uri.path, '/issues/DEV-42');
    });

    testWidgets('якорь на комментарий уезжает в адрес задачи', (tester) async {
      final router = await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(
              id: 'n1',
              type: NotificationDtoType.issueMentioned,
              commentId: 'c-7',
              issueKey: 'DEV-42',
            ),
          ],
        ),
      );

      await tester.tap(find.byType(NotificationRow));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/issues/DEV-42');
      expect(router.state.uri.queryParameters['comment'], 'c-7');
    });

    testWidgets('удалённый комментарий открывает задачу и говорит об этом', (
      tester,
    ) async {
      final router = await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(
              id: 'n1',
              type: NotificationDtoType.issueCommented,
              issueKey: 'DEV-42',
              payload: const NotificationPayloadDto(
                issueKey: 'DEV-42',
                excerpt: 'что-то было',
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.byType(NotificationRow));
      await tester.pumpAndSettle();

      expect(find.text('Комментарий удалён'), findsOneWidget);
      expect(router.state.uri.path, '/issues/DEV-42');
    });

    testWidgets('новый участник ведёт на список участников проекта', (
      tester,
    ) async {
      final router = await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(
              id: 'n1',
              type: NotificationDtoType.projectMemberJoined,
              issueKey: null,
              projectSlug: 'sweet-limit',
              payload: const NotificationPayloadDto(
                projectSlug: 'sweet-limit',
                projectName: 'Sweet Limit',
                memberName: 'Анна Иванова',
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.byType(NotificationRow));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/projects/sweet-limit');
      expect(router.state.uri.queryParameters['tab'], 'members');
    });

    testWidgets('уведомлению без цели нажимать нечего, и это видно сразу', (
      tester,
    ) async {
      // Ни ключа задачи наверху, ни в снимке: задачу удалили.
      final repository = FakeNotificationsRepository(
        items: [
          fakeNotification(
            issueKey: null,
            payload: const NotificationPayloadDto(issueTitle: 'Что-то было'),
          ),
        ],
      );

      await pumpNotifications(tester, notifications: repository);

      // Строка остаётся в ленте: пропажа записей задним числом хуже, чем
      // неактивная строка (`notifications.md`).
      expect(find.byType(NotificationRow), findsOneWidget);
      expect(find.text('недоступно'), findsOneWidget);

      // Основное решение — не дать нажать, а не объяснять после нажатия.
      final ink = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(NotificationRow),
          matching: find.byType(InkWell),
        ),
      );
      expect(ink.onTap, isNull);
      expect(ink.onLongPress, isNull);

      // И в порядок фокуса такая строка не попадает.
      expect(
        tester
            .widgetList<Focus>(
              find.descendant(
                of: find.byType(NotificationRow),
                matching: find.byType(Focus),
              ),
            )
            .where((node) => node.canRequestFocus),
        isEmpty,
      );
    });

    testWidgets(
      'тост-страховка говорит про задачу и проект, а не про источник',
      (tester) async {
        final repository = FakeNotificationsRepository(
          items: [
            fakeNotification(
              issueKey: null,
              payload: const NotificationPayloadDto(issueTitle: 'Что-то было'),
            ),
          ],
        );

        await pumpNotifications(tester, notifications: repository);

        // Нажатие всё же произошло — клавиатурой из устаревшего состояния.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(
          find.text('Открывать нечего: задача или проект удалены'),
          findsOneWidget,
        );
        expect(find.textContaining('Источник уведомления'), findsNothing);
      },
    );

    testWidgets('«отметить все» гасит точки и убирает саму кнопку', (
      tester,
    ) async {
      final repository = FakeNotificationsRepository(
        items: [
          fakeNotification(id: 'n1'),
          fakeNotification(id: 'n2'),
        ],
      );
      await pumpNotifications(tester, notifications: repository);

      expect(find.text('Отметить все как прочитанные'), findsOneWidget);

      await tester.tap(find.text('Отметить все как прочитанные'));
      await tester.pumpAndSettle();

      expect(repository.markAllCalls, 1);
      // Строки остаются на месте — исчезает только кнопка и счётчик.
      expect(find.byType(NotificationRow), findsNWidgets(2));
      expect(find.text('Отметить все как прочитанные'), findsNothing);
    });

    testWidgets('`Shift + a` делает то же самое с клавиатуры', (tester) async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1')],
      );
      await pumpNotifications(tester, notifications: repository);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(repository.markAllCalls, 1);
    });

    testWidgets('стрелки ведут курсор, Enter открывает', (tester) async {
      final router = await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(id: 'n1', issueKey: 'DEV-1'),
            fakeNotification(id: 'n2', issueKey: 'DEV-2'),
          ],
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/issues/DEV-2');
    });

    testWidgets('пустая лента объясняет, что здесь появится', (tester) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(),
      );

      expect(find.text('Уведомлений нет'), findsOneWidget);
      expect(find.byType(NotificationRow), findsNothing);
    });

    testWidgets('ошибка загрузки предлагает повтор', (tester) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          listFailure: const ApiFailure(kind: ApiFailureKind.network),
        ),
      );

      expect(find.text('Не удалось загрузить уведомления'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('отключённые типы объясняются баннером со ссылкой', (
      tester,
    ) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [fakeNotification()],
          settings: fakeSettings(enabled: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Все типы уведомлений отключены'), findsOneWidget);

      // Кнопка ведёт туда, где это можно исправить.
      await tester.tap(find.text('Настроить'));
      await tester.pumpAndSettle();
      expect(find.text('профиль'), findsOneWidget);
    });

    testWidgets('на телефоне строка выше, а кнопка становится иконкой', (
      tester,
    ) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(items: [fakeNotification()]),
        windowSize: const Size(400, 800),
      );

      expect(find.text('Отметить все как прочитанные'), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      final row = tester.widget<NotificationRow>(find.byType(NotificationRow));
      expect(row.compact, isTrue);
    });

    testWidgets('сотня уведомлений не строится целиком', (tester) async {
      await pumpNotifications(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            for (var index = 0; index < 100; index++)
              fakeNotification(id: 'n$index', issueKey: 'DEV-$index'),
          ],
        ),
      );

      // Виртуализация: на экране 800 px высоты строк по 56 влезает
      // заметно меньше сотни.
      expect(
        tester.widgetList<NotificationRow>(find.byType(NotificationRow)).length,
        lessThan(30),
      );
    });
  });
}
