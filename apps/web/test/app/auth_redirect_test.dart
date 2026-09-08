import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_router.dart';
import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/unauthorized_notifier.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_screen.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_screen.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/pump_widget.dart';

const _unauthorized = ApiFailure(
  kind: ApiFailureKind.unauthorized,
  statusCode: 401,
  code: 'session_required',
);

/// Поднимает приложение по адресу [location] и доводит сессию до ответа
/// сервера — ровно так, как это происходит при заходе по ссылке.
Future<(GoRouter, ProviderContainer)> pumpAppAt(
  WidgetTester tester,
  String location, {
  required FakeAuthRepository repository,
}) async {
  useWindowSize(tester, const Size(1280, 800));

  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  router.go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: SLThemeData.light, routerConfig: router),
    ),
  );

  await container.read(sessionControllerProvider.notifier).load();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return (router, container);
}

String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('редирект по состоянию сессии', () {
    testWidgets('без сессии глубокая ссылка ведёт на вход и помнит цель', (
      tester,
    ) async {
      final (router, _) = await pumpAppAt(
        tester,
        '/issues/SL-123',
        repository: FakeAuthRepository(meFailure: _unauthorized),
      );

      expect(locationOf(router), '/login?next=%2Fissues%2FSL-123');
      expect(find.byType(LoginScreen), findsOneWidget);
      // Цель доехала до экрана: после входа человек попадёт на задачу.
      expect(
        tester.widget<LoginScreen>(find.byType(LoginScreen)).next,
        '/issues/SL-123',
      );
    });

    testWidgets('экран входа без сессии никуда не уводит', (tester) async {
      final (router, _) = await pumpAppAt(
        tester,
        AppRoutes.login,
        repository: FakeAuthRepository(meFailure: _unauthorized),
      );

      expect(locationOf(router), AppRoutes.login);
    });

    testWidgets('экран отказа доступен без сессии: она там и не создаётся', (
      tester,
    ) async {
      final (router, _) = await pumpAppAt(
        tester,
        '/access-denied?ticket=abc',
        repository: FakeAuthRepository(meFailure: _unauthorized),
      );

      expect(locationOf(router), '/access-denied?ticket=abc');
    });

    testWidgets('вошедшему на экране входа делать нечего', (tester) async {
      final (router, _) = await pumpAppAt(
        tester,
        AppRoutes.login,
        repository: FakeAuthRepository(meResult: fakeMe()),
      );

      expect(locationOf(router), AppRoutes.projects);
      expect(find.byType(ProjectsScreen), findsOneWidget);
    });

    testWidgets('после входа человек возвращается к цели (US-01)', (
      tester,
    ) async {
      final (router, _) = await pumpAppAt(
        tester,
        '/login?next=%2Fqueues%2FSL',
        repository: FakeAuthRepository(meResult: fakeMe()),
      );

      expect(locationOf(router), '/queues/SL');
    });

    testWidgets('чужой адрес в next игнорируется', (tester) async {
      final (router, _) = await pumpAppAt(
        tester,
        '/login?next=%2F%2Fevil.example%2Fsteal',
        repository: FakeAuthRepository(meResult: fakeMe()),
      );

      expect(locationOf(router), AppRoutes.projects);
    });

    testWidgets('погашенная сессия уводит на вход с пометкой (US-02)', (
      tester,
    ) async {
      final (router, container) = await pumpAppAt(
        tester,
        '/queues/SL',
        repository: FakeAuthRepository(meResult: fakeMe()),
      );

      expect(locationOf(router), '/queues/SL');

      // Так выглядит отзыв доступа из открытой вкладки (US-09).
      container.read(unauthorizedNotifierProvider).fire();
      await tester.pump();
      await tester.pump();

      expect(locationOf(router), contains('reason=expired'));
      expect(
        tester.widget<LoginScreen>(find.byType(LoginScreen)).sessionExpired,
        isTrue,
      );
    });
  });

  group('разбор адреса возврата', () {
    test('принимается только путь внутри приложения', () {
      expect(safeNextLocation('/issues/SL-1'), '/issues/SL-1');
      expect(safeNextLocation(null), AppRoutes.projects);
      expect(safeNextLocation('//evil.example'), AppRoutes.projects);
      expect(safeNextLocation('https://evil.example'), AppRoutes.projects);
    });

    test('токен приглашения достаётся из адреса возврата (US-21)', () {
      expect(inviteTokenOf('/invite/abcdefghijklmnop1234'), isNotNull);
      expect(inviteTokenOf('/issues/SL-1'), isNull);
      expect(inviteTokenOf('/invite/short'), isNull);
      expect(inviteTokenOf(null), isNull);
    });
  });
}
