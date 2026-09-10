import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/lists/sl_issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

import '../../helpers/pump_widget.dart';

const _inProgress = IssueStatusRef(
  id: 'status-in-progress',
  key: 'in_progress',
  name: 'В работе',
  category: IssueStatusCategory.inProgress,
);

const _closed = IssueStatusRef(
  id: 'status-closed',
  key: 'closed',
  name: 'Закрыт',
  category: IssueStatusCategory.done,
);

void main() {
  group('SLIssueRow', () {
    testWidgets('доступное имя собирает все колонки по порядку', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpInTheme(
        tester,
        SizedBox(
          width: 1000,
          child: SLIssueRow(
            issueKey: 'DEV-42',
            title: 'Починить экспорт CSV',
            status: _inProgress,
            priority: 80,
            storyPoints: 8,
            assignee: const SLAvatarData(
              userId: 'user-1',
              fullName: 'Анна Иванова',
            ),
            onTap: () {},
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'DEV-42, Починить экспорт CSV, статус: В работе, '
          'исполнитель: Анна Иванова, приоритет 80 из 100, высокий, '
          'сложность 8 story points',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('без исполнителя и без оценки строка не ломается', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(
          width: 1000,
          child: SLIssueRow(
            issueKey: 'DEV-41',
            title: 'Обновить README',
            status: _inProgress,
            priority: 50,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Не назначен'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('закрытая задача приглушена, но не зачёркнута', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(
          width: 1000,
          child: SLIssueRow(
            issueKey: 'DEV-35',
            title: 'Вёрстка шапки',
            status: _closed,
            priority: 20,
            onTap: () {},
          ),
        ),
      );

      final context = tester.element(find.byType(SLIssueRow));
      final colors = SLColorScheme.of(context);
      final title = tester.widget<Text>(find.text('Вёрстка шапки'));
      final key = tester.widget<Text>(find.text('DEV-35'));

      expect(title.style?.color, colors.textMuted);
      expect(key.style?.color, colors.textMuted);
      expect(title.style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('пустая тема заменяется курсивным «Без названия»', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(
          width: 1000,
          child: SLIssueRow(
            issueKey: 'DEV-9',
            title: '   ',
            status: _inProgress,
            priority: 50,
            onTap: () {},
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Без названия'));
      expect(title.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('на планшете скрыты сложность и имя исполнителя', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(
          width: 900,
          child: SLIssueRow(
            issueKey: 'DEV-42',
            title: 'Починить экспорт CSV',
            status: _inProgress,
            priority: 80,
            storyPoints: 8,
            assignee: const SLAvatarData(
              userId: 'user-1',
              fullName: 'Анна Иванова',
            ),
            layout: SLIssueRowLayout.tablet,
            onTap: () {},
          ),
        ),
        windowSize: const Size(900, 700),
      );

      expect(find.text('Анна Иванова'), findsNothing);
      expect(find.text('8'), findsNothing);
      expect(find.byType(SLAvatar), findsOneWidget);
      expect(find.text('DEV-42'), findsOneWidget);
    });

    testWidgets('раскладка выбирается по брейкпоинту', (tester) async {
      expect(SLIssueRowLayout.of(SLBreakpoint.sm), SLIssueRowLayout.phone);
      expect(SLIssueRowLayout.of(SLBreakpoint.md), SLIssueRowLayout.tablet);
      expect(SLIssueRowLayout.of(SLBreakpoint.lg), SLIssueRowLayout.desktop);
      expect(SLIssueRowLayout.of(SLBreakpoint.xl), SLIssueRowLayout.desktop);

      // Экстенты — из плотности дизайн-системы, а не из литералов в списке.
      expect(SLIssueRowLayout.desktop.extent, 36);
      expect(SLIssueRowLayout.tablet.extent, 40);
      expect(SLIssueRowLayout.phone.extent, 56);
    });

    testWidgets('заголовки колонок не входят в порядок фокуса', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpInTheme(
        tester,
        const SizedBox(width: 1000, child: SLIssueTableHeader()),
      );

      expect(find.text('КЛЮЧ'), findsOneWidget);
      expect(find.text('НАЗВАНИЕ'), findsOneWidget);
      expect(find.bySemanticsLabel('КЛЮЧ'), findsNothing);

      final context = tester.element(find.byType(SLIssueTableHeader));
      final text = SLTextScheme.of(context);
      final colors = SLColorScheme.of(context);
      final cell = tester.widget<Text>(find.text('КЛЮЧ'));

      expect(cell.style?.fontSize, text.overline.fontSize);
      expect(cell.style?.color, colors.textMuted);

      handle.dispose();
    });

    testWidgets('шапку от списка отделяет граница, а не только тень', (
      tester,
    ) async {
      // Залипшая шапка получает `shadowSm` при прокрутке, но в тёмной схеме
      // тень почти не читается (`system.md`, 10.7.1). Границу и собственный
      // фон шапка обязана иметь в обеих схемах и до всякой прокрутки.
      for (final dark in [false, true]) {
        await pumpInTheme(
          tester,
          const SizedBox(width: 1000, child: SLIssueTableHeader()),
          dark: dark,
        );

        final context = tester.element(find.byType(SLIssueTableHeader));
        final colors = SLColorScheme.of(context);
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(SLIssueTableHeader),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = box.decoration! as BoxDecoration;

        expect(
          decoration.color,
          colors.surfaceSunken,
          reason: dark ? 'тёмная схема' : 'светлая схема',
        );
        expect(
          decoration.border?.bottom.color,
          colors.border,
          reason: dark ? 'тёмная схема' : 'светлая схема',
        );
      }
    });
  });
}
