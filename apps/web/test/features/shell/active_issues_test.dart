import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_row.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/shell/presentation/active_issues_providers.dart';
import 'package:sl_tracker_web/features/shell/presentation/shell_sidebar.dart';
import 'package:sl_tracker_web/features/shell/presentation/widgets/active_issue_row.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/pump_widget.dart';

void main() {
  group('мои активные задачи', () {
    ProviderContainer containerWith(FakeIssuesRepository repository) {
      final container = ProviderContainer(
        overrides: [issuesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      return container;
    }

    test('первый запрос уходит без поискового параметра', () async {
      final repository = FakeIssuesRepository()
        ..myIssues = [fakeMyIssue(key: 'DEV-42')];
      final container = containerWith(repository);

      final page = await container.read(activeIssuesProvider.future);

      expect(page.items.single.key, 'DEV-42');
      expect(page.total, 1);
      expect(repository.searchQueries, ['']);
    });

    test('поиск выполняет сервер, а не клиент', () async {
      // D-20: фильтровать загруженную страницу на клиенте нельзя — за её
      // пределами останется ровно то, что человек ищет.
      final repository = FakeIssuesRepository()
        ..myIssues = [fakeMyIssue(key: 'DEV-42')];
      final container = containerWith(repository);
      await container.read(activeIssuesProvider.future);

      container.read(activeIssuesSearchProvider.notifier).search('  csv  ');
      await container.read(activeIssuesProvider.future);

      expect(repository.searchQueries, ['', 'csv']);
    });

    test('назначение себя исполнителем перечитывает список сайдбара', () async {
      // Живой дефект: человек назначил себя исполнителем на экране задачи,
      // а «мои активные задачи» в сайдбаре остались прежними. Событие
      // `issue.updated` приходит только в тему `issue:<KEY>`
      // (`docs/api/websocket.md`, 5), на которую сайдбар не подписан, —
      // значит сигнал обязан дать сам экран задачи.
      final repository = FakeIssuesRepository()
        ..issue = fakeIssue()
        ..myIssues = [];
      final container = containerWith(repository);

      final before = await container.read(activeIssuesProvider.future);
      expect(before.items, isEmpty);
      expect(repository.searchQueries, hasLength(1));

      // Экран задачи открыт: правка идёт от загруженной задачи.
      await container.read(issueProvider('DEV-42').future);

      // Сервер начал отдавать задачу как мою активную.
      repository.myIssues = [fakeMyIssue(key: 'DEV-42')];

      await container
          .read(issueProvider('DEV-42').notifier)
          .changeAssignee(
            const IssueUserDto(id: 'me', displayName: 'Я', avatarUrl: null),
          );

      final after = await container.read(activeIssuesProvider.future);

      expect(
        repository.searchQueries,
        hasLength(2),
        reason: 'список перечитан',
      );
      expect(after.items.single.key, 'DEV-42');
    });

    test('смена сложности список сайдбара не трогает', () async {
      // Перечитываем не на всякую правку, а только на ту, что меняет состав
      // или порядок списка: лишний запрос на каждое движение мыши не нужен.
      final repository = FakeIssuesRepository()
        ..issue = fakeIssue()
        ..myIssues = [fakeMyIssue(key: 'DEV-42')];
      final container = containerWith(repository);

      await container.read(activeIssuesProvider.future);
      await container.read(issueProvider('DEV-42').future);
      await container
          .read(issueProvider('DEV-42').notifier)
          .changeStoryPoints(5);
      await container.read(activeIssuesProvider.future);

      expect(repository.searchQueries, hasLength(1));
    });

    test('сбой списка не выбрасывает исключение наружу', () async {
      final repository = FakeIssuesRepository()
        ..myActiveFailure = const ApiFailure(kind: ApiFailureKind.network);
      final container = containerWith(repository);

      await expectLater(
        container.read(activeIssuesProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      expect(container.read(activeIssuesProvider).hasError, isTrue);
    });
  });

  group('сайдбар', () {
    Future<void> pumpSidebar(
      WidgetTester tester, {
      required ActiveIssuesState state,
      List<MyIssue> issues = const [],
      String searchQuery = '',
      int? count,
      String? selectedIssueKey,
    }) => pumpWithProviders(
      tester,
      Scaffold(
        body: Row(
          children: [
            ShellSidebar(
              collapsed: false,
              onToggleCollapsed: () {},
              onOpenProjects: () {},
              searchFocusNode: FocusNode(),
              onSearchChanged: (_) {},
              state: state,
              issues: issues,
              activeIssuesCount: count,
              searchQuery: searchQuery,
              selectedIssueKey: selectedIssueKey,
            ),
          ],
        ),
      ),
    );

    testWidgets('плейсхолдер называет область поиска целиком', (tester) async {
      // Обрезанный до «Поиск» плейсхолдер и создаёт ощущение поломки
      // (`app-shell.md`, «Поиск: главный риск экрана»).
      await pumpSidebar(tester, state: ActiveIssuesState.loading);

      expect(find.text('Поиск по моим активным задачам'), findsOneWidget);
    });

    testWidgets('подпись о границах поиска появляется только с запросом', (
      tester,
    ) async {
      await pumpSidebar(tester, state: ActiveIssuesState.loading);
      expect(find.text('Ищем только среди ваших активных задач'), findsNothing);

      await pumpSidebar(
        tester,
        state: ActiveIssuesState.data,
        issues: [
          const MyIssue(
            key: 'DEV-1',
            title: 'Задача',
            status: fakeStatusInProgress,
            priority: 50,
          ),
        ],
        searchQuery: 'csv',
      );

      expect(
        find.text('Ищем только среди ваших активных задач'),
        findsOneWidget,
      );
    });

    testWidgets('строки задач показывают ключ и тему', (tester) async {
      await pumpSidebar(
        tester,
        state: ActiveIssuesState.data,
        count: 2,
        selectedIssueKey: 'DEV-42',
        issues: const [
          MyIssue(
            key: 'DEV-42',
            title: 'Починить экспорт CSV',
            status: fakeStatusInProgress,
            priority: 80,
          ),
          MyIssue(
            key: 'WEB-7',
            title: 'Вёрстка шапки',
            status: fakeStatusInProgress,
            priority: 20,
          ),
        ],
      );

      expect(find.byType(ActiveIssueRow), findsNWidgets(2));
      expect(find.text('DEV-42'), findsOneWidget);
      expect(find.text('Починить экспорт CSV'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      final selected = tester
          .widgetList<ActiveIssueRow>(find.byType(ActiveIssueRow))
          .where((row) => row.isSelected);
      expect(selected.single.issue.key, 'DEV-42');
    });

    testWidgets('пустой поиск объясняет границы поиска', (tester) async {
      await pumpSidebar(
        tester,
        state: ActiveIssuesState.searchEmpty,
        searchQuery: 'csv',
      );

      expect(
        find.text('Ничего не найдено среди ваших активных задач'),
        findsOneWidget,
      );
      expect(find.text('Очистить поиск'), findsOneWidget);
    });

    testWidgets('пустой список и ошибка — разные сообщения', (tester) async {
      await pumpSidebar(tester, state: ActiveIssuesState.empty);
      expect(find.text('Нет активных задач'), findsOneWidget);

      await pumpSidebar(tester, state: ActiveIssuesState.error);
      expect(find.text('Не удалось загрузить задачи'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('двести задач не строятся все сразу', (tester) async {
      await pumpSidebar(
        tester,
        state: ActiveIssuesState.data,
        count: 200,
        issues: [
          for (var i = 1; i <= 200; i++)
            MyIssue(
              key: 'DEV-$i',
              title: 'Задача $i',
              status: fakeStatusInProgress,
              priority: 50,
            ),
        ],
      );

      expect(
        tester.widgetList<ActiveIssueRow>(find.byType(ActiveIssueRow)).length,
        lessThan(60),
      );
    });
  });
}
