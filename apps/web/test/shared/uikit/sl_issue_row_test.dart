import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/lists/sl_issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
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

    testWidgets('в узкой области скрыты сложность и имя исполнителя', (
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
            layout: SLIssueRowLayout.resolve(
              breakpoint: SLBreakpoint.md,
              contentWidth: 700,
            ),
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

    test('высота строки — по брейкпоинту, колонки — по ширине содержимого', () {
      // Две независимые величины, и путать их нельзя: высота — это
      // плотность интерфейса, набор колонок — это место под название.
      SLIssueRowLayout wide(SLBreakpoint breakpoint) =>
          SLIssueRowLayout.resolve(breakpoint: breakpoint, contentWidth: 1200);

      expect(wide(SLBreakpoint.xl).extent, 36);
      expect(wide(SLBreakpoint.lg).extent, 36);
      expect(wide(SLBreakpoint.md).extent, 40);
      expect(wide(SLBreakpoint.xl).columns, SLIssueColumnSet.full);
      expect(wide(SLBreakpoint.md).columns, SLIssueColumnSet.full);

      // Телефон — карточка при любой ширине: семь колонок в 360 px
      // не помещаются ни при какой арифметике.
      expect(wide(SLBreakpoint.sm), SLIssueRowLayout.phone);
      expect(SLIssueRowLayout.phone.extent, 56);
      expect(SLIssueRowLayout.phone.isCard, isTrue);
    });

    test('колонка названия никогда не уже 280', () {
      // Это и есть правило, из которого выведены пороги
      // (`screens/queue-issues.md`, «Колонки по ширине содержимого»).
      // Проверяем его напрямую, а не через пороги: пороги — следствие.
      for (var width = 688.0; width <= 1600.0; width += 1) {
        final layout = SLIssueRowLayout.resolve(
          breakpoint: SLBreakpoint.lg,
          contentWidth: width,
        );
        final title = width - SLIssueRowLayout.fixedWidth(layout.columns);

        expect(
          title,
          greaterThanOrEqualTo(SLSizes.issueTitleMinWidth),
          reason: 'ширина содержимого $width, набор ${layout.columns.name}',
        );
      }
    });

    test('порядок отбрасывания колонок: сложность, имя исполнителя', () {
      SLIssueColumnSet columnsAt(double width) => SLIssueRowLayout.resolve(
        breakpoint: SLBreakpoint.lg,
        contentWidth: width,
      ).columns;

      expect(columnsAt(1000), SLIssueColumnSet.full);
      expect(columnsAt(860), SLIssueColumnSet.full);
      expect(columnsAt(859), SLIssueColumnSet.withoutComplexity);
      expect(columnsAt(816), SLIssueColumnSet.withoutComplexity);
      expect(columnsAt(815), SLIssueColumnSet.assigneeAvatarOnly);
      expect(columnsAt(688), SLIssueColumnSet.assigneeAvatarOnly);
      expect(columnsAt(687), SLIssueColumnSet.card);

      // Ключ, название, статус и приоритет не отбрасываются никогда.
      for (final columns in SLIssueColumnSet.values) {
        if (columns == SLIssueColumnSet.card) continue;
        expect(
          SLIssueRowLayout.fixedWidth(columns),
          greaterThanOrEqualTo(
            SLSizes.issueKeyColumn +
                SLSizes.statusColumn +
                SLSizes.priorityColumn,
          ),
        );
      }
    });

    test('дефект: при окне 1024 с сайдбаром название не сжимается до 84', () {
      // Регрессия на исходный дефект. Окно 1024, сайдбар 280 развёрнут —
      // области содержимого остаётся 744 px.
      const contentWidth = 1024.0 - SLSizes.sidebarWidth;
      final layout = SLIssueRowLayout.resolve(
        breakpoint: SLBreakpoint.lg,
        contentWidth: contentWidth,
      );
      final title = contentWidth - SLIssueRowLayout.fixedWidth(layout.columns);

      expect(layout.columns, SLIssueColumnSet.assigneeAvatarOnly);
      expect(title, greaterThanOrEqualTo(280));

      // Свернув сайдбар, пользователь возвращает себе колонки.
      const collapsedWidth = 1024.0 - SLSizes.sidebarCollapsedWidth;
      expect(
        SLIssueRowLayout.resolve(
          breakpoint: SLBreakpoint.lg,
          contentWidth: collapsedWidth,
        ).columns,
        SLIssueColumnSet.full,
      );
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
