import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_status_colors.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('IssueStatus', () {
    test('порядок статусов зафиксирован спекой', () {
      expect(IssueStatus.values.map((status) => status.code).toList(), [
        'open',
        'in_progress',
        'review',
        'testing',
        'closed',
      ]);
    });

    test('незнакомый код не роняет клиент', () {
      expect(IssueStatus.tryParse('in_progress'), IssueStatus.inProgress);
      expect(IssueStatus.tryParse('archived'), isNull);
    });
  });

  group('SLStatusChip', () {
    testWidgets('текст статуса показывается всегда', (tester) async {
      for (final status in IssueStatus.values) {
        await pumpInTheme(tester, SLStatusChip(status: status));

        expect(find.text(status.label), findsOneWidget);
      }
    });

    testWidgets('у каждого статуса своя иконка', (tester) async {
      final icons = IssueStatus.values.map(SLStatusChip.iconOf).toSet();

      expect(icons.length, IssueStatus.values.length);
    });

    testWidgets('некликабельная плашка рисуется без шеврона', (tester) async {
      await pumpInTheme(
        tester,
        const SLStatusChip(status: IssueStatus.inProgress),
      );

      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    });

    testWidgets('кликабельная плашка получает шеврон и вызывает обработчик', (
      tester,
    ) async {
      var pressed = 0;
      await pumpInTheme(
        tester,
        SLStatusChip(
          status: IssueStatus.inProgress,
          onPressed: () => pressed++,
        ),
      );

      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      await tester.tap(find.text('В работе'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('цвета берутся из палитры статусов, а не из литералов', (
      tester,
    ) async {
      await pumpInTheme(tester, const SLStatusChip(status: IssueStatus.closed));

      final context = tester.element(find.byType(SLStatusChip));
      final statusColors = SLStatusColors.of(context);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SLStatusChip),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, statusColors.surfaceOf(IssueStatus.closed));

      final label = tester.widget<Text>(find.text('Закрыт'));
      expect(label.style?.color, statusColors.textOf(IssueStatus.closed));
    });

    testWidgets('доступное имя различает кликабельную и обычную плашку', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpInTheme(tester, const SLStatusChip(status: IssueStatus.review));
      expect(find.bySemanticsLabel('Статус: Ревью'), findsOneWidget);

      await pumpInTheme(
        tester,
        SLStatusChip(status: IssueStatus.review, onPressed: () {}),
      );
      expect(find.bySemanticsLabel('Статус: Ревью, изменить'), findsOneWidget);

      handle.dispose();
    });
  });
}
