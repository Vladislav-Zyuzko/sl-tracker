import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

import '../../helpers/pump_widget.dart';

/// Достаёт фон кнопки для набора состояний.
Color _backgroundFor(WidgetTester tester, Set<WidgetState> states) {
  final button = tester.widget<FilledButton>(find.byType(FilledButton));

  return button.style!.backgroundColor!.resolve(states)!;
}

void main() {
  group('SLButton', () {
    testWidgets('нажатие вызывает обработчик', (tester) async {
      var pressed = 0;
      await pumpInTheme(
        tester,
        SLButton(label: 'Создать задачу', onPressed: () => pressed++),
      );

      await tester.tap(find.text('Создать задачу'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('без обработчика кнопка отключена', (tester) async {
      await pumpInTheme(
        tester,
        const SLButton(label: 'Создать задачу', onPressed: null),
      );

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
        isFalse,
      );
    });

    testWidgets('отключённая кнопка красится ролью surfaceDisabled', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SLButton(label: 'Создать задачу', onPressed: null),
      );

      final context = tester.element(find.byType(SLButton));

      expect(
        _backgroundFor(tester, {WidgetState.disabled}),
        SLColorScheme.of(context).surfaceDisabled,
      );
    });

    testWidgets('наведение и нажатие меняют фон на роли accent', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SLButton(label: 'Создать задачу', onPressed: () {}),
      );

      final colors = SLColorScheme.of(tester.element(find.byType(SLButton)));

      expect(_backgroundFor(tester, {}), colors.accent);
      expect(_backgroundFor(tester, {WidgetState.hovered}), colors.accentHover);
      expect(
        _backgroundFor(tester, {WidgetState.pressed}),
        colors.accentPressed,
      );
    });

    testWidgets('во время загрузки текст скрыт, а спиннер показан', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SLButton(label: 'Создать задачу', isLoading: true, onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    });

    testWidgets('во время загрузки нажатие не доходит до обработчика', (
      tester,
    ) async {
      var pressed = 0;
      await pumpInTheme(
        tester,
        SLButton(
          label: 'Создать задачу',
          isLoading: true,
          onPressed: () => pressed++,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(pressed, 0);
    });

    testWidgets('во время загрузки кнопка не выглядит отключённой', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SLButton(label: 'Создать задачу', isLoading: true, onPressed: () {}),
      );

      final colors = SLColorScheme.of(tester.element(find.byType(SLButton)));

      expect(_backgroundFor(tester, {WidgetState.disabled}), colors.accent);
    });

    testWidgets('на десктопе высота берётся из плотности брейкпоинта', (
      tester,
    ) async {
      await pumpInTheme(tester, SLButton(label: 'ОК', onPressed: () {}));

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        SLDensity.desktop.buttonMd,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('на тач-платформе зона нажатия не меньше 44', (tester) async {
      await pumpInTheme(
        tester,
        SLButton(label: 'ОК', onPressed: () {}),
        windowSize: const Size(420, 800),
      );

      final size = tester.getSize(find.byType(FilledButton));

      expect(size.height, greaterThanOrEqualTo(SLSizes.touchTarget));
      expect(size.width, greaterThanOrEqualTo(SLSizes.touchTarget));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('минимальная ширина не даёт короткой подписи схлопнуться', (
      tester,
    ) async {
      await pumpInTheme(tester, SLButton(label: 'ОК', onPressed: () {}));

      expect(
        tester.getSize(find.byType(FilledButton)).width,
        greaterThanOrEqualTo(64),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('опасный вариант красится ролью danger', (tester) async {
      await pumpInTheme(
        tester,
        SLButton(
          label: 'Удалить',
          variant: SLButtonVariant.danger,
          onPressed: () {},
        ),
      );

      final colors = SLColorScheme.of(tester.element(find.byType(SLButton)));

      expect(_backgroundFor(tester, {}), colors.danger);
      expect(_backgroundFor(tester, {WidgetState.hovered}), colors.dangerHover);
    });
  });
}
