import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/yandex_id_button.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('кнопка Яндекс ID', () {
    testWidgets('надпись и знак — из требований Яндекса', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
      );

      expect(find.text(YandexIdButton.label), findsOneWidget);

      // Знак берётся ассетом и не рисуется вручную.
      final mark = tester.widget<Image>(find.byType(Image));
      expect((mark.image as AssetImage).assetName, YandexIdButton.markAsset);
      expect(mark.width, YandexIdButton.markSize);
      // Знак декоративен: доступное имя есть у кнопки целиком.
      expect(mark.excludeFromSemantics, isTrue);
    });

    testWidgets('исключение из системы: чёрный фон, высота 44, радиус 12', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;

      expect(style.backgroundColor?.resolve({}), YandexIdButton.background);
      expect(style.foregroundColor?.resolve({}), YandexIdButton.foreground);
      expect(style.fixedSize?.resolve({})?.height, YandexIdButton.height);

      final shape = style.shape?.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(YandexIdButton.radius));
    });

    testWidgets('нажатие срабатывает', (tester) async {
      var taps = 0;

      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () => taps++)),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('во время перехода нажатия игнорируются', (tester) async {
      var taps = 0;

      await pumpInTheme(
        tester,
        SizedBox(
          width: 360,
          child: YandexIdButton(isLoading: true, onPressed: () => taps++),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 0);
      // Надпись сменяется спиннером, но кнопка остаётся чёрной и активной
      // на вид: мигать ей нечем, страница всё равно выгружается.
      expect(find.text(YandexIdButton.label), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('доступное имя — «Войти через Яндекс»', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
      );

      expect(
        find.bySemanticsLabel(YandexIdButton.semanticLabel),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
