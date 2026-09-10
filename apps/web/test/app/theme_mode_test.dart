import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/app/sl_app.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_preference.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_providers.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/storage/local_store.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';

import '../helpers/fake_local_store.dart';
import '../helpers/fake_repositories.dart';
import '../helpers/pump_widget.dart';

/// Создаёт контейнер так же, как это делает `main`: сперва читает выбор
/// из хранилища, потом отдаёт его приложению стартовым значением.
///
/// Именно этот порядок проверяют тесты на сохранение выбора: если
/// восстановление уедет в асинхронный код после первого кадра, пользователь
/// с тёмной темой увидит вспышку светлой.
Future<ProviderContainer> bootContainer(
  SLLocalStore store, {
  List<Override> overrides = const [],
}) async {
  final mode = await SLThemeModePreference.read(store);

  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      initialThemeModeProvider.overrideWithValue(mode),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  return container;
}

/// Яркость темы, которую [MaterialApp] реально применил к дереву.
Brightness appliedBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Navigator).first)).brightness;

void main() {
  group('хранимый выбор темы', () {
    test('пустое хранилище даёт «как в системе»', () {
      expect(SLThemeModePreference.decode(null), ThemeMode.system);
      expect(SLThemeModePreference.defaultMode, ThemeMode.system);
    });

    test('чужое значение не роняет приложение, а откатывается к умолчанию', () {
      expect(SLThemeModePreference.decode('sepia'), ThemeMode.system);
      expect(SLThemeModePreference.decode(''), ThemeMode.system);
      expect(SLThemeModePreference.decode('0'), ThemeMode.system);
    });

    test('все три режима переживают запись и чтение', () async {
      for (final mode in ThemeMode.values) {
        final store = FakeLocalStore();
        await SLThemeModePreference.write(store, mode);

        // В хранилище лежит имя, а не индекс: индекс поедет при любой
        // правке ThemeMode на стороне Flutter.
        expect(store.values[SLThemeModePreference.storageKey], mode.name);
        expect(await SLThemeModePreference.read(store), mode);
      }
    });

    test('в списке выбора ровно три режима, первый — «как в системе»', () {
      expect(SLThemeModePreference.order.length, ThemeMode.values.length);
      expect(SLThemeModePreference.order.toSet(), ThemeMode.values.toSet());
      expect(SLThemeModePreference.order.first, ThemeMode.system);
    });
  });

  group('контроллер темы', () {
    test('стартует с «как в системе», пока выбора не было', () async {
      final container = await bootContainer(FakeLocalStore());

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('переключает все три режима', () async {
      final store = FakeLocalStore();
      final container = await bootContainer(store);
      final controller = container.read(themeModeProvider.notifier);

      await controller.select(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await controller.select(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      await controller.select(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('повторный выбор того же режима не пишет в хранилище', () async {
      final store = FakeLocalStore();
      final container = await bootContainer(store);
      final controller = container.read(themeModeProvider.notifier);

      await controller.select(ThemeMode.dark);
      await controller.select(ThemeMode.dark);

      expect(store.writes, 1);
    });

    test('выбор переживает перезапуск приложения', () async {
      final store = FakeLocalStore();

      final first = await bootContainer(store);
      await first.read(themeModeProvider.notifier).select(ThemeMode.dark);

      // Второй контейнер — это F5: провайдеры создаются заново,
      // хранилище остаётся.
      final second = await bootContainer(store);

      expect(second.read(themeModeProvider), ThemeMode.dark);
    });

    test('недоступное хранилище не мешает переключать тему', () async {
      final store = FakeLocalStore()..broken = true;
      final container = await bootContainer(store);

      await container.read(themeModeProvider.notifier).select(ThemeMode.light);

      // Тема сменилась — просто не переживёт перезагрузку.
      expect(container.read(themeModeProvider), ThemeMode.light);

      final afterReload = await bootContainer(store);
      expect(afterReload.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('приложение применяет выбранную тему', () {
    /// Поднимает настоящий [SLApp]: проверяется как раз его связка
    /// `theme` / `darkTheme` / `themeMode`, а не её копия в тесте.
    ///
    /// Сессии намеренно нет: тема к ней не имеет отношения, а экран входа
    /// не ходит в сеть — тест остаётся про цвет, а не про загрузку данных.
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required SLLocalStore store,
      Brightness platform = Brightness.light,
    }) async {
      useWindowSize(tester, const Size(1280, 800));

      tester.platformDispatcher.platformBrightnessTestValue = platform;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final container = await bootContainer(
        store,
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              meFailure: const ApiFailure(
                kind: ApiFailureKind.unauthorized,
                statusCode: 401,
                code: 'session_required',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const SLApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      return container;
    }

    testWidgets('светлая тема при явном выборе, даже если система тёмная', (
      tester,
    ) async {
      final store = FakeLocalStore(
        initial: {SLThemeModePreference.storageKey: ThemeMode.light.name},
      );

      await pumpApp(tester, store: store, platform: Brightness.dark);

      expect(appliedBrightness(tester), Brightness.light);
    });

    testWidgets('тёмная тема при явном выборе, даже если система светлая', (
      tester,
    ) async {
      final store = FakeLocalStore(
        initial: {SLThemeModePreference.storageKey: ThemeMode.dark.name},
      );

      await pumpApp(tester, store: store, platform: Brightness.light);

      expect(appliedBrightness(tester), Brightness.dark);
    });

    testWidgets('в режиме «как в системе» тема идёт за настройкой ОС', (
      tester,
    ) async {
      await pumpApp(
        tester,
        store: FakeLocalStore(),
        platform: Brightness.dark,
      );
      expect(appliedBrightness(tester), Brightness.dark);

      // Пользователь переключил тему ОС, не перезагружая страницу.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(appliedBrightness(tester), Brightness.light);
    });

    testWidgets('смена режима перекрашивает приложение без перезапуска', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        store: FakeLocalStore(),
        platform: Brightness.light,
      );

      expect(appliedBrightness(tester), Brightness.light);

      await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(appliedBrightness(tester), Brightness.dark);
    });
  });
}
