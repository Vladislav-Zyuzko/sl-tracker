import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('SLAvatarColors', () {
    test('индекс устойчив: один и тот же id даёт один и тот же цвет', () {
      final first = SLAvatarColors.stableIndex('user-42', 8);
      final second = SLAvatarColors.stableIndex('user-42', 8);

      expect(first, second);
      expect(first, inInclusiveRange(0, 7));
    });

    test('разные идентификаторы обычно расходятся по цветам', () {
      final indexes = {
        for (var i = 0; i < 64; i++) SLAvatarColors.stableIndex('user-$i', 8),
      };

      expect(indexes.length, greaterThan(1));
    });

    test('в палитре ровно восемь заливок', () {
      expect(SLAvatarColors.light().fills.length, 8);
    });
  });

  group('SLAvatar', () {
    test('инициалы берутся из имени и фамилии', () {
      expect(SLAvatar.initialsOf('Анна Иванова'), 'АИ');
      expect(SLAvatar.initialsOf('  Пётр   Смирнов '), 'ПС');
      expect(SLAvatar.initialsOf('Мария'), 'М');
      expect(SLAvatar.initialsOf('   '), '');
    });

    testWidgets('без фотографии показывает инициалы', (tester) async {
      await pumpInTheme(
        tester,
        const SLAvatar(userId: 'user-1', fullName: 'Анна Иванова'),
      );

      expect(find.text('АИ'), findsOneWidget);
    });

    testWidgets('без имени падает на иконку, а не на пустоту', (tester) async {
      await pumpInTheme(tester, const SLAvatar(userId: 'user-1', fullName: ''));

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('цвет заливки выбирается по идентификатору, а не по имени', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SLAvatar(userId: 'user-7', fullName: 'Анна Иванова'),
      );

      final context = tester.element(find.byType(SLAvatar));
      final expected = SLAvatarColors.of(context).fillOf('user-7');
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(SLAvatar),
          matching: find.byType(ColoredBox),
        ),
      );

      expect(box.color, expected);
    });

    testWidgets('группа показывает три аватара и счётчик остальных', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SLAvatarGroup(
          members: [
            SLAvatarData(userId: '1', fullName: 'Анна Иванова'),
            SLAvatarData(userId: '2', fullName: 'Пётр Смирнов'),
            SLAvatarData(userId: '3', fullName: 'Мария Ковалёва'),
            SLAvatarData(userId: '4', fullName: 'Иван Петров'),
            SLAvatarData(userId: '5', fullName: 'Ольга Белова'),
          ],
        ),
      );

      expect(find.byType(SLAvatar), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('доступное имя группы перечисляет видимых и остальных', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpInTheme(
        tester,
        const SLAvatarGroup(
          members: [
            SLAvatarData(userId: '1', fullName: 'Анна Иванова'),
            SLAvatarData(userId: '2', fullName: 'Пётр Смирнов'),
            SLAvatarData(userId: '3', fullName: 'Мария Ковалёва'),
            SLAvatarData(userId: '4', fullName: 'Иван Петров'),
          ],
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Участники: Анна Иванова, Пётр Смирнов, Мария Ковалёва и ещё 1',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
