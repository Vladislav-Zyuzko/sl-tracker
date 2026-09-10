import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_router.dart';
import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/features/access/presentation/access_denied_screen.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_screen.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_screen.dart';
import 'package:sl_tracker_web/features/invites/presentation/invite_accept_screen.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_screen.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_screen.dart';
import 'package:sl_tracker_web/features/profile/presentation/profile_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_screen.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_screen.dart';
import 'package:sl_tracker_web/features/shell/presentation/app_shell.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

import '../helpers/pump_widget.dart';

/// Поднимает приложение сразу по адресу [location].
///
/// Это и есть проверка глубокой ссылки: экран открывается напрямую, без
/// перехода с главной, — ровно так же, как при заходе по ссылке из чата
/// и при F5.
Future<GoRouter> pumpAt(
  WidgetTester tester,
  String location, {
  Size windowSize = const Size(1280, 800),
}) async {
  useWindowSize(tester, windowSize);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  router.go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: SLThemeData.light, routerConfig: router),
    ),
  );

  // Не pumpAndSettle: шиммер скелетона крутится бесконечно и никогда
  // не «успокоится». Двух кадров хватает, чтобы роутер построил экран.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return router;
}

void main() {
  group('маршруты внутри оболочки', () {
    testWidgets('корень открывает список проектов', (tester) async {
      await pumpAt(tester, AppRoutes.projects);

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(ProjectsScreen), findsOneWidget);
    });

    testWidgets('прямая ссылка на задачу открывает экран задачи', (
      tester,
    ) async {
      await pumpAt(tester, '/issues/SL-123');

      final screen = tester.widget<IssueScreen>(find.byType(IssueScreen));

      expect(screen.issueKey, 'SL-123');
      expect(screen.anchorCommentId, isNull);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('ссылка на комментарий доносит якорь до экрана', (
      tester,
    ) async {
      // Так выглядит переход из уведомления об упоминании (US-102, US-104):
      // задача плюс идентификатор комментария в адресе.
      await pumpAt(tester, '/issues/SL-123?comment=c-42');

      final screen = tester.widget<IssueScreen>(find.byType(IssueScreen));

      expect(screen.issueKey, 'SL-123');
      expect(screen.anchorCommentId, 'c-42');
    });

    testWidgets('ключ задачи не по формату ведёт на «не найдено»', (
      tester,
    ) async {
      await pumpAt(tester, '/issues/не-ключ');

      expect(find.byType(IssueScreen), findsNothing);
      expect(find.text('Задача не найдена'), findsOneWidget);
    });

    testWidgets('прямая ссылка на очередь передаёт ключ', (tester) async {
      await pumpAt(tester, '/queues/SL');

      expect(
        tester
            .widget<QueueIssuesScreen>(find.byType(QueueIssuesScreen))
            .queueKey,
        'SL',
      );
    });

    testWidgets('прямая ссылка на проект передаёт slug', (tester) async {
      await pumpAt(tester, '/projects/sweet-limit');

      expect(
        tester.widget<ProjectScreen>(find.byType(ProjectScreen)).slug,
        'sweet-limit',
      );
    });

    testWidgets('прямая ссылка на центр уведомлений открывает его', (
      tester,
    ) async {
      await pumpAt(tester, AppRoutes.notifications);

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('вкладка проекта читается из адреса: ?tab=members', (
      tester,
    ) async {
      await pumpAt(tester, '/projects/sweet-limit?tab=members');

      expect(
        tester.widget<ProjectScreen>(find.byType(ProjectScreen)).initialTab,
        'members',
      );
      expect(ProjectScreen.tabOf('members'), ProjectTab.members);
      // Незнакомая вкладка — опечатка в ссылке, а не ошибка: экран
      // открывается на вкладке по умолчанию.
      expect(ProjectScreen.tabOf('нет-такой'), isNull);
    });

    testWidgets('профиль и список доступа — разные экраны', (tester) async {
      await pumpAt(tester, AppRoutes.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);

      await pumpAt(tester, AppRoutes.access);
      expect(find.byType(AccessListScreen), findsOneWidget);
    });
  });

  group('маршруты вне оболочки', () {
    testWidgets('вход открывается без оболочки', (tester) async {
      await pumpAt(tester, AppRoutes.login);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('закрытый доступ открывается без оболочки', (tester) async {
      await pumpAt(tester, AppRoutes.accessDenied);

      expect(find.byType(AccessDeniedScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('приглашение принимает валидный токен', (tester) async {
      const token = 'abcdefghijklmnop1234';
      await pumpAt(tester, '/invite/$token');

      expect(
        tester
            .widget<InviteAcceptScreen>(find.byType(InviteAcceptScreen))
            .token,
        token,
      );
    });

    testWidgets('короткий токен приглашения не принимается', (tester) async {
      await pumpAt(tester, '/invite/short');

      expect(find.byType(InviteAcceptScreen), findsNothing);
      expect(find.text('Ссылка приглашения не подходит'), findsOneWidget);
    });
  });

  group('редиректы и неизвестные адреса', () {
    testWidgets('/projects приводится к корню', (tester) async {
      final router = await pumpAt(tester, '/projects');

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.projects,
      );
      expect(find.byType(ProjectsScreen), findsOneWidget);
    });

    testWidgets('/profile приводится к /me', (tester) async {
      final router = await pumpAt(tester, '/profile');

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.profile,
      );
    });

    testWidgets('/access приводится к /me/access', (tester) async {
      final router = await pumpAt(tester, '/access');

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.access,
      );
    });

    testWidgets('неизвестный путь показывает экран «не найдено»', (
      tester,
    ) async {
      await pumpAt(tester, '/no-such-page');

      expect(find.text('Страница не найдена'), findsOneWidget);
    });
  });

  group('построение адресов', () {
    test('помощники собирают канонические пути', () {
      expect(AppRoutes.issuePath('SL-123'), '/issues/SL-123');
      expect(AppRoutes.queuePath('SL'), '/queues/SL');
      expect(AppRoutes.projectPath('sweet-limit'), '/projects/sweet-limit');
      expect(AppRoutes.invitePath('token'), '/invite/token');
    });

    test('проверки параметров отсекают мусор', () {
      expect(RouteParams.issueKey.hasMatch('SL-123'), isTrue);
      expect(RouteParams.issueKey.hasMatch('sl-123'), isFalse);
      expect(RouteParams.issueKey.hasMatch('SL123'), isFalse);
      expect(RouteParams.queueKey.hasMatch('SL'), isTrue);
      expect(RouteParams.queueKey.hasMatch('SL-1'), isFalse);
      expect(RouteParams.projectSlug.hasMatch('sweet-limit'), isTrue);
      expect(RouteParams.projectSlug.hasMatch('Sweet Limit'), isFalse);
    });
  });
}
