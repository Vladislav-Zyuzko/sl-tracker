import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_screen.dart';
import 'package:sl_tracker_web/shared/uikit/lists/sl_issue_row.dart';

import '../../helpers/fake_platform.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран задач очереди по адресу `/queues/DEV`.
Future<GoRouter> pumpQueue(
  WidgetTester tester, {
  required FakeQueuesRepository queues,
  required FakeIssuesRepository issues,
  RecordingBrowserNavigator? navigator,
  String location = '/queues/DEV',
  Size windowSize = const Size(1280, 800),
}) => pumpWithRouter(
  tester,
  initialLocation: location,
  windowSize: windowSize,
  overrides: [
    queuesRepositoryProvider.overrideWithValue(queues),
    issuesRepositoryProvider.overrideWithValue(issues),
    browserNavigatorProvider.overrideWithValue(
      navigator ?? RecordingBrowserNavigator(),
    ),
  ],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: Text('мои проекты')),
    ),
    GoRoute(
      path: '/queues/:key',
      builder: (context, state) {
        final query = state.uri.queryParameters;

        return Scaffold(
          body: QueueIssuesScreen(
            queueKey: state.pathParameters['key']!,
            statusKeys: QueueIssuesQuery.parseStatuses(query['status']),
            sort: IssueSort.parse(query['sort']),
          ),
        );
      },
    ),
    GoRoute(
      path: '/issues/:key',
      builder: (context, state) =>
          Scaffold(body: Text('задача ${state.pathParameters['key']}')),
    ),
  ],
);

