import 'package:dio/dio.dart';

import 'package:sl_tracker_web/app/app_config.dart';
import 'package:sl_tracker_web/core/network/adapter/session_http_adapter.dart';
import 'package:sl_tracker_web/core/network/session_interceptor.dart';

/// Собирает HTTP-клиент приложения.
///
/// Один клиент на всё приложение: адаптер с поддержкой cookie-сессии,
/// разбор ошибок в [SessionInterceptor], таймауты из [AppConfig].
///
/// Валидация статусов отключена намеренно — коды 4xx и 5xx должны дойти
/// до интерсептора и стать `ApiFailure`, а не утонуть в общем `DioException`.
Dio createDio({required void Function() onUnauthorized}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  )..httpClientAdapter = createSessionHttpAdapter();

  dio.interceptors.add(SessionInterceptor(onUnauthorized: onUnauthorized));

  return dio;
}
