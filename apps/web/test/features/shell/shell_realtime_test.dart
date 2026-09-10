import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';
import 'package:sl_tracker_web/features/shell/presentation/app_shell.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_offline_bar.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_counter_badge.dart';

import '../../helpers/fake_notification_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/fake_realtime.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает оболочку с живой связью на подставном транспорте.
Future<FakeRealtimeSocketFactory> pumpShell(
  WidgetTester tester, {
  required FakeNotificationsRepository notifications,
}) async {
  final realtime = FakeRealtimeSocketFactory();

  await pumpWithRouter(
    tester,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Text('экран')),
        ],
      ),
    ],
    overrides: [
      realtimeSocketFactoryProvider.overrideWithValue(realtime),
      notificationsRepositoryProvider.overrideWithValue(notifications),
      issuesRepositoryProvider.overrideWithValue(FakeIssuesRepository()),
      signedIn(),
    ],
  );

  await tester.pump();
  await tester.pump();

  return realtime;
}

/// Останавливает живую связь окончательным кодом закрытия.
///
/// Без этого в конце теста остаётся такт прикладного `ping`, и тестовый
/// биндинг справедливо считает висящий таймер ошибкой. В приложении этот же
/// код означает «сессии больше нет», и цикл переподключения на нём
/// останавливается — ровно то, что здесь нужно.
Future<void> stopRealtime(
  WidgetTester tester,
  FakeRealtimeSocketFactory realtime,
) async {
  realtime.last.emitClose(RealtimeCloseCodes.accessRevoked);
  await tester.pump();
  await tester.pump();
}

void main() {
  group('оболочка и живая связь', () {
    testWidgets('счётчик непрочитанных виден в шапке и меняется событием', (
      tester,
    ) async {
      final realtime = await pumpShell(
        tester,
        notifications: FakeNotificationsRepository(
          items: [
            fakeNotification(id: 'n1'),
            fakeNotification(id: 'n2'),
          ],
        ),
      );

      expect(find.byType(SLCounterBadge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      realtime.last.emitReady();
      await tester.pump();
      realtime.last.emitEvent(
        topic: RealtimeTopics.me,
        event: RealtimeEvents.notificationCreated,
        actorId: 'someone-else',
        data: {'id': 'n3', 'type': 'issue_mentioned', 'unreadCount': 5},
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('5'), findsOneWidget);

      await stopRealtime(tester, realtime);
    });

    testWidgets('обрыв показывает полосу офлайна, возврат — тост', (
      tester,
    ) async {
      final realtime = await pumpShell(
        tester,
        notifications: FakeNotificationsRepository(),
      );

      realtime.last.emitReady();
      await tester.pump();

      // Пока связь есть, полосы нет.
      expect(
        tester.widget<SLOfflineBar>(find.byType(SLOfflineBar)).visible,
        isFalse,
      );

      realtime.last.emitClose(1006);
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<SLOfflineBar>(find.byType(SLOfflineBar)).visible,
        isTrue,
      );
      expect(find.text(SLOfflineBar.message), findsOneWidget);

      // Ждём переподключение: задержка 1 с плюс случайная добавка.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      realtime.last.emitReady();
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<SLOfflineBar>(find.byType(SLOfflineBar)).visible,
        isFalse,
      );
      expect(find.text('Соединение восстановлено'), findsOneWidget);

      await stopRealtime(tester, realtime);
    });
  });
}
