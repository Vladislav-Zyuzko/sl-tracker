import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/app/theme/theme_mode_preference.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_providers.dart';
import 'package:sl_tracker_web/core/storage/local_store.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/theme_mode_section.dart';

import '../../helpers/fake_local_store.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает секцию выбора темы с хранилищем [store].
Future<ProviderContainer> pumpSection(
  WidgetTester tester, {
  required FakeLocalStore store,
  ThemeMode initial = ThemeMode.system,
}) => pumpWithProviders(
  tester,
  const Scaffold(body: ThemeModeSection()),
  overrides: [
    localStoreProvider.overrideWithValue(store),
    initialThemeModeProvider.overrideWithValue(initial),
  ],
);

/// Сколько галочек на экране. Выбранный вариант ровно один.
int checkCount() => find.byIcon(Icons.check_rounded).evaluate().length;

void main() {
  group('секция выбора темы', () {
    testWidgets('показывает все три режима, «как в системе» первым', (
      tester,
    ) async {
      await pumpSection(tester, store: FakeLocalStore());

      for (final mode in ThemeMode.values) {
        expect(
          find.text(ThemeModeSection.labelOf(mode)),
          findsOneWidget,
          reason: 'режим ${mode.name}',
        );
      }

      final system = tester.getTopLeft(
        find.text(ThemeModeSection.labelOf(ThemeMode.system)),
      );
      final light = tester.getTopLeft(
        find.text(ThemeModeSection.labelOf(ThemeMode.light)),
      );
      final dark = tester.getTopLeft(
        find.text(ThemeModeSection.labelOf(ThemeMode.dark)),
      );

      expect(system.dy, lessThan(light.dy));
      expect(light.dy, lessThan(dark.dy));
    });

    testWidgets('отмечен ровно один вариант — текущий', (tester) async {
      await pumpSection(
        tester,
        store: FakeLocalStore(),
        initial: ThemeMode.light,
      );

      expect(checkCount(), 1);

      // Галочка стоит в строке «Светлая», а не где придётся.
      final check = tester.getCenter(find.byIcon(Icons.check_rounded));
      final row = tester.getRect(
        find.text(ThemeModeSection.labelOf(ThemeMode.light)),
      );

      expect(check.dy, greaterThanOrEqualTo(row.top - 8));
      expect(check.dy, lessThanOrEqualTo(row.bottom + 8));
    });

    testWidgets('нажатие по строке переключает режим и сохраняет выбор', (
      tester,
    ) async {
      final store = FakeLocalStore();
      final container = await pumpSection(tester, store: store);

      await tester.tap(find.text(ThemeModeSection.labelOf(ThemeMode.dark)));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        store.values[SLThemeModePreference.storageKey],
        ThemeMode.dark.name,
      );
      expect(checkCount(), 1);
    });

    testWidgets('проходит по всем трём режимам подряд', (tester) async {
      final store = FakeLocalStore();
      final container = await pumpSection(tester, store: store);

      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        await tester.tap(find.text(ThemeModeSection.labelOf(mode)));
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider), mode);
        expect(
          store.values[SLThemeModePreference.storageKey],
          mode.name,
          reason: 'режим ${mode.name} не доехал до хранилища',
        );
      }
    });

    testWidgets('недоступное хранилище не мешает переключению', (tester) async {
      final store = FakeLocalStore()..broken = true;
      final container = await pumpSection(tester, store: store);

      await tester.tap(find.text(ThemeModeSection.labelOf(ThemeMode.dark)));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('для скринридера это группа взаимоисключающих вариантов', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpSection(
        tester,
        store: FakeLocalStore(),
        initial: ThemeMode.dark,
      );

      expect(find.bySemanticsLabel(ThemeModeSection.groupLabel), findsOneWidget);

      final selected = tester.getSemantics(
        find.bySemanticsLabel(ThemeModeSection.labelOf(ThemeMode.dark)),
      );
      expect(
        selected.flagsCollection.isInMutuallyExclusiveGroup,
        isTrue,
        reason: 'иначе VoiceOver прочитает три независимых пункта',
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);

      // Уточнение к «как в системе» читается вместе с названием, а не
      // теряется отдельной строкой.
      expect(
        find.bySemanticsLabel(
          '${ThemeModeSection.labelOf(ThemeMode.system)}. '
          '${ThemeModeSection.hintOf(ThemeMode.system)}',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
