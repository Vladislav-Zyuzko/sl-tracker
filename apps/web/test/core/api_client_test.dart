import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/sl_dio.dart';

/// Отвечает заготовленным телом и запоминает запрос.
///
/// Проверяем ровно то, что нельзя проверить глазами в браузере: какой адрес
/// в итоге собирается из `baseUrl` и путей из контракта, и во что
/// превращается тело ошибки бэкенда.
class CapturingAdapter implements HttpClientAdapter {
  CapturingAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;

  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'x-request-id': ['req-42'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(SlApiClient, CapturingAdapter) clientWith({
  int statusCode = 200,
  Object body = const <String, Object?>{},
  void Function()? onUnauthorized,
}) {
  final adapter = CapturingAdapter(statusCode: statusCode, body: body);
  final dio = createDio(onUnauthorized: onUnauthorized ?? () {})
    ..httpClientAdapter = adapter;

  return (SlApiClient(dio), adapter);
}

/// Тело ответа снято с живого API: `curl http://localhost:8081/api/me`.
const _sessionRequired = {
  'message': 'Требуется вход',
  'code': 'session_required',
  'statusCode': 401,
};

void main() {
  group('адреса запросов', () {
    test('путь из контракта не удваивает префикс /api', () async {
      final (client, adapter) = clientWith(
        body: {
          'id': 'u1',
          'displayName': 'Анна',
          'email': 'anna@yandex.ru',
          'avatarUrl': null,
          'isInstanceOwner': true,
          'canManageAccessList': true,
          'session': {'kind': 'cookie', 'expiresAt': '2026-12-31T00:00:00Z'},
        },
      );

      final me = await client.auth.meControllerMe();

      // Именно `/api/me`, а не `/api/api/me`: пути приходят из контракта
      // целиком, поэтому `baseUrl` у Dio — это origin, а не origin с префиксом.
      expect(adapter.request?.uri.toString(), '/api/me');
      expect(me.canManageAccessList, isTrue);
    });

    test('поиск и постраничность уезжают параметрами запроса', () async {
      final (client, adapter) = clientWith(
        body: {'items': <Object>[], 'nextCursor': null, 'total': 0},
      );

      await client.access.accessControllerList(limit: 50, q: 'anna');

      final uri = adapter.request!.uri;

      expect(uri.path, '/api/access-entries');
      expect(uri.queryParameters['q'], 'anna');
      expect(uri.queryParameters['limit'], '50');
    });

    test(
      'небезопасный метод уходит как есть: Origin проставляет браузер',
      () async {
        final (client, adapter) = clientWith(
          statusCode: 201,
          body: {
            'id': 'e1',
            'email': 'ivan@yandex.ru',
            'source': 'manual',
            'isInstanceOwner': false,
            'createdAt': '2026-02-12T10:30:00Z',
            'firstLoginAt': null,
            'user': null,
            'addedBy': null,
            'isSelf': false,
          },
        );

        await client.access.accessControllerAdd(
          body: const CreateAccessEntryDto(email: 'ivan@yandex.ru'),
        );

        expect(adapter.request?.method, 'POST');
        // Свой `Origin` клиент не подставляет: заголовок ставит браузер,
        // и сервер сверяет именно его (403 `csrf_origin_mismatch`).
        expect(adapter.request?.headers.containsKey('origin'), isFalse);
      },
    );
  });

  group('запрос без тела', () {
    test('не заявляет JSON: иначе Fastify отвечает 400 на выход', () async {
      final (client, adapter) = clientWith(statusCode: 204, body: const {});

      await client.auth.authControllerLogout();

      // Проверено на живом API: `POST /api/auth/logout` с заголовком
      // `Content-Type: application/json` и пустым телом возвращает 400,
      // без заголовка — 204.
      expect(adapter.request?.data, isNull);
      expect(adapter.request?.headers[Headers.contentTypeHeader], isNull);
    });

    test('тело у запроса с телом остаётся JSON', () async {
      final (client, adapter) = clientWith(
        statusCode: 200,
        body: {
          'id': 'e1',
          'email': 'ivan@yandex.ru',
          'source': 'manual',
          'isInstanceOwner': true,
          'createdAt': '2026-02-12T10:30:00Z',
          'firstLoginAt': null,
          'user': null,
          'addedBy': null,
          'isSelf': false,
        },
      );

      await client.access.accessControllerUpdate(
        id: 'e1',
        body: const UpdateAccessEntryDto(isInstanceOwner: true),
      );

      expect(
        adapter.request?.headers[Headers.contentTypeHeader],
        contains('application/json'),
      );
    });
  });

  group('разбор ошибок сервера', () {
    test('401 сообщает о потере сессии и несёт код', () async {
      var unauthorized = 0;
      final (client, _) = clientWith(
        statusCode: 401,
        body: _sessionRequired,
        onUnauthorized: () => unauthorized++,
      );

      final failure = await client.auth.meControllerMe().then<ApiFailure?>(
        (_) => null,
        onError: (Object error) => ApiFailure.of(error),
      );

      expect(unauthorized, 1);
      expect(failure?.kind, ApiFailureKind.unauthorized);
      expect(failure?.code, 'session_required');
      expect(failure?.requestId, 'req-42');
    });

    test('409 доносит машинный код до экрана', () async {
      final (client, _) = clientWith(
        statusCode: 409,
        body: const {
          'message': 'Этот адрес уже в списке',
          'code': 'access_entry_exists',
          'statusCode': 409,
        },
      );

      final failure = await client.access
          .accessControllerAdd(
            body: const CreateAccessEntryDto(email: 'ivan@yandex.ru'),
          )
          .then<ApiFailure?>(
            (_) => null,
            onError: (Object error) => ApiFailure.of(error),
          );

      expect(failure?.kind, ApiFailureKind.conflict);
      expect(failure?.code, 'access_entry_exists');
    });

    test('404 обмена тикета — не сбой, а «адреса не будет»', () async {
      final (client, _) = clientWith(
        statusCode: 404,
        body: const {
          'message': 'Ссылка устарела',
          'code': 'ticket_not_found',
          'statusCode': 404,
        },
      );

      final failure = await client.auth
          .authControllerAccessDeniedInfo(ticket: 'used')
          .then<ApiFailure?>(
            (_) => null,
            onError: (Object error) => ApiFailure.of(error),
          );

      expect(failure?.kind, ApiFailureKind.notFound);
      expect(failure?.code, 'ticket_not_found');
    });
  });
}
