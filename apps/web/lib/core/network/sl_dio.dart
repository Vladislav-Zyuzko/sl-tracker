import 'package:dio/dio.dart';

import 'package:sl_tracker_web/app/app_config.dart';
import 'package:sl_tracker_web/core/network/adapter/session_http_adapter.dart';
import 'package:sl_tracker_web/core/network/empty_body_interceptor.dart';
import 'package:sl_tracker_web/core/network/partial_update_interceptor.dart';
import 'package:sl_tracker_web/core/network/session_interceptor.dart';

/// Собирает HTTP-клиент приложения.
///
/// Один клиент на всё приложение: адаптер с поддержкой cookie-сессии,
/// разбор ошибок в [SessionInterceptor], таймауты из [AppConfig].
///
/// `baseUrl` — это origin, а не origin с префиксом `/api`: пути `/api/me`
/// и `/api/access-entries` приходят из контракта вместе со сгенерированным
/// клиентом, и `dio` просто склеивает их с базой. По умолчанию база пустая —
/// адрес получается относительным, браузер разрешает его от адреса страницы,
/// и запрос остаётся first-party (ADR-0001).
///
/// Заголовок `Origin` браузер проставляет сам и запретить его подмену нельзя —
/// это и требуется: небезопасные методы сервер сверяет по нему
/// (`apps/api/src/auth/csrf.ts`, ответ 403 `csrf_origin_mismatch`).
/// Поэтому мы не задаём `Origin` руками и не отправляем запросы в обход `dio`.
///
/// Валидация статусов отключена намеренно — коды 4xx и 5xx должны дойти
/// до интерсептора и стать `ApiFailure`, а не утонуть в общем `DioException`.
Dio createDio({required void Function() onUnauthorized}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiOrigin,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  )..httpClientAdapter = createSessionHttpAdapter();

  dio.interceptors.addAll([
    // Порядок важен: тело чистим и заголовки правим до отправки, ошибки
    // разбираем после. `PartialUpdateInterceptor` идёт первым: он может
    // оставить тело пустым, и `EmptyBodyInterceptor` должен это увидеть.
    PartialUpdateInterceptor(),
    EmptyBodyInterceptor(),
    SessionInterceptor(onUnauthorized: onUnauthorized),
  ]);

  return dio;
}
