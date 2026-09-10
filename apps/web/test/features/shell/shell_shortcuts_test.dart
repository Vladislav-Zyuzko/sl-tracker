import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/features/shell/presentation/shell_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';

import '../../helpers/pump_widget.dart';

/// Хоткеи оболочки живут над всем приложением, в том числе над полем поиска
/// в сайдбаре. Одиночные буквы `p`, `i`, `n`, `g` и `[` не должны отбирать
/// клавишу у ввода — на русской раскладке это «п», «ш», «т», «о».
void main() {
  group('хоткеи оболочки', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      required List<String> fired,
    }) => pumpInTheme(
      tester,
      SizedBox(
        width: 320,
        child: ShellShortcuts(
          onFocusSearch: () => fired.add('search'),
          onToggleSidebar: () => fired.add('sidebar'),
          onGoProjects: () => fired.add('projects'),
          onGoNotifications: () => fired.add('notifications'),
          onShowHelp: () => fired.add('help'),
          child: SLSearchField(
            hint: 'Название или ключ',
            onQueryChanged: (_) {},
          ),
        ),
      ),
    );

    testWidgets('в поле поиска буквы остаются буквами', (tester) async {
      final fired = <String>[];
      await pumpShell(tester, fired: fired);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      const letters = {
        'p': LogicalKeyboardKey.keyP,
        'i': LogicalKeyboardKey.keyI,
        'n': LogicalKeyboardKey.keyN,
        'g': LogicalKeyboardKey.keyG,
      };

      for (final entry in letters.entries) {
        final handled = await simulateKeyDownEvent(entry.value);
        await simulateKeyUpEvent(entry.value);
        await tester.pump();

        expect(
          handled,
          isFalse,
          reason: 'клавиша «${entry.key}» обязана дойти до поля поиска',
        );
      }

      expect(fired, isEmpty);
    });

    testWidgets('вне поля ввода последовательность `g` `p` работает', (
      tester,
    ) async {
      final fired = <String>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpInTheme(
        tester,
        ShellShortcuts(
          onFocusSearch: () => fired.add('search'),
          onToggleSidebar: () => fired.add('sidebar'),
          onGoProjects: () => fired.add('projects'),
          onGoNotifications: () => fired.add('notifications'),
          onShowHelp: () => fired.add('help'),
          child: Focus(
            focusNode: focusNode,
            autofocus: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();

      expect(fired, ['projects']);
    });

    testWidgets('`Ctrl + K` работает и внутри поля ввода', (tester) async {
      final fired = <String>[];
      await pumpShell(tester, fired: fired);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyK);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(handled, isTrue);
      expect(fired, ['search']);
    });
  });
}
