import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';

import '../../helpers/pump_widget.dart';

/// Механика одиночных хоткеев.
///
/// Тест про **механизм**, а не про конкретный экран: экранов с одиночными
/// буквенными хоткеями шесть, и проверять каждый по отдельности значит
/// однажды завести седьмой без проверки.
///
/// Почему проверяется именно «событие не перехвачено». В вебе символ в поле
/// вставляет браузер, а Flutter решает, звать ли `preventDefault`: событие,
/// объявленное обработанным, до поля не доходит и символа не даёт. То есть
/// «клавиша не перехвачена» и «буква наберётся» — это одно и то же
/// утверждение, и в виджет-тесте наблюдаемо первое.
///
/// Ровно на этом и сломался `CallbackShortcuts`: он считает событие
/// обработанным, как только активатор совпал, даже если обработчик ничего
/// не сделал. На русской раскладке «ф» — это клавиша `A`, «н» — `Y`,
/// и в описании задачи они не набирались вовсе.
void main() {
  group('SLShortcuts', () {
    testWidgets('пока человек печатает, буква достаётся полю, а не хоткею', (
      tester,
    ) async {
      var fired = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpInTheme(
        tester,
        SLShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyA): () => fired++,
          },
          child: TextField(controller: controller),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        slIsTypingInField(),
        isTrue,
        reason: 'фокус в поле — предпосылка теста',
      );

      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(
        handled,
        isFalse,
        reason: 'клавиша не перехвачена — значит символ дойдёт до поля',
      );
      expect(fired, 0, reason: 'хоткей во время набора не срабатывает');
    });

    testWidgets('вне поля ввода хоткей работает как обычно', (tester) async {
      var fired = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpInTheme(
        tester,
        SLShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyA): () => fired++,
          },
          child: Focus(
            focusNode: focusNode,
            autofocus: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();

      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(handled, isTrue);
      expect(fired, 1);
    });

    testWidgets('выключенный хоткей не претендует на клавишу', (tester) async {
      var fired = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpInTheme(
        tester,
        SLShortcuts(
          enabled: false,
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyC): () => fired++,
          },
          child: Focus(
            focusNode: focusNode,
            autofocus: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();

      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyC);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyC);

      expect(
        handled,
        isFalse,
        reason: 'нечего делать — значит и клавишу забирать не за чем',
      );
      expect(fired, 0);
    });

    testWidgets('незнакомая клавиша уходит дальше по дереву', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpInTheme(
        tester,
        SLShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.keyA): () {}},
          child: Focus(
            focusNode: focusNode,
            autofocus: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );
      await tester.pump();

      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyZ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyZ);

      expect(handled, isFalse);
    });

    testWidgets('CallbackShortcuts на нашем месте сломался бы — контрольный', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      // Тот же расклад на штатном виджете. Если однажды Flutter изменит
      // поведение `CallbackShortcuts` и перестанет поглощать клавишу
      // вхолостую, этот тест покраснеет — и `SLShortcuts` можно будет
      // выбросить, а не тащить по инерции.
      await pumpInTheme(
        tester,
        CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.keyA): () {}},
          child: TextField(controller: controller),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final handled = await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyA);

      expect(
        handled,
        isTrue,
        reason: 'штатный виджет поглощает клавишу, даже когда фокус в поле',
      );
    });
  });

  group('slIsTypingInField', () {
    testWidgets('различает поле ввода и обычный фокусируемый элемент', (
      tester,
    ) async {
      final button = FocusNode();
      final controller = TextEditingController();
      addTearDown(button.dispose);
      addTearDown(controller.dispose);

      await pumpInTheme(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: button,
              autofocus: true,
              child: const SizedBox(width: 100, height: 40),
            ),
            TextField(controller: controller),
          ],
        ),
      );
      await tester.pump();

      expect(slIsTypingInField(), isFalse);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(slIsTypingInField(), isTrue);
    });
  });
}
