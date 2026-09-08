import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';

import '../../helpers/pump_widget.dart';

const _style = TextStyle(fontSize: 10);

void main() {
  group('SLMiddleEllipsisText.fit', () {
    test('короткое значение не трогается', () {
      expect(
        SLMiddleEllipsisText.fit('ivan@yandex.ru', _style, 1000),
        'ivan@yandex.ru',
      );
    });

    test('длинное значение теряет середину, а не домен', () {
      const email = 'ivan.petrov.the.longest@ochen-dlinnyy-domen.example.ru';

      final result = SLMiddleEllipsisText.fit(email, _style, 120);

      expect(result, contains(SLMiddleEllipsisText.ellipsis));
      expect(result.length, lessThan(email.length));
      // Начало узнаваемо, конец — тоже: иначе строка перестаёт что-то значить.
      expect(
        email.startsWith(result.split(SLMiddleEllipsisText.ellipsis).first),
        isTrue,
      );
      expect(
        email.endsWith(result.split(SLMiddleEllipsisText.ellipsis).last),
        isTrue,
      );
    });

    test('на нулевой ширине не падает', () {
      expect(SLMiddleEllipsisText.fit('ivan@yandex.ru', _style, 0), isNotEmpty);
    });
  });

  group('SLMiddleEllipsisText', () {
    testWidgets('полное значение остаётся в тултипе и в семантике', (
      tester,
    ) async {
      const email = 'ivan.petrov.the.longest@ochen-dlinnyy-domen.example.ru';

      await pumpInTheme(
        tester,
        const SizedBox(
          width: 100,
          child: SLMiddleEllipsisText(value: email, style: _style),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, email);
      expect(find.text(email), findsNothing);
    });

    testWidgets('когда всё помещается, тултипа нет', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 400,
          child: SLMiddleEllipsisText(value: 'a@b.ru', style: _style),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
      expect(find.text('a@b.ru'), findsOneWidget);
    });
  });
}
