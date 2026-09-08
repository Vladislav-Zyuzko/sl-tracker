import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/auth/domain/session_state.dart';

/// Всё, что приложение знает о текущей сессии.
///
/// Сама сессия живёт в httpOnly cookie и клиенту не видна (ADR-0001):
/// здесь — только результат запроса `GET /api/me` и причина, по которой
/// его не удалось получить.
@immutable
class Session {
  /// @nodoc
  const Session({required this.state, this.user, this.failure});

  /// Приложение только запустилось, проверка ещё не начиналась.
  const Session.unknown() : this(state: SessionState.unknown);

  /// Пользователь внутри.
  const Session.authenticated(MeResponseDto user)
    : this(state: SessionState.authenticated, user: user);

  /// Сессии нет. [failure] заполнен, если причина — не 401, а сбой связи:
  /// экран входа покажет по нему баннер, а не сделает вид, что всё в порядке.
  const Session.anonymous({ApiFailure? failure})
    : this(state: SessionState.anonymous, failure: failure);

  /// @nodoc
  final SessionState state;

  /// Профиль текущего пользователя. `null` — пользователь не установлен.
  ///
  /// Во время повторной проверки сохраняется: интерфейс не должен схлопывать
  /// имя и аватар в скелетон каждый раз, когда сессия перепроверяется.
  final MeResponseDto? user;

  /// Почему проверка не удалась. `null` — либо всё хорошо, либо честный 401.
  final ApiFailure? failure;

  /// Пользователь внутри и его профиль известен.
  bool get isAuthenticated => state == SessionState.authenticated;

  /// Сессии нет: вход или истёкшая сессия.
  bool get isSignedOut =>
      state == SessionState.anonymous || state == SessionState.expired;

  /// Проверка ещё идёт или не начиналась — уводить куда-либо рано.
  bool get isResolving =>
      state == SessionState.unknown || state == SessionState.checking;

  /// Показывать ли пункт «Доступ к трекеру».
  ///
  /// Флаг приходит с сервера готовым: клиент не вычисляет право сам
  /// (`docs/design/screens/access-list.md`, Q-D30).
  bool get canManageAccessList => user?.canManageAccessList ?? false;

  /// @nodoc
  Session copyWith({
    SessionState? state,
    MeResponseDto? user,
    ApiFailure? failure,
  }) => Session(
    state: state ?? this.state,
    user: user ?? this.user,
    failure: failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          other.state == state &&
          other.user == user &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(state, user, failure);

  @override
  String toString() => 'Session(${state.name})';
}