void main() {
  group('список задач очереди', () {
    testWidgets('загрузка показывает скелетон и настоящие заголовки колонок', (
      tester,
    ) async {
      final issues = FakeIssuesRepository(
        issues: [fakeIssueRow(key: 'DEV-1')],
        role: IssueListDtoRole.admin,
      )..gate = Completer<void>();

      await pumpQueue(tester, queues: FakeQueuesRepository(), issues: issues);
      await tester.pump();

      expect(find.byType(SLIssueTableHeader), findsOneWidget);
      expect(find.text('КЛЮЧ'), findsOneWidget);
      expect(find.byType(SLIssueRowSkeleton), findsWidgets);
      expect(find.byType(SLIssueRow), findsNothing);

      issues.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SLIssueRow), findsOneWidget);
    });

    testWidgets('строки и счётчик «Показано N» на месте', (tester) async {
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [
            fakeIssueRow(key: 'DEV-1', title: 'Починить экспорт CSV'),
            fakeIssueRow(key: 'DEV-2', title: 'Обновить README'),
          ],
          role: IssueListDtoRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEV-1'), findsOneWidget);
      expect(find.text('Починить экспорт CSV'), findsOneWidget);
      expect(find.text('Показано 2'), findsOneWidget);
      expect(find.text('Разработка'), findsOneWidget);
    });

    testWidgets('две тысячи задач не строятся все сразу', (tester) async {
      // Главная проверка экрана: список обязан быть виртуализированным.
      // На 2000 задачах в дереве должно жить около экрана строк, а не 2000.
      final issues = FakeIssuesRepository(
        issues: [for (var i = 1; i <= 2000; i++) fakeIssueRow(key: 'DEV-$i')],
        role: IssueListDtoRole.admin,
      )..pageSize = 2000;

      await pumpQueue(tester, queues: FakeQueuesRepository(), issues: issues);
      await tester.pumpAndSettle();

      final built = tester.widgetList<SLIssueRow>(find.byType(SLIssueRow));
      // Окно 1280 × 800: примерно 20 строк по 36 плюс кэш по краям.
      expect(built.length, lessThan(60));
      expect(built.length, greaterThan(10));

      // Прокрутка на середину списка не увеличивает число построенных строк.
      await tester.drag(find.byType(SLIssueRow).first, const Offset(0, -8000));
      await tester.pumpAndSettle();

      expect(
        tester.widgetList<SLIssueRow>(find.byType(SLIssueRow)).length,
        lessThan(60),
      );
      expect(find.text('DEV-1'), findsNothing);
    });

    testWidgets('пустая очередь предлагает создать первую задачу', (
      tester,
    ) async {
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(role: IssueListDtoRole.admin),
      );
      await tester.pumpAndSettle();

      expect(find.text('В этой очереди пока нет задач'), findsOneWidget);
      expect(
        find.text('Создайте первую — она получит ключ DEV-1.'),
        findsOneWidget,
      );
    });

    testWidgets('читателю не предлагают создавать задачи', (tester) async {
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(role: IssueListDtoRole.reader),
      );
      await tester.pumpAndSettle();

      expect(find.text('В этой очереди пока нет задач'), findsOneWidget);
      expect(
        find.text('Задачи появятся, когда их создадут участники проекта.'),
        findsOneWidget,
      );
      expect(find.text('Создать задачу'), findsNothing);
    });

    testWidgets('пусто после фильтра — другой текст и сброс фильтров', (
      tester,
    ) async {
      final router = await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [fakeIssueRow(key: 'DEV-1')],
          role: IssueListDtoRole.admin,
        ),
        location: '/queues/DEV?status=closed',
      );
      await tester.pumpAndSettle();

      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(
        find.text('Ни одна задача не подходит под выбранные статусы.'),
        findsOneWidget,
      );
      // Панель фильтров остаётся: иначе непонятно, что фильтр применён.
      expect(find.textContaining('Статус:'), findsOneWidget);

      await tester.tap(find.text('Сбросить фильтры'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/queues/DEV',
      );
      expect(find.text('DEV-1'), findsOneWidget);
    });

    testWidgets('ошибка первой загрузки оставляет шапку и фильтры', (
      tester,
    ) async {
      final issues = FakeIssuesRepository()
        ..listFailure = const ApiFailure(kind: ApiFailureKind.network);

      await pumpQueue(tester, queues: FakeQueuesRepository(), issues: issues);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить задачи'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
      expect(find.text('Разработка'), findsOneWidget);
      expect(find.textContaining('Статус:'), findsOneWidget);

      issues.listFailure = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить задачи'), findsNothing);
    });

    testWidgets('очередь не найдена — без названия очереди и проекта', (
      tester,
    ) async {
      final queues = FakeQueuesRepository()
        ..getFailure = const ApiFailure(kind: ApiFailureKind.notFound);
      final issues = FakeIssuesRepository()
        ..listFailure = const ApiFailure(kind: ApiFailureKind.notFound);

      await pumpQueue(tester, queues: queues, issues: issues);
      await tester.pumpAndSettle();

      expect(find.text('Очередь не найдена'), findsOneWidget);
      expect(find.text('Разработка'), findsNothing);
    });

    testWidgets('фильтр по статусу уходит в адрес страницы ключами', (
      tester,
    ) async {
      final router = await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [
            fakeIssueRow(key: 'DEV-1'),
            fakeIssueRow(key: 'DEV-2', statusKey: 'open', statusName: 'Открыт'),
          ],
          role: IssueListDtoRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Статус: Все'));
      await tester.pumpAndSettle();

      // Именно пункт меню, а не плашка статуса в строке DEV-2 с тем же
      // текстом: иначе тест ловит не то, что проверяет.
      await tester.tap(
        find.descendant(
          of: find.byType(CheckboxMenuButton),
          matching: find.text('Открыт'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/queues/DEV?status=open',
      );
    });

    testWidgets('стрелка и Enter открывают задачу под курсором', (
      tester,
    ) async {
      final router = await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [
            fakeIssueRow(key: 'DEV-1'),
            fakeIssueRow(key: 'DEV-2'),
          ],
          role: IssueListDtoRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      final rows = tester.widgetList<SLIssueRow>(find.byType(SLIssueRow));
      expect(rows.where((row) => row.focused).single.issueKey, 'DEV-2');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/issues/DEV-2',
      );
    });

    testWidgets('клик по строке открывает задачу', (tester) async {
      final router = await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [fakeIssueRow(key: 'DEV-7')],
          role: IssueListDtoRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SLIssueRow));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/issues/DEV-7',
      );
    });

    testWidgets('на телефоне панель сворачивается, а кнопка становится FAB', (
      tester,
    ) async {
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [fakeIssueRow(key: 'DEV-1', title: 'Починить экспорт')],
          role: IssueListDtoRole.admin,
        ),
        windowSize: const Size(400, 800),
      );
      await tester.pumpAndSettle();

      expect(find.text('Фильтры'), findsOneWidget);
      expect(find.textContaining('Статус:'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // Заголовков колонок на телефоне нет, строки становятся карточками 56.
      expect(find.text('КЛЮЧ'), findsNothing);
      expect(
        tester.widget<SLIssueRow>(find.byType(SLIssueRow)).layout,
        SLIssueRowLayout.phone,
      );
    });

    testWidgets('на планшете счётчик уходит, а строка становится выше', (
      tester,
    ) async {
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [fakeIssueRow(key: 'DEV-1')],
          role: IssueListDtoRole.admin,
        ),
        windowSize: const Size(900, 800),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Показано'), findsNothing);
      expect(find.text('КЛЮЧ'), findsOneWidget);
      expect(tester.widget<SLIssueRow>(find.byType(SLIssueRow)).layout.extent, 40);
    });

    testWidgets('колонки отбрасываются по ширине области, а не по окну', (
      tester,
    ) async {
      // Окно 830: места на всё не хватает, и первой уходит сложность.
      // Имя исполнителя при этом остаётся — порядок отбрасывания продуман.
      await pumpQueue(
        tester,
        queues: FakeQueuesRepository(),
        issues: FakeIssuesRepository(
          issues: [fakeIssueRow(key: 'DEV-1')],
          role: IssueListDtoRole.admin,
        ),
        windowSize: const Size(830, 800),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<SLIssueRow>(find.byType(SLIssueRow)).layout.columns,
        SLIssueColumnSet.withoutComplexity,
      );
      expect(find.text('ИСПОЛНИТЕЛЬ'), findsOneWidget);
      expect(find.text('С'), findsNothing);
    });

    testWidgets('таблицу обмеряет один LayoutBuilder, а не каждая строка', (
      tester,
    ) async {
      // Прямая защита от того, чем это можно сломать: `LayoutBuilder`
      // внутри строки убивает виртуализацию.
      final issues = FakeIssuesRepository(
        issues: [for (var i = 1; i <= 200; i++) fakeIssueRow(key: 'DEV-$i')],
        role: IssueListDtoRole.admin,
      )..pageSize = 200;

      await pumpQueue(tester, queues: FakeQueuesRepository(), issues: issues);
      await tester.pumpAndSettle();

      final rows = tester.widgetList<SLIssueRow>(find.byType(SLIssueRow));
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(
          find.descendant(
            of: find.byWidget(row),
            matching: find.byType(LayoutBuilder),
          ),
          findsNothing,
        );
      }
    });
  });
}
