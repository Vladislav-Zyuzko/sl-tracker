import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';
import 'package:sl_tracker_web/features/profile/presentation/profile_screen.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/notification_setting_row.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/theme_mode_section.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_owner_badge.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';

import '../../helpers/fake_notification_repositories.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран профиля с готовой сессией.
Future<void> pumpProfile(
  WidgetTester tester, {
  required FakeNotificationsRepository notifications,
  MeResponseDto? user,
  Size windowSize = const Size(1280, 800),
}) async {
  await pumpWithProviders(
    tester,
    const SLToastHost(child: ProfileScreen()),
    windowSize: windowSize,
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(notifications),
      signedIn(user: user),
    ],
  );

  await tester.pump();
  await tester.pump();
}

void main() {
  group('экран профиля', () {
    testWidgets('данные из Яндекс ID показаны текстом и объяснены баннером', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(),
        user: fakeMe(
          displayName: 'Анна Иванова',
          email: 'anna@example.com',
          isInstanceOwner: false,
        ),
      );

      expect(find.text('Анна Иванова'), findsOneWidget);
      expect(find.text('anna@example.com'), findsOneWidget);
      expect(
        find.text('Имя, email и аватар приходят из вашего аккаунта Яндекса'),
        findsOneWidget,
      );
      // Не отключённые поля ввода, а текст: править их нельзя никогда.
      expect(find.byType(TextField), findsNothing);
      // Адрес выделяется мышью — его копируют.
      expect(find.byType(SelectionArea), findsAtLeast(1));
    });

    testWidgets('владелец трекера получает бейдж и пояснение к нему', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(),
        user: fakeMe(isInstanceOwner: true),
      );

      expect(find.byType(SLOwnerBadge), findsOneWidget);
      expect(find.text('Владелец трекера'), findsOneWidget);
      expect(
        find.textContaining('Прав внутри проектов это не даёт'),
        findsOneWidget,
      );
    });

    testWidgets('пустое имя из Яндекс ID заменяется адресом', (tester) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(),
        user: fakeMe(displayName: '  ', email: 'ivan@example.com'),
      );

      expect(find.text('ivan@example.com'), findsAtLeast(1));
    });

    testWidgets('шесть настроек в порядке спеки и от первого лица', (
      tester,
    ) async {
      await pumpProfile(tester, notifications: FakeNotificationsRepository());

      expect(find.byType(NotificationSettingRow), findsNWidgets(6));
      expect(find.text('Присылать уведомления, когда:'), findsOneWidget);

      final labels = tester
          .widgetList<NotificationSettingRow>(
            find.byType(NotificationSettingRow),
          )
          .map((row) => row.label)
          .toList();

      expect(labels.first, 'Меня назначили исполнителем задачи');
      // Упоминание стоит перед комментарием: US-104 требует, чтобы упоминание
      // приходило независимо от комментариев.
      expect(
        labels.indexOf('Меня упомянули в тексте'),
        lessThan(
          labels.indexOf(
            'Появился комментарий к задаче, на которую я подписан',
          ),
        ),
      );
      expect(labels.last, 'В проект вступил новый участник');
    });

    testWidgets('переключение оптимистично: тумблер меняется сразу', (
      tester,
    ) async {
      final repository = FakeNotificationsRepository();
      await pumpProfile(tester, notifications: repository);

      final switches = find.byType(SLSwitch);
      expect(tester.widget<SLSwitch>(switches.first).value, isTrue);

      await tester.tap(switches.first);
      await tester.pump();

      expect(tester.widget<SLSwitch>(switches.first).value, isFalse);
      await tester.pumpAndSettle();
      expect(repository.lastUpdate, (
        NotificationSettingDtoType.issueAssigned,
        false,
      ));
    });

    testWidgets('клик по строке переключает тумблер целиком', (tester) async {
      final repository = FakeNotificationsRepository();
      await pumpProfile(tester, notifications: repository);

      await tester.tap(
        find.text('Меня упомянули в тексте'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(repository.lastUpdate, (
        NotificationSettingDtoType.issueMentioned,
        false,
      ));
    });

    testWidgets('ошибка сохранения возвращает тумблер и объясняет', (
      tester,
    ) async {
      final repository = FakeNotificationsRepository(
        updateFailure: const ApiFailure(kind: ApiFailureKind.server),
      );
      await pumpProfile(tester, notifications: repository);

      await tester.tap(find.byType(SLSwitch).first);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SLSwitch>(find.byType(SLSwitch).first).value,
        isTrue,
      );
      expect(find.text('Не удалось сохранить настройку'), findsOneWidget);
      expect(find.text('Повторить'), findsAtLeast(1));
    });

    testWidgets('все типы отключены — предупреждение, но не запрет', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(
          settings: fakeSettings(enabled: false),
        ),
      );

      expect(find.text('Все уведомления отключены'), findsOneWidget);
      expect(
        find.textContaining('Вы не узнаете о назначенных задачах'),
        findsOneWidget,
      );
    });

    testWidgets('ошибка настроек не роняет блок «кто я»', (tester) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(
          settingsFailure: const ApiFailure(kind: ApiFailureKind.network),
        ),
      );

      expect(find.text('Анна Петрова'), findsOneWidget);
      expect(find.text('Не удалось загрузить настройки'), findsOneWidget);
      expect(find.byType(NotificationSettingRow), findsNothing);
    });

    testWidgets('скелетон настроек повторяет шесть строк', (tester) async {
      final repository = FakeNotificationsRepository();
      await pumpWithProviders(
        tester,
        const SLToastHost(child: ProfileScreen()),
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          signedIn(),
        ],
      );

      expect(find.byType(ProfileSettingsSkeleton), findsOneWidget);

      await tester.pump();
      await tester.pump();
      expect(find.byType(ProfileSettingsSkeleton), findsNothing);
    });

    testWidgets('секция оформления стоит между уведомлениями и сессией', (
      tester,
    ) async {
      await pumpProfile(tester, notifications: FakeNotificationsRepository());

      expect(find.byType(ThemeModeSection), findsOneWidget);
      expect(find.text('ОФОРМЛЕНИЕ'), findsOneWidget);

      final notificationsTitle = tester.getTopLeft(find.text('УВЕДОМЛЕНИЯ'));
      final appearanceTitle = tester.getTopLeft(find.text('ОФОРМЛЕНИЕ'));
      final sessionTitle = tester.getTopLeft(find.text('СЕССИЯ'));

      expect(notificationsTitle.dy, lessThan(appearanceTitle.dy));
      expect(appearanceTitle.dy, lessThan(sessionTitle.dy));
    });

    testWidgets('на телефоне кнопка выхода занимает всю ширину', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        notifications: FakeNotificationsRepository(),
        windowSize: const Size(400, 900),
      );

      expect(find.text('Выйти'), findsOneWidget);
      // Аватар уменьшается и встаёт над именем.
      expect(find.text('Анна Петрова'), findsOneWidget);
    });
  });
}
