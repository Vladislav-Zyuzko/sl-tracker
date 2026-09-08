import 'package:dio/dio.dart';

/// Убирает `Content-Type: application/json` у запросов без тела.
///
/// Существует из-за живой ошибки, а не «на всякий случай»: `POST
/// /api/auth/logout` тела не имеет, а сгенерированный клиент всё равно ставил
/// заголовок из общих настроек `Dio`. Fastify на такое отвечает 400 — «тело
/// не может быть пустым, если заявлен JSON», — и выход переставал работать.
///
/// Правило простое: заявлять формат тела, которого нет, нельзя. Оно защищает
/// и будущие запросы без тела — например, `DELETE /api/access-entries/{id}`.
class EmptyBodyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data == null) {
      options.contentType = null;
      options.headers.remove(Headers.contentTypeHeader);
    }

    handler.next(options);
  }
}
