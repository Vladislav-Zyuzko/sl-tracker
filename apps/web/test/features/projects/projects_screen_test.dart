import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_card.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

import '../../helpers/fake_project_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран списка проектов внутри настоящего роутера.
Future<GoRouter> pumpProjects(
  WidgetTester tester,
  FakeProjectsRepository repository, {
  Size windowSize = const Size(1280, 800),
}) => pumpWithRouter(
  tester,
  windowSize: windowSize,
  overrides: [projectsRepositoryProvider.overrideWithValue(repository)],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: ProjectsScreen()),
    ),
    GoRoute(
      path: '/projects/:slug',
      builder: (context, state) =>
          Scaffold(body: Text('проект ${state.pathParameters['slug']}')),
    ),
  ],
);

void main() {
  group('экран «Мои проекты»', () {
    testWidgets('пока грузится — скелетон карточек, а не спиннер', (
      tester,
    ) async {
      final repository = FakeProjectsRepository()..gate = Completer<void>();

      await pumpProjects(tester, repository);
      await tester.pump();

      expect(find.byType(SLSkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repository.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('пусто — объясняет, как попасть в чужой проект', (
      tester,
    ) async {
      await pumpProjects(tester, FakeProjectsRepository());
      await tester.pumpAndSettle();

      expect(find.text('У вас пока нет проектов'), findsOneWidget);
      expect(
        find.textContaining('в чужой проект попадают только по ней'),
        findsOneWidget,
      );
    });

    testWidgets('ошибка загрузки предлагает повтор', (tester) async {
      final repository = FakeProjectsRepository(
        listFailure: const ApiFailure(kind: ApiFailureKind.network),
      );

      await pumpProjects(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить проекты'), findsOneWidget);
      expect(find.byType(SLErrorState), findsOneWidget);

      repository.listFailure = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('У вас пока нет проектов'), findsOneWidget);
    });

    testWidgets('карточка показывает название, описание и роль', (
      tester,
    ) async {
      await pumpProjects(
        tester,
        FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sweet Limit'), findsOneWidget);
      expect(find.text('Мобильное приложение для команды'), findsOneWidget);
      // Роль на этом экране показывается всегда — она отвечает на вопрос
      // «куда я могу вносить изменения».
      expect(find.text('Админ'), findsOneWidget);
    });

    testWidgets('пустое описание не ломает высоту карточки', (tester) async {
      await pumpProjects(
        tester,
        FakeProjectsRepository(projects: [fakeProject(description: null)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ProjectCard)).height,
        ProjectCard.defaultHeight,
      );
    });

    testWidgets('клик по карточке открывает проект', (tester) async {
      final router = await pumpProjects(
        tester,
        FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProjectCard));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sweet-limit',
      );
    });
  });

  group('создание проекта', () {
    testWidgets('предпросмотр адреса считается по мере ввода названия', (
      tester,
    ) async {
      await pumpProjects(tester, FakeProjectsRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Создать проект').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Сладкий Лимит 2026!',
      );
      await tester.pump();

      expect(find.text('/projects/sladkiy-limit-2026'), findsOneWidget);
      expect(find.text('Адрес проекта будет:'), findsOneWidget);
    });

    testWidgets('после создания открывается адрес из ответа сервера', (
      tester,
    ) async {
      // Сервер добавил суффикс из-за коллизии: переходить нужно на его
      // значение, а не на клиентский предпросмотр (D-35).
      final router = await pumpProjects(tester, FakeProjectsRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Создать проект').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Сладкий Лимит');
      await tester.pump();
      expect(find.text('/projects/sladkiy-limit'), findsOneWidget);

      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sladkiy-limit-2',
      );
    });

    testWidgets('пустое название не отправляется на сервер', (tester) async {
      await pumpProjects(tester, FakeProjectsRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Создать проект').first);
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Создать'),
      );

      expect(button.onPressed, isNull);
    });
  });
}
