import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

void main() {
  group('переключатель', () {
    testWidgets('размер — 32 × 18, бегунок 14 (components.md, 23)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SLColorScheme.light()]),
          home: Scaffold(body: SLSwitch(value: true, onChanged: (_) {})),
        ),
      );

      final track = tester.getSize(
        find.descendant(
          of: find.byType(SLSwitch),
          matching: find.byType(AnimatedContainer),
        ),
      );

      expect(track.width, SLSwitch.width);
      expect(track.height, SLSwitch.height);
      // Зона нажатия на тач — не меньше 44 при том же визуальном размере.
      expect(
        tester.getSize(find.byType(SLSwitch)).height,
        greaterThanOrEqualTo(SLSizes.touchTarget),
      );
    });

    testWidgets('нажатие переключает, отключённый не реагирует', (
      tester,
    ) async {
      var value = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SLColorScheme.light()]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  SLSwitch(
                    value: value,
                    onChanged: (next) => setState(() => value = next),
                  ),
                  const SLSwitch(value: true, onChanged: null),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SLSwitch).first);
      await tester.pumpAndSettle();
      expect(value, isTrue);

      // Отключённый переключатель не меняет ничего и молчит.
      await tester.tap(find.byType(SLSwitch).last);
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('пробел переключает то, что под фокусом, и фокус виден', (
      tester,
    ) async {
      var value = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SLColorScheme.light()]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SLSwitch(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );

      // Кольца фокуса нет, пока фокуса нет.
      expect(
        tester.widget<SLFocusRing>(find.byType(SLFocusRing)).focused,
        isFalse,
      );

      // Фокус приходит обходом с клавиатуры, а не вручную поставленным
      // узлом: проверять надо ровно тот путь, которым идёт человек.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.widget<SLFocusRing>(find.byType(SLFocusRing)).focused,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(value, isTrue);
    });
  });
}
