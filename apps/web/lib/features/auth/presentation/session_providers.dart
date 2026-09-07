import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/features/auth/domain/session_state.dart';

/// Состояние сессии приложения.
///
/// Пока источник состояния только один — интерсептор HTTP-клиента, который
/// зовёт [SessionController.expire] на 401. Запрос `GET /api/me`, который
/// переводит состояние в [SessionState.authenticated], появится, когда будет
/// зафиксирован контракт `/api/me`: сейчас его в `docs/api/openapi.json` нет.
final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Контроллер состояния сессии.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState.unknown;

  /// Отмечает, что проверка сессии началась.
  void startChecking() => state = SessionState.checking;

  /// Пользователь внутри.
  void authenticated() => state = SessionState.authenticated;

  /// Сервер ответил 401.
  ///
  /// Различаем два случая: сессия была и истекла — тогда нужна модалка
  /// «Войдите снова» поверх экрана; сессии не было вовсе — обычный уход
  /// на экран входа.
  void expire() {
    state = state == SessionState.authenticated
        ? SessionState.expired
        : SessionState.anonymous;
  }

  /// Пользователь вышел сам.
  void signOut() => state = SessionState.anonymous;
}
