import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_priority_colors.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_priority_indicator.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('PriorityRange', () {
    test('границы диапазонов совпадают с таблицей из system.md', () {
      expect(PriorityRange.of(0), PriorityRange.low);
      expect(PriorityRange.of(20), PriorityRange.low);
      expect(PriorityRange.of(30), PriorityRange.normal);
      expect(PriorityRange.of(60), PriorityRange.normal);
      expect(PriorityRange.of(70), PriorityRange.high);
      expect(PriorityRange.of(80), PriorityRange.high);
      expect(PriorityRange.of(90), PriorityRange.critical);
      expect(PriorityRange.of(100), PriorityRange.critical);
    });

    test('названия диапазонов — часть контракта продукта', () {
      expect(PriorityRange.low.label, 'Низкий');
      expect(PriorityRange.normal.label, 'Обычный');
      expect(PriorityRange.high.label, 'Высокий');
      expect(PriorityRange.critical.label, 'Критический');
    });
  });

  group('SLPriorityIndicator', () {
    testWidgets('показывает точное значение числом', (tester) async {
      await pumpInTheme(tester, const SLPriorityIndicator(value: 80));

      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('ноль — это «Низкий», а не пусто', (tester) async {
      await pumpInTheme(tester, const SLPriorityIndicator(value: 0));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('ноль красится цветом textMuted, а не цветом диапазона', (
      tester,
    ) async {
      await pumpInTheme(tester, const SLPriorityIndicator(value: 0));

      final context = tester.element(find.byType(SLPriorityIndicator));
      final zero = tester.widget<Text>(find.text('0'));

      expect(zero.style?.color, SLColorScheme.of(context).textMuted);
    });

    testWidgets('высокий приоритет красится цветом своего диапазона', (
      tester,
    ) async {
      await pumpInTheme(tester, const SLPriorityIndicator(value: 80));

      final context = tester.element(find.byType(SLPriorityIndicator));
      final number = tester.widget<Text>(find.text('80'));

      expect(number.style?.color, SLPriorityColors.of(context).numberOf(80));
    });

    testWidgets('доступное имя называет значение и диапазон', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInTheme(tester, const SLPriorityIndicator(value: 80));

      expect(
        find.bySemanticsLabel('Приоритет 80 из 100, высокий'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('без значения рисует прочерк в тех же габаритах', (
      tester,
    ) async {
      await pumpInTheme(tester, const SLPriorityIndicator.unset());

      expect(find.text('—'), findsOneWidget);
      expect(
        tester.getSize(find.byType(SLPriorityIndicator)),
        SLPriorityIndicator.compactSize,
      );
    });

    testWidgets('компактная форма держит фиксированный размер 34 на 20', (
      tester,
    ) async {
      await pumpInTheme(tester, const SLPriorityIndicator(value: 100));

      expect(
        tester.getSize(find.byType(SLPriorityIndicator)),
        SLPriorityIndicator.compactSize,
      );
    });

    testWidgets('расширенная форма добавляет название диапазона', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SLPriorityIndicator(value: 90, expanded: true),
      );

      expect(find.text('90'), findsOneWidget);
      expect(find.text('Критический'), findsOneWidget);
    });
  });
}
