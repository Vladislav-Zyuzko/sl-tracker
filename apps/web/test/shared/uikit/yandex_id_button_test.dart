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

    testWidgets('в светлой схеме — основной вариант: чёрный фон, белый текст', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;

      expect(
        style.backgroundColor?.resolve({}),
        YandexIdButton.blackBackground,
      );
      expect(
        style.foregroundColor?.resolve({}),
        YandexIdButton.blackForeground,
      );
      expect(style.fixedSize?.resolve({})?.height, YandexIdButton.height);

      final shape = style.shape?.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(YandexIdButton.radius));

      final label = tester.widget<Text>(find.text(YandexIdButton.label));
      expect(label.style?.color, YandexIdButton.blackForeground);
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
      // Надпись сменяется спиннером, но кнопка остаётся сплошной и активной
      // на вид: мигать ей нечем, страница всё равно выгружается.
      expect(find.text(YandexIdButton.label), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('в тёмной схеме — белый вариант Яндекса, а не чёрный', (
      tester,
    ) async {
      // Чёрная кнопка на фоне экрана входа `#10141C` даёт 1.14:1 при
      // требуемых WCAG 1.4.11 3:1 — контрол исчезает. Яндекс публикует
      // два варианта, и выбор между ними изменением кнопки не является
      // (`system.md`, 3.4.1; `screens/login.md`).
      ButtonStyle currentStyle() =>
          tester.widget<FilledButton>(find.byType(FilledButton)).style!;

      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
      );
      final light = currentStyle();

      await pumpInTheme(
        tester,
        SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
        dark: true,
      );
      final dark = currentStyle();

      expect(dark.backgroundColor?.resolve({}), YandexIdButton.whiteBackground);
      expect(dark.foregroundColor?.resolve({}), YandexIdButton.whiteForeground);

      // Геометрия — общая для обоих вариантов и не обсуждается.
      expect(dark.fixedSize?.resolve({}), light.fixedSize?.resolve({}));
      expect(dark.shape?.resolve({}), light.shape?.resolve({}));
      expect(dark.padding?.resolve({}), light.padding?.resolve({}));

      // Надпись покрашена вариантом кнопки, а не ролью темы.
      final label = tester.widget<Text>(find.text(YandexIdButton.label));
      expect(label.style?.color, YandexIdButton.whiteForeground);

      // Знак — тот же ассет, без перекраски: он не меняется ни в одном
      // из вариантов.
      final mark = tester.widget<Image>(find.byType(Image));
      expect((mark.image as AssetImage).assetName, YandexIdButton.markAsset);
      expect(mark.color, isNull);
    });

    testWidgets('вуаль наведения и нажатия — цветом надписи варианта', (
      tester,
    ) async {
      // На чёрном варианте она белая, на белом — чёрная: белая вуаль
      // на белой кнопке ничего бы не показала.
      for (final dark in [false, true]) {
        await pumpInTheme(
          tester,
          SizedBox(width: 360, child: YandexIdButton(onPressed: () {})),
          dark: dark,
        );

        final overlay = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!
            .overlayColor;
        final expected = YandexIdButton.foregroundOf(
          dark ? Brightness.dark : Brightness.light,
        );

        expect(
          overlay?.resolve({WidgetState.hovered}),
          expected.withValues(alpha: 0.10),
          reason: dark ? 'тёмная схема' : 'светлая схема',
        );
        expect(
          overlay?.resolve({WidgetState.pressed}),
          expected.withValues(alpha: 0.18),
          reason: dark ? 'тёмная схема' : 'светлая схема',
        );
      }
    });

    testWidgets('спиннер красится цветом надписи кнопки, а не ролью темы', (
      tester,
    ) async {
      // В тёмной схеме `textOnAccent` — тёмные чернила, а кнопка белая:
      // спиннер обязан быть чёрным, иначе он исчезнет
      // (`screens/login.md`, «Состояния»).
      for (final dark in [false, true]) {
        await pumpInTheme(
          tester,
          SizedBox(
            width: 360,
            child: YandexIdButton(isLoading: true, onPressed: () {}),
          ),
          dark: dark,
        );

        final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );

        expect(
          spinner.color,
          YandexIdButton.foregroundOf(dark ? Brightness.dark : Brightness.light),
          reason: dark ? 'тёмная схема' : 'светлая схема',
        );
      }
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
