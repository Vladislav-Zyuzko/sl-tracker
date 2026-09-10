import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

import '../../helpers/pump_widget.dart';

/// Границы поля из его текущей отрисовки.
InputDecoration _decorationOf(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

BorderSide _sideOf(InputBorder? border) => border!.borderSide;

void main() {
  group('SLTextField: фокус', () {
    testWidgets('в фокусе ровно один контур — своя рамка 2 px, без кольца', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Спринт 14');
      addTearDown(controller.dispose);

      await pumpInTheme(
        tester,
        SizedBox(
          width: 320,
          child: SLTextField(controller: controller, label: 'Название'),
        ),
      );

      // Дефект был именно в этом: рамка `borderFocus` плюс кольцо
      // `borderFocus` с зазором — «инпут внутри инпута»
      // (`system.md`, 10.6.1).
      expect(
        find.descendant(
          of: find.byType(SLTextField),
          matching: find.byType(SLFocusRing),
        ),
        findsNothing,
        reason: 'кольцо вокруг поля — второй синий контур, его быть не должно',
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final colors = SLColorScheme.of(tester.element(find.byType(TextField)));
      final focused = _sideOf(_decorationOf(tester).focusedBorder);

      expect(focused.color, colors.borderFocus);
      expect(focused.width, SLBorders.controlFocus);
      expect(
        find.descendant(
          of: find.byType(SLTextField),
          matching: find.byType(SLFocusRing),
        ),
        findsNothing,
      );
    });

    testWidgets('текст и каретка при получении фокуса не сдвигаются', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Спринт 14');
      addTearDown(controller.dispose);

      await pumpInTheme(
        tester,
        SizedBox(
          width: 320,
          child: SLTextField(controller: controller, label: 'Название'),
        ),
      );

      final before = tester.getTopLeft(find.byType(EditableText));
      final sizeBefore = tester.getSize(find.byType(SLTextField));

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Утолщение рисуется внутрь, `contentPadding` один на все состояния:
      // если текст дёргается — это дефект (`system.md`, 10.6.1).
      expect(tester.getTopLeft(find.byType(EditableText)), before);
      expect(tester.getSize(find.byType(SLTextField)), sizeBefore);
    });

    testWidgets('поле с ошибкой в фокусе остаётся красным, а не синим', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'a');
      addTearDown(controller.dispose);

      await pumpInTheme(
        tester,
        SizedBox(
          width: 320,
          child: SLTextField(
            controller: controller,
            label: 'Название',
            errorText: 'Слишком короткое название',
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final colors = SLColorScheme.of(tester.element(find.byType(TextField)));
      final decoration = _decorationOf(tester);

      // Ошибка важнее того, где сейчас каретка; фокус передаётся толщиной.
      expect(_sideOf(decoration.focusedBorder).color, colors.borderDanger);
      expect(_sideOf(decoration.focusedErrorBorder).color, colors.borderDanger);
      expect(
        _sideOf(decoration.focusedErrorBorder).width,
        SLBorders.controlFocus,
      );
    });
  });

  group('SLSearchField: фокус', () {
    testWidgets('кольца нет, рамка в фокусе 2 px, текст не сдвигается', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(
          width: 320,
          child: SLSearchField(
            hint: 'Поиск по моим активным задачам',
            onQueryChanged: (_) {},
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(SLSearchField),
          matching: find.byType(SLFocusRing),
        ),
        findsNothing,
      );

      final before = tester.getTopLeft(find.byType(EditableText));

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final colors = SLColorScheme.of(tester.element(find.byType(TextField)));
      final focused = _sideOf(_decorationOf(tester).focusedBorder);

      expect(focused.color, colors.borderFocus);
      expect(focused.width, SLBorders.controlFocus);
      expect(tester.getTopLeft(find.byType(EditableText)), before);
    });
  });

  group('InputDecorationTheme', () {
    test('все пять границ заданы, толщина означает фокус', () {
      final decoration = SLThemeData.light.inputDecorationTheme;
      final colors = SLThemeData.light.extension<SLColorScheme>()!;

      for (final border in [
        decoration.border,
        decoration.enabledBorder,
        decoration.focusedBorder,
        decoration.errorBorder,
        decoration.focusedErrorBorder,
        decoration.disabledBorder,
      ]) {
        expect(border, isA<OutlineInputBorder>());
        expect(
          (border! as OutlineInputBorder).borderRadius,
          SLRadii.smAll,
          reason: 'радиус поля ввода — radiusSm',
        );
      }

      expect(_sideOf(decoration.enabledBorder).color, colors.borderStrong);
      expect(_sideOf(decoration.enabledBorder).width, SLBorders.hairline);

      expect(_sideOf(decoration.focusedBorder).color, colors.borderFocus);
      expect(_sideOf(decoration.focusedBorder).width, SLBorders.controlFocus);

      expect(_sideOf(decoration.errorBorder).color, colors.borderDanger);
      expect(_sideOf(decoration.errorBorder).width, SLBorders.hairline);

      expect(_sideOf(decoration.focusedErrorBorder).color, colors.borderDanger);
      expect(
        _sideOf(decoration.focusedErrorBorder).width,
        SLBorders.controlFocus,
      );

      expect(_sideOf(decoration.disabledBorder).color, colors.border);
      expect(_sideOf(decoration.disabledBorder).width, SLBorders.hairline);
    });
  });
}
