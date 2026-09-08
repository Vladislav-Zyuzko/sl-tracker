// Дымовая проверка сгенерированного клиента против **живого** API.
//
//     dart run --enable-asserts tool/live_smoke.dart [http://localhost:8081]
//
// Проверяет то, что виджет-тесты проверить не могут: что реальные ответы
// сервера разбираются в наши DTO, что коды ошибок доезжают до клиента
// и что адреса собираются правильно. Сессии здесь нет и быть не может —
// она живёт в httpOnly cookie браузера, — поэтому проверяются только
// неаутентифицированные ответы.
//
// Запускать после каждого изменения контракта: `docs/api/openapi.json`
// меняется чаще, чем экраны.
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/empty_body_interceptor.dart';

Future<void> main(List<String> args) async {
  final origin = args.isEmpty ? 'http://localhost:8081' : args.first;
  var unauthorized = 0;

  final dio = Dio(
    BaseOptions(
      baseUrl: origin,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(EmptyBodyInterceptor());
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        final failure = ApiFailure.fromDioException(error);
        if (failure.kind == ApiFailureKind.unauthorized) unauthorized++;
        handler.next(error.copyWith(error: failure));
      },
    ),
  );

  final client = SlApiClient(dio);

  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      stdout.writeln('OK   $name');
    } on Object catch (error) {
      stdout.writeln('FAIL $name: $error');
    }
  }

  await check('GET /api/health отвечает', () async {
    final health = await client.health.healthControllerCheck();
    assert(
      health.status == HealthResponseDtoStatus.ok,
      'status=${health.status}',
    );
  });

  await check('GET /api/me без сессии — 401 session_required', () async {
    try {
      await client.auth.meControllerMe();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(failure.code == 'session_required', '$failure');
      // Идентификатор запроса нужен в баг-репорте: он уезжает
      // в блок «Подробности» состояния ошибки.
      assert(failure.requestId != null, 'нет заголовка x-request-id');
    }
  });

  await check('GET /api/access-entries без сессии — 401', () async {
    try {
      await client.access.accessControllerList();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Новые разделы контракта: проверяем, что сгенерированные клиенты
  // разговаривают с сервером, хотя экранов для них ещё нет.
  await check('GET /api/projects без сессии — 401', () async {
    try {
      await client.projects.projectsControllerList();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET /api/issues/my-active без сессии — 401', () async {
    try {
      await client.issues.myIssuesControllerMyActive();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('обмен несуществующего тикета — 404 ticket_not_found', () async {
    try {
      await client.auth.authControllerAccessDeniedInfo(
        ticket: 'no-such-ticket',
      );
      throw StateError('ожидался 404');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.notFound, '$failure');
      assert(failure.code == 'ticket_not_found', '$failure');
    }
  });

  await check('POST /api/auth/logout без сессии — 204', () async {
    await client.auth.authControllerLogout();
  });

  await check('вход отвечает редиректом на Яндекс, а не телом', () async {
    final response = await dio.get<void>(
      '/api/auth/yandex/start',
      options: Options(
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final location = response.headers.value('location') ?? '';
    assert(response.statusCode == 302, 'status=${response.statusCode}');
    assert(location.startsWith('https://oauth.yandex.ru/'), location);
  });

  stdout.writeln(
    '\n401-сигналов поймано: $unauthorized — по одному на каждый запрос '
    'без сессии. Столько же раз приложение увело бы человека на вход.',
  );
  dio.close();
}
