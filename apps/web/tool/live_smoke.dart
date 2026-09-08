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
  var lastRequestUri = '';
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        lastRequestUri = options.uri.toString();
        handler.next(options);
      },
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

  await check('GET /api/projects/{slug} без сессии — 401', () async {
    try {
      await client.projects.projectsControllerGet(slug: 'sweet-limit');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET участников без сессии — 401', () async {
    try {
      await client.projects.membersControllerList(slug: 'sweet-limit');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET приглашений проекта без сессии — 401', () async {
    try {
      await client.invitations.projectInvitationsControllerList(
        slug: 'sweet-limit',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Отзыв приглашения — POST без тела. Ровно на таких запросах сгенерированный
  // клиент раньше ставил `Content-Type: application/json`, и Fastify отвечал
  // 400. Проверка сторожит именно это: код ответа обязан быть 401, а не 400.
  await check('POST отзыва приглашения без тела не ломается о 400', () async {
    try {
      await client.invitations.projectInvitationsControllerRevoke(
        slug: 'sweet-limit',
        id: '00000000-0000-0000-0000-000000000000',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(
        failure.statusCode != 400,
        'пустой POST снова отвергнут: $failure',
      );
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('приглашение по неизвестному токену без сессии — 401', () async {
    // Без сессии сервер обязан ответить 401 раньше, чем 404: иначе
    // по коду ответа можно было бы перебирать существующие токены,
    // даже не входя в трекер.
    try {
      await client.invitations.invitationAcceptControllerPreview(
        token: 'nesuschestvuyuschiy-token-dlya-proverki',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('вступление по приглашению без сессии — 401', () async {
    try {
      await client.invitations.invitationAcceptControllerAccept(
        token: 'nesuschestvuyuschiy-token-dlya-proverki',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(
        failure.statusCode != 400,
        'пустой POST снова отвергнут: $failure',
      );
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('создание проекта без сессии — 401, а не 500', () async {
    try {
      await client.projects.projectsControllerCreate(
        body: const CreateProjectDto(name: 'Проверка связи'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('удаление обложки без сессии — 401', () async {
    try {
      await client.projects.projectsControllerRemoveCover(slug: 'sweet-limit');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Обложка уходит `multipart/form-data` через сгенерированный клиент:
  // `use_multipart_file` в `swagger_parser.yaml` заменил `dart:io File`
  // на `MultipartFile`, которому в браузере есть чем себя наполнить.
  // Проверяем, что запрос собирается и доезжает до авторизации, а не
  // разваливается на теле.
  await check('multipart-обложка уходит на сервер и получает 401', () async {
    try {
      await client.projects.projectsControllerUploadCover(
        slug: 'sweet-limit',
        file: MultipartFile.fromBytes(
          // Восьмибайтовая сигнатура PNG: содержимое здесь неважно,
          // до проверки типа запрос всё равно не доживёт.
          const [137, 80, 78, 71, 13, 10, 26, 10],
          filename: 'cover.png',
          contentType: DioMediaType.parse('image/png'),
        ),
      );
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

  // Очереди и задачи: разделы контракта, ради которых написан этот заход.
  await check('GET очередей проекта без сессии — 401', () async {
    try {
      await client.queues.projectQueuesControllerList(slug: 'sweet-limit');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('POST создания очереди без сессии — 401, а не 400', () async {
    try {
      await client.queues.projectQueuesControllerCreate(
        slug: 'sweet-limit',
        body: const CreateQueueDto(key: 'DEV', name: 'Разработка'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET очереди по ключу без сессии — 401', () async {
    try {
      await client.queues.queueControllerGet(key: 'DEV');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET статусов очереди без сессии — 401', () async {
    try {
      await client.queues.queueControllerStatuses(key: 'DEV');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('PATCH переименования очереди без сессии — 401', () async {
    try {
      await client.queues.queueControllerUpdate(
        key: 'DEV',
        body: const UpdateQueueDto(name: 'Разработка'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('DELETE очереди без сессии — 401', () async {
    try {
      await client.queues.queueControllerRemove(key: 'DEV');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Главный запрос экрана. Проверяется не только код ответа, но и то, как
  // собран адрес: фильтр по статусу принимает ключи через запятую, и ошибка
  // здесь стоила бы пустого списка на рабочем экране.
  await check('GET задач очереди собирает фильтр и сортировку', () async {
    try {
      await client.issues.queueIssuesControllerList(
        key: 'DEV',
        status: 'in_progress,review',
        sort: Sort.newest,
        limit: 50,
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('/api/queues/DEV/issues'),
        'путь собран неверно: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('status=in_progress%2Creview') ||
            lastRequestUri.contains('status=in_progress,review'),
        'фильтр статусов не доехал: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('sort=newest'),
        'сортировка не доехала: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('limit=50'),
        'размер порции не доехал: $lastRequestUri',
      );
    }
  });

  await check('GET моих активных задач с поиском — 401', () async {
    try {
      await client.issues.myIssuesControllerMyActive(q: 'csv', limit: 50);
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('q=csv'),
        'поисковый запрос не доехал: $lastRequestUri',
      );
    }
  });

  await check('POST создания задачи без сессии — 401, а не 400', () async {
    try {
      await client.issues.queueIssuesControllerCreate(
        key: 'DEV',
        body: const CreateIssueDto(title: 'Проверка связи'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET задачи по ключу без сессии — 401', () async {
    try {
      await client.issues.issueControllerGet(key: 'DEV-1');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('PATCH смены статуса задачи без сессии — 401', () async {
    try {
      await client.issues.issueControllerUpdate(
        key: 'DEV-1',
        body: const UpdateIssueDto(statusId: 'status-1'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET истории задачи без сессии — 401', () async {
    try {
      await client.issues.issueControllerListHistory(key: 'DEV-1');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  stdout.writeln(
    '\n401-сигналов поймано: $unauthorized — по одному на каждый запрос '
    'без сессии. Столько же раз приложение увело бы человека на вход.',
  );
  dio.close();
}
