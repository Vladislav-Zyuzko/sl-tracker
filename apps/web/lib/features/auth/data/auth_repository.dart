import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';

/// Работа с сессией и профилем.
///
/// Тонкая обёртка над сгенерированным клиентом: её задача — отдавать наружу
/// [ApiFailure] вместо `DioException`, чтобы про `dio` не знал никто, кроме
/// слоя сети.
class AuthRepository {
  /// @nodoc
  const AuthRepository(this._client);

  final AuthClient _client;

  /// Текущий пользователь. 401 приходит как [ApiFailureKind.unauthorized].
  Future<MeResponseDto> me() async {
    try {
      return await _client.meControllerMe();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Выход.
  ///
  /// Сервер отвечает 204 и тогда, когда сессии уже нет: экран отказа доступа
  /// зовёт выход, не зная, была ли сессия вообще создана.
  Future<void> logout() async {
    try {
      await _client.authControllerLogout();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Обменивает одноразовый тикет экрана отказа на адрес, которым человек вошёл.
  ///
  /// Тикет живёт 60 секунд и обменивается ровно один раз, поэтому 404 — это
  /// штатная ситуация (перезагрузка страницы, возврат по истории), а не сбой:
  /// возвращаем `null`, и экран показывает текст без адреса.
  Future<String?> accessDeniedEmail(String ticket) async {
    try {
      final info = await _client.authControllerAccessDeniedInfo(ticket: ticket);

      return info.email;
    } on Object catch (error) {
      final failure = ApiFailure.of(error);
      if (failure.kind == ApiFailureKind.notFound) return null;

      throw failure;
    }
  }
}

/// @nodoc
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider).auth),
);
