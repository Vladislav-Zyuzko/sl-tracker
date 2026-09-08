import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/unauthorized_notifier.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/domain/session.dart';
import 'package:sl_tracker_web/features/auth/domain/session_state.dart';

/// Состояние сессии приложения.
///
/// Единственный владелец ответа `GET /api/me`. Источников смены состояния два:
/// явная проверка при старте ([SessionController.load]) и сигнал 401
/// от HTTP-клиента.
final sessionControllerProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

/// Контроллер состояния сессии.
class SessionController extends Notifier<Session> {
  @override
  Session build() {
    // На 401 приложение реагирует одинаково, откуда бы запрос ни пришёл.
    // Подписка на отдельный сигнал, а не на HTTP-клиент напрямую, разрывает
    // круг «клиенту нужна сессия — сессии нужен клиент».
    final unauthorized = ref.watch(unauthorizedNotifierProvider);
    unauthorized.addListener(_onUnauthorized);
    ref.onDispose(() => unauthorized.removeListener(_onUnauthorized));

    return const Session.unknown();
  }

  /// Проверяет сессию запросом `GET /api/me`.
  ///
  /// Вызывается при старте приложения и после возврата из Яндекс ID.
  /// Повторный вызов во время проверки игнорируется: два одинаковых запроса
  /// на старте не нужны никому.
  Future<void> load() async {
    if (state.state == SessionState.checking) return;

    final previousUser = state.user;
    state = Session(state: SessionState.checking, user: previousUser);

    try {
      state = Session.authenticated(
        await ref.read(authRepositoryProvider).me(),
      );
    } on ApiFailure catch (failure) {
      state = switch (failure.kind) {
        // Честный «сессии нет»: сюда же приходит отзыв доступа (US-09).
        ApiFailureKind.unauthorized => Session(
          state: previousUser == null
              ? SessionState.anonymous
              : SessionState.expired,
        ),
        // Сеть или сервер. Внутрь не пускаем, но и молчать нельзя: причина
        // доедет до экрана входа и станет баннером, а не пустым экраном.
        _ => Session.anonymous(failure: failure),
      };
    }
  }

  /// Выход по кнопке.
  ///
  /// Ошибку не глотает: экран показывает тост «Не удалось выйти» с повтором.
  /// Состояние сбрасывается только после успешного ответа сервера — иначе
  /// интерфейс уверял бы, что человек вышел, когда сессия на сервере жива.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Session.anonymous();
  }

  /// Сервер ответил 401 на любой запрос.
  ///
  /// Различаем два случая: сессия была и истекла — на экране входа человека
  /// встретит баннер «Сессия истекла» (US-02); сессии не было вовсе —
  /// обычный вход.
  void _onUnauthorized() {
    if (state.isSignedOut) return;

    state = Session(
      state: state.user == null ? SessionState.anonymous : SessionState.expired,
    );
  }
}
