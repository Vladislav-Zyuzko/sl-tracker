import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_fields.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/search_field_geometry.dart';

/// Границы поля из его текущей отрисовки.
InputDecoration _decorationOf(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

BorderSide _sideOf(InputBorder? border) => border!.borderSide;

/// Нижний разделитель встроенного поля поиска.
BorderSide _dividerOf(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(SLSearchField),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );

  return ((box.decoration as BoxDecoration).border! as Border).bottom;
}

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
            hint: 'Название или ключ',
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

  group('SLSearchField: геометрия', () {
    testWidgets('самостоятельное поле — высотой 36', (tester) async {
      // Высота 36 равна высоте строки списка, которую поле фильтрует:
      // контрол ниже своих строк читается как подчинённый им
      // (`system.md`, 10.3.1).
      await pumpInTheme(
        tester,
        SizedBox(
          width: 320,
          child: SLSearchField(
            hint: 'Название или ключ',
            onQueryChanged: (_) {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(SLSearchField)).height, 36);
    });

    test('места вызова дают полю не меньше 240', () {
      // Ширину задаёт вызывающая сторона: тугие габариты от родителя
      // компонент переопределить не может, поэтому 240 живёт токеном
      // и проверяется там, где поле ставят.
      expect(
        SLSizes.sidebarWidth - 2 * SLSpacing.space2,
        greaterThanOrEqualTo(SLSizes.searchFieldMinWidth),
      );
      expect(
        IssueUserField.menuWidth,
        greaterThanOrEqualTo(SLSizes.searchFieldMinWidth),
      );
    });

    testWidgets('встроенное в меню — 32, без рамки, с разделителем', (
      tester,
    ) async {
      // Рамка внутри рамки меню — «коробка в коробке», тот же дефект,
      // из-за которого переделывали кольцо фокуса (`components.md`, 4.1).
      await pumpInTheme(
        tester,
        SizedBox(
          width: 280,
          child: SLSearchField(
            hint: 'Начните вводить имя',
            variant: SLSearchFieldVariant.embedded,
            showHotkeyHint: false,
            onQueryChanged: (_) {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(SLSearchField)).height, 32);

      final decoration = _decorationOf(tester);
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.filled, isFalse);

      final colors = SLColorScheme.of(tester.element(find.byType(TextField)));
      expect(_dividerOf(tester).color, colors.borderSubtle);
      expect(_dividerOf(tester).width, SLBorders.hairline);

      // В фокусе утолщается разделитель, а не появляется рамка.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(_decorationOf(tester).focusedBorder, InputBorder.none);
      expect(_dividerOf(tester).color, colors.borderFocus);
      expect(_dividerOf(tester).width, SLBorders.controlFocus);
    });

    // Размер поля не зависит от того, что стоит справа. Дефект: коробка
    // поля была 36, а рамка внутри неё — 18 пустой, с бейджем `/` и со
    // спиннером и 24 с кнопкой очистки: заливку и контур `InputDecorator`
    // рисует по высоте содержимого, а не по `SizedBox` (`components.md`,
    // 4.1). Ширины — те, что дают места вызова: сайдбар и список доступа.
    for (final (label, windowSize, expectedHeight) in const [
      ('десктоп', Size(1280, 800), 36.0),
      ('телефон', Size(390, 800), 44.0),
    ]) {
      for (final width in const [
        SLSizes.sidebarWidth - 2 * SLSpacing.space2,
        SLSizes.searchFieldMinWidth,
      ]) {
        testWidgets(
          'самостоятельное, $label, ширина $width: рамка одна '
          'во всех четырёх состояниях',
          (tester) async {
            final controller = TextEditingController();
            addTearDown(controller.dispose);

            Future<void> pump({required bool loading}) => pumpInTheme(
              tester,
              SizedBox(
                width: width,
                child: SLSearchField(
                  hint: 'Название или ключ',
                  controller: controller,
                  isLoading: loading,
                  onQueryChanged: (_) {},
                ),
              ),
              windowSize: windowSize,
            );

            await pump(loading: false);
            expect(find.text('/'), findsOneWidget);
            final frames = await searchFieldFramesByState(tester);

            await pump(loading: true);
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
            frames['загрузка'] = searchFieldFrame(tester);

            for (final MapEntry(key: state, value: frame) in frames.entries) {
              expect(
                frame.size,
                Size(width, expectedHeight),
                reason: 'рамка в состоянии «$state»',
              );
            }
            expectFrameFillsField(tester, frames);
          },
        );
      }
    }

    testWidgets('встроенное: иконка и строка по центру и не прыгают', (
      tester,
    ) async {
      // Та же причина у встроенного вида: рамки у него нет, но иконка
      // центровалась по высоте содержимого (18, с кнопкой очистки 24) и
      // съезжала на 3 px, а строка прижималась к верху поля высотой 32.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      Future<void> pump({required bool loading}) => pumpInTheme(
        tester,
        SizedBox(
          width: IssueUserField.menuWidth,
          child: SLSearchField(
            hint: 'Начните вводить имя',
            variant: SLSearchFieldVariant.embedded,
            showHotkeyHint: false,
            controller: controller,
            isLoading: loading,
            onQueryChanged: (_) {},
          ),
        ),
      );

      await pump(loading: false);
      final center = tester.getCenter(find.byType(SLSearchField)).dy;

      void expectCentered(String state) {
        expect(
          tester.getCenter(find.byIcon(Icons.search_rounded)).dy,
          center,
          reason: 'иконка поиска в состоянии «$state»',
        );
        expect(
          tester.getCenter(find.byType(EditableText)).dy,
          center,
          reason: 'строка в состоянии «$state»',
        );
      }

      expectCentered('пустое без фокуса');

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expectCentered('пустое в фокусе');

      await tester.enterText(find.byType(TextField), 'ан');
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expectCentered('с текстом');

      await pump(loading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expectCentered('загрузка');

      // Дебаунс не должен пережить тест.
      await tester.pump(const Duration(seconds: 1));
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
