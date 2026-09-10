import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_notice.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_screen.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/yandex_id_button.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

import '../../helpers/fake_platform.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран входа в состоянии «сессии нет».
///
/// Именно так экран видит неаутентифицированный человек: приложение уже
/// сходило за `GET /api/me` и получило 401.
Future<ProviderContainer> pumpLogin(
  WidgetTester tester,
  LoginScreen screen, {
  BrowserNavigator? navigator,
}) async {
  final container = await pumpWithProviders(
    tester,
    screen,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          meFailure: const ApiFailure(
            kind: ApiFailureKind.unauthorized,
            statusCode: 401,
          ),
        ),
      ),
      if (navigator != null)
        browserNavigatorProvider.overrideWithValue(navigator),
    ],
  );

  await container.read(sessionControllerProvider.notifier).load();
  await tester.pump();

  return container;
}

void main() {
  group('экран входа', () {
    testWidgets('кнопка уводит на /api/auth/yandex/start полным переходом', (
      tester,
    ) async {
      final navigator = RecordingBrowserNavigator();

      await pumpLogin(tester, const LoginScreen(), navigator: navigator);

      await tester.tap(find.text(YandexIdButton.label));
      await tester.pump();

      expect(navigator.urls, ['/api/auth/yandex/start']);
    });

    testWidgets('адрес назначения уезжает параметром next (US-01)', (
      tester,
    ) async {
      final navigator = RecordingBrowserNavigator();

      await pumpLogin(
        tester,
        const LoginScreen(next: '/issues/SL-123'),
        navigator: navigator,
      );

      await tester.tap(find.text(YandexIdButton.label));
      await tester.pump();

      expect(
        navigator.urls.single,
        '/api/auth/yandex/start?next=%2Fissues%2FSL-123',
      );
    });

    testWidgets('повторное нажатие второй раз браузер не уводит', (
      tester,
    ) async {
      final navigator = RecordingBrowserNavigator();

      await pumpLogin(tester, const LoginScreen(), navigator: navigator);

      await tester.tap(find.text(YandexIdButton.label));
      await tester.pump();
      await tester.tap(find.byType(LoginScreen));
      await tester.pump();

      expect(navigator.urls.length, 1);
    });

    testWidgets('отказ в Яндексе объясняется спокойно, а не как поломка', (
      tester,
    ) async {
      await pumpLogin(tester, const LoginScreen(errorCode: 'access_denied'));

      expect(find.text('Вход отменён'), findsOneWidget);
      expect(
        tester.widget<SLBanner>(find.byType(SLBanner)).variant,
        SLBannerVariant.info,
      );
      // Код показывается только под «Подробности» — на экране его нет.
      expect(find.text('access_denied'), findsNothing);

      await tester.tap(find.text('Подробности'));
      await tester.pump();
      expect(find.text('access_denied'), findsOneWidget);
    });

    testWidgets('немодерированное приложение — предупреждение, не ошибка', (
      tester,
    ) async {
      await pumpLogin(
        tester,
        const LoginScreen(errorCode: 'unauthorized_client'),
      );

      expect(find.text('Вход временно недоступен'), findsOneWidget);
      expect(
        tester.widget<SLBanner>(find.byType(SLBanner)).variant,
        SLBannerVariant.warning,
      );
    });

    testWidgets('ненастроенный вход отключает кнопку', (tester) async {
      // Единственный код, при котором повтор гарантированно бессмыслен:
      // ненастроенный OAuth сам не рассосётся (`screens/login.md`).
      await pumpLogin(
        tester,
        const LoginScreen(errorCode: 'oauth_not_configured'),
      );

      expect(find.text('Вход не настроен'), findsOneWidget);
      expect(
        find.text(
          'На этом сервере не настроен вход через Яндекс ID. '
          'Это чинится администратором, повторять попытку бесполезно.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<SLBanner>(find.byType(SLBanner)).variant,
        SLBannerVariant.warning,
      );

      final button = tester.widget<YandexIdButton>(find.byType(YandexIdButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('при остальных кодах кнопка остаётся рабочей', (tester) async {
      final navigator = RecordingBrowserNavigator();
      await pumpLogin(
        tester,
        const LoginScreen(errorCode: 'access_denied'),
        navigator: navigator,
      );

      await tester.tap(find.text(YandexIdButton.label));
      await tester.pump();

      expect(navigator.urls, hasLength(1));
    });

    testWidgets('истёкшая сессия объявляется отдельно (US-02)', (tester) async {
      await pumpLogin(tester, const LoginScreen(sessionExpired: true));

      expect(find.text('Сессия истекла'), findsOneWidget);
    });

    testWidgets('сбой проверки сессии становится баннером', (tester) async {
      final container = await pumpWithProviders(
        tester,
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              meFailure: const ApiFailure(
                kind: ApiFailureKind.server,
                statusCode: 502,
              ),
            ),
          ),
        ],
      );

      await container.read(sessionControllerProvider.notifier).load();
      await tester.pump();

      expect(find.text('Не удалось войти'), findsOneWidget);
      expect(
        find.text('Проверьте соединение и попробуйте ещё раз.'),
        findsOneWidget,
      );
    });

    testWidgets('пока сессия проверяется, вместо кнопки — «Завершаем вход»', (
      tester,
    ) async {
      // Состояние «неизвестно» — ровно то, в котором приложение только что
      // вернулось из Яндекса и ещё не спросило `GET /api/me`.
      await pumpWithProviders(tester, const LoginScreen());

      expect(find.text('Завершаем вход…'), findsOneWidget);
      expect(find.text(YandexIdButton.label), findsNothing);
    });
  });

  group('тексты ошибок входа', () {
    test('каждый код контракта имеет свой текст', () {
      const codes = [
        'access_denied',
        'unauthorized_client',
        'invalid_state',
        'provider_unavailable',
        'oauth_not_configured',
        'server_error',
      ];

      for (final code in codes) {
        final notice = LoginNotice.ofOAuthError(code);

        expect(notice.title, isNotEmpty, reason: code);
        expect(notice.description, isNotEmpty, reason: code);
        expect(notice.details, code);
      }
    });

    test('кнопку блокирует ровно один код', () {
      const codes = [
        'access_denied',
        'unauthorized_client',
        'invalid_state',
        'provider_unavailable',
        'server_error',
      ];

      for (final code in codes) {
        expect(
          LoginNotice.ofOAuthError(code).blocksSignIn,
          isFalse,
          reason: code,
        );
      }

      expect(
        LoginNotice.ofOAuthError('oauth_not_configured').blocksSignIn,
        isTrue,
      );
    });

    test('неизвестный код не оставляет пользователя без объяснения', () {
      final notice = LoginNotice.ofOAuthError('что-то новое');

      expect(notice.title, 'Не удалось войти');
      expect(notice.variant, SLBannerVariant.danger);
    });

    test('401 баннера не порождает: это обычный вход, а не сбой', () {
      expect(
        LoginNotice.ofFailure(
          const ApiFailure(kind: ApiFailureKind.unauthorized),
        ),
        isNull,
      );
    });
  });
}
