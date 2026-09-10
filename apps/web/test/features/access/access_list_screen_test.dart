import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/access/data/access_repository.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_providers.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_screen.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/access_entry_row.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/access_source_badge.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран списка доступа с готовой сессией.
Future<ProviderContainer> pumpAccessList(
  WidgetTester tester, {
  required FakeAccessRepository access,
  bool canManageAccessList = true,
}) async {
  final container = await pumpWithProviders(
    tester,
    // В приложении экран живёт внутри оболочки с её `Scaffold`;
    // в тесте эту роль играет обычный `Scaffold`.
    const Scaffold(body: AccessListScreen()),
    overrides: [
      accessRepositoryProvider.overrideWithValue(access),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          meResult: fakeMe(canManageAccessList: canManageAccessList),
        ),
      ),
    ],
  );

  await container.read(sessionControllerProvider.notifier).load();
  await tester.pump();
  await tester.pump();

  return container;
}

void main() {
  group('экран списка доступа', () {
    testWidgets('без права раздел не подтверждается: «страница не найдена»', (
      tester,
    ) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(entries: [fakeEntry()]),
        canManageAccessList: false,
      );

      expect(find.text('Страница не найдена'), findsOneWidget);
      expect(find.text('Доступ к трекеру'), findsNothing);
    });

    testWidgets('источников записи три, и каждый назван словами', (
      tester,
    ) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          entries: [
            fakeEntry(
              id: '1',
              email: 'config@yandex.ru',
              source: AccessEntryDtoSource.config,
            ),
            fakeEntry(
              id: '2',
              email: 'manual@yandex.ru',
              source: AccessEntryDtoSource.manual,
            ),
            fakeEntry(
              id: '3',
              email: 'invite@yandex.ru',
              source: AccessEntryDtoSource.invitation,
            ),
          ],
        ),
      );

      expect(find.byType(AccessSourceBadge), findsNWidgets(3));
      expect(find.text('Конфигурация'), findsOneWidget);
      expect(find.text('Вручную'), findsOneWidget);
      expect(find.text('Приглашение'), findsOneWidget);
      // Плашка неизвестного источника тоже имеет текст, а не пустоту.
      expect(
        AccessSourceBadge.labelOf(AccessEntryDtoSource.$unknown),
        isNotEmpty,
      );
    });

    testWidgets('счётчик показывает, сколько записей всего', (tester) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          entries: [
            fakeEntry(id: '1', email: 'a@yandex.ru'),
            fakeEntry(id: '2', email: 'b@yandex.ru'),
          ],
        ),
      );

      expect(find.text('Всего: 2'), findsOneWidget);
      expect(find.byType(AccessEntryRow), findsNWidgets(2));
    });

    testWidgets('у собственной записи нет пункта удаления', (tester) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          entries: [
            fakeEntry(id: '1', email: 'me@yandex.ru', isSelf: true),
            fakeEntry(id: '2', email: 'other@yandex.ru'),
          ],
        ),
      );

      expect(find.text('(вы)'), findsOneWidget);

      await tester.tap(find.byTooltip('Действия для me@yandex.ru'));
      await tester.pumpAndSettle();

      expect(find.text('Удалить из списка'), findsNothing);
      expect(find.text('Нельзя удалить собственный доступ'), findsOneWidget);
    });

    testWidgets('чужую запись удалить предлагают', (tester) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          entries: [fakeEntry(id: '2', email: 'other@yandex.ru')],
        ),
      );

      await tester.tap(find.byTooltip('Действия для other@yandex.ru'));
      await tester.pumpAndSettle();

      expect(find.text('Удалить из списка'), findsOneWidget);
      expect(find.text('Сделать владельцем трекера'), findsOneWidget);
    });

    testWidgets('пустой список объясняет, что делать', (tester) async {
      await pumpAccessList(tester, access: FakeAccessRepository());

      expect(find.text('В списке доступа никого нет'), findsOneWidget);
      expect(find.text('Добавить адрес'), findsWidgets);
    });

    testWidgets('сбой загрузки предлагает повтор, а не белый экран', (
      tester,
    ) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          listFailure: const ApiFailure(kind: ApiFailureKind.network),
        ),
      );

      expect(find.text('Не удалось загрузить список доступа'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('403 не подтверждает существование раздела', (tester) async {
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          listFailure: const ApiFailure(
            kind: ApiFailureKind.forbidden,
            statusCode: 403,
            code: 'access_list_forbidden',
          ),
        ),
      );

      expect(find.text('Страница не найдена'), findsOneWidget);
    });

    testWidgets('поле поиска высотой 36 и не уже 240', (tester) async {
      // Та же геометрия, что у поиска в сайдбаре: поле поиска — контрол
      // над строками, а не строка (`system.md`, 10.3.1).
      await pumpAccessList(
        tester,
        access: FakeAccessRepository(
          entries: [fakeEntry(id: '1', email: 'anna@yandex.ru')],
        ),
      );

      final size = tester.getSize(find.byType(SLSearchField));
      expect(size.height, 36);
      expect(size.width, greaterThanOrEqualTo(SLSizes.searchFieldMinWidth));
    });

    testWidgets('поиск уходит на сервер, а не фильтрует загруженное', (
      tester,
    ) async {
      final access = FakeAccessRepository(
        entries: [fakeEntry(id: '1', email: 'anna@yandex.ru')],
      );
      final container = await pumpAccessList(tester, access: access);

      container.read(accessSearchQueryProvider.notifier).update('anna');
      await tester.pump();
      await tester.pump();

      expect(access.lastQuery, 'anna');
    });

    testWidgets('пусто после поиска — другой текст и другое действие', (
      tester,
    ) async {
      final access = FakeAccessRepository(entries: [fakeEntry()]);
      final container = await pumpAccessList(tester, access: access);

      access.entries = [];
      container.read(accessSearchQueryProvider.notifier).update('никого');
      await tester.pump();
      await tester.pump();

      expect(find.text('Ничего не нашлось'), findsOneWidget);
      expect(find.text('Очистить поиск'), findsOneWidget);
    });
  });

  group('список доступа: состояние', () {
    test('удаление убирает строку и уменьшает счётчик', () async {
      final access = FakeAccessRepository(
        entries: [
          fakeEntry(id: '1', email: 'a@yandex.ru'),
          fakeEntry(id: '2', email: 'b@yandex.ru'),
        ],
      );
      final container = ProviderContainer(
        overrides: [accessRepositoryProvider.overrideWithValue(access)],
      );
      addTearDown(container.dispose);

      await container.read(accessListProvider.future);
      final revoked = await container
          .read(accessListProvider.notifier)
          .revoke('1');
      final page = container.read(accessListProvider).requireValue;

      expect(revoked, 2);
      expect(page.items.map((entry) => entry.id), ['2']);
      expect(page.total, 1);
    });

    test('добавленная запись встаёт сверху и подсвечивается', () async {
      final access = FakeAccessRepository(
        entries: [fakeEntry(id: '1', email: 'a@yandex.ru')],
      );
      final container = ProviderContainer(
        overrides: [accessRepositoryProvider.overrideWithValue(access)],
      );
      addTearDown(container.dispose);

      await container.read(accessListProvider.future);
      final created = await container
          .read(accessListProvider.notifier)
          .add('new@yandex.ru');
      final page = container.read(accessListProvider).requireValue;

      expect(page.items.first.email, 'new@yandex.ru');
      expect(page.items.first.source, AccessEntryDtoSource.manual);
      expect(page.highlightedId, created.id);
      expect(page.total, 2);
    });
  });
}
