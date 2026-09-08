import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/unauthorized_notifier.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/domain/session_state.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';

import '../../helpers/fake_repositories.dart';

ProviderContainer containerWith(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  return container;
}

void main() {
  group('SessionController', () {
    test('до проверки состояние — «неизвестно»', () {
      final container = containerWith(FakeAuthRepository(meResult: fakeMe()));

      expect(
        container.read(sessionControllerProvider).state,
        SessionState.unknown,
      );
    });

    test('успешный /api/me делает пользователя вошедшим', () async {
      final repository = FakeAuthRepository(meResult: fakeMe());
      final container = containerWith(repository);

      await container.read(sessionControllerProvider.notifier).load();
      final session = container.read(sessionControllerProvider);

      expect(session.state, SessionState.authenticated);
      expect(session.user?.email, 'anna@yandex.ru');
      expect(session.canManageAccessList, isTrue);
      expect(repository.meCalls, 1);
    });

    test('401 без предыдущей сессии — обычный вход, без «истекла»', () async {
      final container = containerWith(
        FakeAuthRepository(
          meFailure: const ApiFailure(
            kind: ApiFailureKind.unauthorized,
            statusCode: 401,
            code: 'session_required',
          ),
        ),
      );

      await container.read(sessionControllerProvider.notifier).load();
      final session = container.read(sessionControllerProvider);

      expect(session.state, SessionState.anonymous);
      expect(session.user, isNull);
      // Сбоя не было — баннера на экране входа быть не должно.
      expect(session.failure, isNull);
    });

    test(
      'сбой сети не выдаётся за «сессии нет»: причина сохраняется',
      () async {
        final container = containerWith(
          FakeAuthRepository(
            meFailure: const ApiFailure(kind: ApiFailureKind.network),
          ),
        );

        await container.read(sessionControllerProvider.notifier).load();
        final session = container.read(sessionControllerProvider);

        expect(session.state, SessionState.anonymous);
        expect(session.failure?.kind, ApiFailureKind.network);
      },
    );

    test('401 после успешного входа — это «сессия истекла» (US-02)', () async {
      final repository = FakeAuthRepository(meResult: fakeMe());
      final container = containerWith(repository);

      await container.read(sessionControllerProvider.notifier).load();
      expect(
        container.read(sessionControllerProvider).state,
        SessionState.authenticated,
      );

      // Так это выглядит из HTTP-клиента: любой запрос вернул 401.
      container.read(unauthorizedNotifierProvider).fire();

      expect(
        container.read(sessionControllerProvider).state,
        SessionState.expired,
      );
    });

    test('после выхода 401 больше не считается истёкшей сессией', () async {
      final repository = FakeAuthRepository(meResult: fakeMe());
      final container = containerWith(repository);

      await container.read(sessionControllerProvider.notifier).load();
      await container.read(sessionControllerProvider.notifier).signOut();

      expect(repository.logoutCalls, 1);
      expect(
        container.read(sessionControllerProvider).state,
        SessionState.anonymous,
      );

      container.read(unauthorizedNotifierProvider).fire();
      expect(
        container.read(sessionControllerProvider).state,
        SessionState.anonymous,
      );
    });

    test('неудачный выход не делает вид, что человек вышел', () async {
      final repository = FakeAuthRepository(
        meResult: fakeMe(),
        logoutFailure: const ApiFailure(kind: ApiFailureKind.network),
      );
      final container = containerWith(repository);

      await container.read(sessionControllerProvider.notifier).load();

      await expectLater(
        container.read(sessionControllerProvider.notifier).signOut(),
        throwsA(isA<ApiFailure>()),
      );
      expect(
        container.read(sessionControllerProvider).state,
        SessionState.authenticated,
      );
    });
  });
}
