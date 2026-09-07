import 'package:dio/dio.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';

/// Разбирает ошибки транспорта в [ApiFailure] и сообщает о потере сессии.
///
/// Разбор делается здесь один раз: дальше по приложению ходит уже понятная
/// причина, а не `DioException` с кодом. Экраны и репозитории про `dio`
/// ничего не знают.
class SessionInterceptor extends Interceptor {
  /// @nodoc
  SessionInterceptor({required this.onUnauthorized});

  /// Вызывается на 401: состояние сессии сбрасывается, пользователь уходит
  /// на экран входа. Сам интерсептор не навигирует — это не его дело.
  final void Function() onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = ApiFailure.fromDioException(err);

    if (failure.kind == ApiFailureKind.unauthorized) {
      onUnauthorized();
    }

    // 403 наружу не перехватываем: «нет прав» — состояние конкретного экрана,
    // и решать, показать пустой экран или тост с откатом, должен экран.
    handler.next(err.copyWith(error: failure));
  }
}
