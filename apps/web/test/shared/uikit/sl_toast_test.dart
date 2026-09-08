import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('очередь тостов', () {
    test('одинаковые подряд не дублируются — растёт счётчик', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final toasts = container.read(toastControllerProvider.notifier);
      toasts
        ..success('Адрес добавлен')
        ..success('Адрес добавлен');

      final state = container.read(toastControllerProvider);

      expect(state.length, 1);
      expect(state.single.count, 2);
    });

    test('видно не больше трёх: четвёртый вытесняет самый старый', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final toasts = container.read(toastControllerProvider.notifier);
      for (final message in ['первый', 'второй', 'третий', 'четвёртый']) {
        toasts.show(message);
      }

      final messages = container
          .read(toastControllerProvider)
          .map((toast) => toast.message);

      expect(messages, ['второй', 'третий', 'четвёртый']);
    });

    test('ошибка сама не закрывается, успех закрывается через 4 с', () {
      expect(SLToastVariant.danger.autoDismissAfter, isNull);
      expect(
        SLToastVariant.success.autoDismissAfter,
        const Duration(seconds: 4),
      );
      expect(
        SLToastVariant.warning.autoDismissAfter,
        const Duration(seconds: 6),
      );
    });
  });

  group('слой тостов', () {
    testWidgets('успех показывается и закрывается сам', (tester) async {
      final container = await pumpWithProviders(
        tester,
        const SLToastHost(child: SizedBox.expand()),
      );

      container
          .read(toastControllerProvider.notifier)
          .success('Адрес добавлен');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Адрес добавлен'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Адрес добавлен'), findsNothing);
    });

    testWidgets('ошибка остаётся на экране и предлагает повтор', (
      tester,
    ) async {
      var retried = 0;
      final container = await pumpWithProviders(
        tester,
        const SLToastHost(child: SizedBox.expand()),
      );

      container
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось выйти',
            actionLabel: 'Повторить',
            onAction: () => retried++,
          );
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Не удалось выйти'), findsOneWidget);

      await tester.tap(find.text('Повторить'));
      await tester.pump();

      expect(retried, 1);

      // Тост уезжает 120 мс — досматриваем анимацию, иначе таймер останется
      // висеть и тест справедливо на это пожалуется.
      await tester.pump(SLToastController.dismissDuration);
      await tester.pump();

      expect(find.text('Не удалось выйти'), findsNothing);
    });
  });
}
