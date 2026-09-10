import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_providers.dart';

import '../../helpers/fake_notification_repositories.dart';
import '../../helpers/fake_realtime.dart';
import '../../helpers/fake_repositories.dart';

/// Поднимает контейнер с сессией и подставными репозиториями.
Future<ProviderContainer> buildContainer({
  required FakeNotificationsRepository notifications,
  FakeRealtimeSocketFactory? realtime,
}) async {
  final container = ProviderContainer(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(notifications),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(meResult: fakeMe()),
      ),
      if (realtime != null)
        realtimeSocketFactoryProvider.overrideWithValue(realtime),
    ],
  );
  addTearDown(container.dispose);

  await container.read(sessionControllerProvider.notifier).load();

  return container;
}

void main() {
  group('лента уведомлений', () {
    test(
      'первая порция приносит счётчик непрочитанных вместе с собой',
      () async {
        final repository = FakeNotificationsRepository(
          items: [
            fakeNotification(id: 'n1'),
            fakeNotification(id: 'n2', readAt: DateTime.utc(2026)),
          ],
        );
        final container = await buildContainer(notifications: repository);

        final page = await container.read(notificationsProvider.future);

        expect(page.items, hasLength(2));
        expect(page.unreadCount, 1);
        // Второго запроса ради счётчика не делаем: он приехал в ответе ленты.
        expect(container.read(unreadCountProvider).value, 1);
      },
    );

    test(
      'пометка прочитанным оптимистична и откатывается при ошибке',
      () async {
        final repository = FakeNotificationsRepository(
          items: [fakeNotification(id: 'n1')],
          markReadFailure: const ApiFailure(kind: ApiFailureKind.server),
        );
        final container = await buildContainer(notifications: repository);
        await container.read(notificationsProvider.future);

        final controller = container.read(notificationsProvider.notifier);

        await expectLater(
          controller.markRead('n1'),
          throwsA(isA<ApiFailure>()),
        );

        final page = container.read(notificationsProvider).requireValue;
        expect(page.items.single.readAt, isNull, reason: 'точка вернулась');
        expect(page.unreadCount, 1, reason: 'счётчик вернулся');
      },
    );

    test(
      '«отметить все» гасит точки, но не трогает порядок и состав',
      () async {
        final repository = FakeNotificationsRepository(
          items: [
            fakeNotification(id: 'n1'),
            fakeNotification(id: 'n2'),
            fakeNotification(id: 'n3', readAt: DateTime.utc(2026)),
          ],
        );
        final container = await buildContainer(notifications: repository);
        await container.read(notificationsProvider.future);

        await container.read(notificationsProvider.notifier).markAllRead();

        final page = container.read(notificationsProvider).requireValue;
        expect(page.items.map((item) => item.id), ['n1', 'n2', 'n3']);
        expect(page.items.every((item) => item.readAt != null), isTrue);
        expect(page.unreadCount, 0);
        expect(container.read(unreadCountProvider).value, 0);
      },
    );

    test('ошибка «отметить все» возвращает всё как было', () async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1')],
        markAllFailure: const ApiFailure(kind: ApiFailureKind.network),
      );
      final container = await buildContainer(notifications: repository);
      await container.read(notificationsProvider.future);

      await expectLater(
        container.read(notificationsProvider.notifier).markAllRead(),
        throwsA(isA<ApiFailure>()),
      );

      expect(container.read(notificationsProvider).requireValue.unreadCount, 1);
    });

    test('дозагрузка добавляет порцию в конец и не дублирует строки', () async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1')],
        nextPage: [fakeNotification(id: 'n2')],
      );
      final container = await buildContainer(notifications: repository);
      await container.read(notificationsProvider.future);

      await container.read(notificationsProvider.notifier).loadMore();

      final page = container.read(notificationsProvider).requireValue;
      expect(page.items.map((item) => item.id), ['n1', 'n2']);
      expect(page.hasMore, isFalse);
    });

    test('ошибка дозагрузки сохраняет загруженное', () async {
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1')],
        nextPage: [fakeNotification(id: 'n2')],
      );
      final container = await buildContainer(notifications: repository);
      await container.read(notificationsProvider.future);

      repository.listFailure = const ApiFailure(kind: ApiFailureKind.network);
      await container.read(notificationsProvider.notifier).loadMore();

      final page = container.read(notificationsProvider).requireValue;
      expect(page.items, hasLength(1));
      expect(page.loadMoreFailed, isTrue);
    });
  });

  group('живой счётчик непрочитанных', () {
    test('событие темы `user:me` меняет счётчик без запроса', () async {
      final realtime = FakeRealtimeSocketFactory();
      final repository = FakeNotificationsRepository(
        items: [fakeNotification(id: 'n1')],
      );
      final container = await buildContainer(
        notifications: repository,
        realtime: realtime,
      );

      // Счётчик подписывается на тему сам — он нужен на каждом экране.
      await container.read(unreadCountProvider.future);
      await Future<void>.delayed(Duration.zero);

      realtime.last.emitReady();
      await Future<void>.delayed(Duration.zero);

      realtime.last.emitEvent(
        topic: RealtimeTopics.me,
        event: RealtimeEvents.notificationCreated,
        actorId: 'actor-1',
        data: {'id': 'n2', 'type': 'issue_mentioned', 'unreadCount': 7},
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(unreadCountProvider).value, 7);

      // Прочитали в другой вкладке — счётчик здесь обязан уменьшиться.
      realtime.last.emitEvent(
        topic: RealtimeTopics.me,
        event: RealtimeEvents.notificationRead,
        data: {'unreadCount': 0},
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(unreadCountProvider).value, 0);
    });
  });

  group('настройки подписки', () {
    test('переключение оптимистично, ошибка возвращает тумблер', () async {
      final repository = FakeNotificationsRepository(
        updateFailure: const ApiFailure(kind: ApiFailureKind.server),
      );
      final container = await buildContainer(notifications: repository);
      await container.read(notificationSettingsProvider.future);

      await expectLater(
        container
            .read(notificationSettingsProvider.notifier)
            .toggle(NotificationSettingDtoType.issueCommented, enabled: false),
        throwsA(isA<ApiFailure>()),
      );

      final settings = container
          .read(notificationSettingsProvider)
          .requireValue;
      expect(
        settings
            .firstWhere(
              (item) => item.type == NotificationSettingDtoType.issueCommented,
            )
            .enabled,
        isTrue,
      );
    });

    test('меняется ровно один тип, остальные не трогаются', () async {
      final repository = FakeNotificationsRepository();
      final container = await buildContainer(notifications: repository);
      await container.read(notificationSettingsProvider.future);

      await container
          .read(notificationSettingsProvider.notifier)
          .toggle(NotificationSettingDtoType.issueMentioned, enabled: false);

      expect(repository.lastUpdate, (
        NotificationSettingDtoType.issueMentioned,
        false,
      ));
      expect(
        allNotificationsDisabled(
          container.read(notificationSettingsProvider).requireValue,
        ),
        isFalse,
      );
    });

    test('все шесть отключены — это отдельное состояние экрана', () {
      expect(allNotificationsDisabled(fakeSettings(enabled: false)), isTrue);
      expect(allNotificationsDisabled(fakeSettings()), isFalse);
      // Пустой список — это ещё не «всё отключено», это «ничего не пришло».
      expect(allNotificationsDisabled(const []), isFalse);
    });
  });
}
