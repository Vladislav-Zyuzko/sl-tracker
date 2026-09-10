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
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/pump_widget.dart';
import '../../helpers/search_field_geometry.dart';

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

    testWidgets('плейсхолдер говорит, что вводить, а область — заголовок', (
      tester,
    ) async {
      // Прежний плейсхолдер «Поиск по моим активным задачам» занимал
      // ≈ 207 px при 184 px места и обрезался. Область поиска теперь
      // называет постоянно видимый заголовок над полем
      // (`components.md`, 4.2, `app-shell.md`).
      await pumpSidebar(tester, state: ActiveIssuesState.loading);

      expect(find.text('Название или ключ'), findsOneWidget);
      expect(find.text('Поиск по моим активным задачам'), findsNothing);
      expect(find.text('МОИ АКТИВНЫЕ ЗАДАЧИ'), findsOneWidget);

      // Заголовок стоит именно **над** полем, а не под ним: иначе он
      // не объясняет ничего.
      expect(
        tester.getTopLeft(find.text('МОИ АКТИВНЫЕ ЗАДАЧИ')).dy,
        lessThan(tester.getTopLeft(find.byType(SLSearchField)).dy),
      );
    });

    testWidgets('ширина сайдбара — одно число на все случаи, 280', (
      tester,
    ) async {
      await pumpSidebar(tester, state: ActiveIssuesState.loading);

      expect(
        tester.getSize(find.byType(ShellSidebar)).width,
        SLSizes.sidebarWidth,
      );
      expect(SLSizes.sidebarWidth, 280);
    });

    testWidgets('поле поиска высотой 36 — вровень со строкой списка', (
      tester,
    ) async {
      // Контрол ниже строк, которые он фильтрует, читается как
      // подчинённый им (`system.md`, 10.3.1).
      await pumpSidebar(tester, state: ActiveIssuesState.loading);

      final field = tester.getSize(find.byType(SLSearchField));
      expect(field.height, 36);
      expect(field.height, ShellSidebar.issueRowExtent);

      // Ширина сайдбара 280, поля — 280 − 2 · space2 = 264 минус пиксель
      // на правую границу самого сайдбара. Главное — что это больше
      // минимальных 240 из 10.3.1, и плейсхолдер помещается целиком.
      expect(
        field.width,
        closeTo(SLSizes.sidebarWidth - 2 * SLSpacing.space2, 1),
      );
      expect(field.width, greaterThanOrEqualTo(SLSizes.searchFieldMinWidth));
    });

    testWidgets('рамка поиска одного размера во всех состояниях', (
      tester,
    ) async {
      // Дефект с боевого стенда: пустое поле было низким — рамка 18 внутри
      // коробки 36 — и вырастало до 24, когда появлялась кнопка очистки.
      // Рамка обязана быть 264 × 36, вровень со строкой списка, что бы
      // ни стояло справа (`app-shell.md`, `components.md` 4.1).
      await pumpSidebar(tester, state: ActiveIssuesState.loading);
      expect(find.text('/'), findsOneWidget);

      final frames = await searchFieldFramesByState(tester);

      for (final MapEntry(key: state, value: frame) in frames.entries) {
        expect(
          frame.height,
          ShellSidebar.issueRowExtent,
          reason: 'высота рамки в состоянии «$state»',
        );
        // 280 − 2 · space2 = 264 минус пиксель правой границы сайдбара —
        // та же поправка, что в проверке выше.
        expect(
          frame.width,
          closeTo(SLSizes.sidebarWidth - 2 * SLSpacing.space2, 1),
          reason: 'ширина рамки в состоянии «$state»',
        );
      }
      expectFrameFillsField(tester, frames);
    });

    testWidgets('подпись о границах поиска появляется только с запросом', (
      tester,
    ) async {
      await pumpSidebar(tester, state: ActiveIssuesState.loading);
      expect(find.text(ShellSidebar.searchScopeNotice), findsNothing);

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
        find.text(ShellSidebar.searchScopeNotice),
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
