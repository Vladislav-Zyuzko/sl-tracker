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
import 'package:sl_tracker_web/core/network/partial_update_interceptor.dart';

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
  dio.interceptors.add(PartialUpdateInterceptor());
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

  // Экран задачи: комментарии, вложения, упоминания и ссылки. Раздел
  // добавлен вместе с самим экраном — до него этих маршрутов в контракте
  // не было.
  await check('GET комментариев задачи собирает курсор и размер', () async {
    try {
      await client.comments.commentsControllerList(
        key: 'DEV-1',
        cursor: 'cursor-1',
        limit: 50,
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('/api/issues/DEV-1/comments'),
        'путь собран неверно: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('cursor=cursor-1'),
        'курсор более ранних не доехал: $lastRequestUri',
      );
    }
  });

  await check('POST комментария без сессии — 401, а не 400', () async {
    try {
      await client.comments.commentsControllerCreate(
        key: 'DEV-1',
        body: const CreateCommentDto(body: 'Проверка связи'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('PATCH комментария без сессии — 401', () async {
    try {
      await client.comments.commentsControllerUpdate(
        key: 'DEV-1',
        commentId: '00000000-0000-0000-0000-000000000000',
        body: const UpdateCommentDto(body: 'Правка'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('DELETE комментария без сессии — 401', () async {
    try {
      await client.comments.commentsControllerRemove(
        key: 'DEV-1',
        commentId: '00000000-0000-0000-0000-000000000000',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET вложений задачи без сессии — 401', () async {
    try {
      await client.attachments.attachmentsControllerList(key: 'DEV-1');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Загрузка вложения — тот же `multipart`, что и обложка проекта:
  // проверяем, что тело собирается и доезжает до авторизации.
  await check('multipart-вложение уходит на сервер и получает 401', () async {
    try {
      await client.attachments.attachmentsControllerUpload(
        key: 'DEV-1',
        file: MultipartFile.fromBytes(
          const [137, 80, 78, 71, 13, 10, 26, 10],
          filename: 'screenshot.png',
          contentType: DioMediaType.parse('image/png'),
        ),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('DELETE вложения без сессии — 401', () async {
    try {
      await client.attachments.attachmentsControllerRemove(
        key: 'DEV-1',
        attachmentId: '00000000-0000-0000-0000-000000000000',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET подсказки упоминаний передаёт строку поиска', () async {
    try {
      await client.mentions.mentionSuggestionsControllerSuggest(
        key: 'DEV-1',
        query: 'ан',
        limit: 10,
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('/api/issues/DEV-1/mention-suggestions'),
        'путь собран неверно: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('query='),
        'строка поиска не доехала: $lastRequestUri',
      );
    }
  });

  await check('POST внешней ссылки без сессии — 401, а не 400', () async {
    try {
      await client.issues.issueControllerAddLink(
        key: 'DEV-1',
        body: const CreateIssueLinkDto(url: 'https://example.com/spec'),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('DELETE внешней ссылки без сессии — 401', () async {
    try {
      await client.issues.issueControllerRemoveLink(
        key: 'DEV-1',
        linkId: '00000000-0000-0000-0000-000000000000',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('DELETE задачи без сессии — 401', () async {
    try {
      await client.issues.issueControllerRemove(key: 'DEV-1');
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Уведомления: раздел, ради которого написан этот заход. Проверяется
  // и сборка адресов, и то, что POST без тела не разваливается о 400.
  await check('GET ленты уведомлений собирает порцию и курсор', () async {
    try {
      await client.notifications.notificationsControllerList(
        cursor: 'eyJpZCI6MX0',
        limit: 30,
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('/api/notifications'),
        'путь собран неверно: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('limit=30'),
        'размер порции не доехал: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('cursor=eyJpZCI6MX0'),
        'курсор не доехал: $lastRequestUri',
      );
    }
  });

  await check('GET счётчика непрочитанных без сессии — 401', () async {
    try {
      await client.notifications.notificationsControllerUnreadCount();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Пометка прочитанным — POST **без тела**. Тот же класс ошибки, на котором
  // Fastify раньше отвечал 400 из-за `Content-Type: application/json`
  // у пустого запроса.
  await check('POST пометки прочитанным без тела не ломается о 400', () async {
    try {
      await client.notifications.notificationsControllerMarkRead(
        id: '00000000-0000-0000-0000-000000000000',
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'пустой POST снова отвергнут: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('POST «отметить все» без тела не ломается о 400', () async {
    try {
      await client.notifications.notificationsControllerMarkAllRead();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'пустой POST снова отвергнут: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  await check('GET настроек подписки без сессии — 401', () async {
    try {
      await client.notifications.notificationsControllerSettings();
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Экран профиля меняет ровно один тип за раз: одновременное переключение
  // двух тумблеров иначе затирало бы друг друга.
  await check('PUT настроек отправляет один тип и доезжает до 401', () async {
    try {
      await client.notifications.notificationsControllerUpdateSettings(
        body: const UpdateNotificationSettingsDto(
          items: [
            UpdateNotificationSettingDto(
              type: UpdateNotificationSettingDtoType.issueCommented,
              enabled: false,
            ),
          ],
        ),
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.statusCode != 400, 'тело не принято: $failure');
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
    }
  });

  // Поиск по участникам проекта: маршрут появился под селекторы автора
  // и исполнителя. Здесь проверяется только сборка адреса — экраны на него
  // ещё не переведены.
  await check('GET участников проекта принимает поиск и курсор', () async {
    try {
      await client.projects.membersControllerList(
        slug: 'sweet-limit',
        q: 'иван',
        cursor: 'eyJpZCI6MX0',
        limit: 50,
      );
      throw StateError('ожидался 401');
    } on DioException catch (error) {
      final failure = ApiFailure.of(error);
      assert(failure.kind == ApiFailureKind.unauthorized, '$failure');
      assert(
        lastRequestUri.contains('q=%D0%B8%D0%B2%D0%B0%D0%BD') ||
            lastRequestUri.contains('q=иван'),
        'поиск не доехал: $lastRequestUri',
      );
      assert(
        lastRequestUri.contains('cursor=eyJpZCI6MX0'),
        'курсор не доехал вместе с поиском: $lastRequestUri',
      );
    }
  });

  // Живые обновления. Открыть настоящий WebSocket отсюда нечем — в VM нет
  // браузерного клиента и нет cookie, — но рукопожатие это и есть обычный
  // HTTP-запрос с `Upgrade`, и проверить его код ответа можно. Без сессии
  // сервер обязан ответить 401 **до** открытия сокета (`websocket.md`, 2).
  await check('рукопожатие WebSocket без сессии — 401, сокет не открывается', () async {
    final uri = Uri.parse('$origin/api/ws');
    final httpClient = HttpClient();

    try {
      final request = await httpClient.openUrl('GET', uri);
      request.headers
        ..set(HttpHeaders.connectionHeader, 'Upgrade')
        ..set('Upgrade', 'websocket')
        ..set('Sec-WebSocket-Version', '13')
        // Ключ произвольный: до проверки протокола запрос не доживёт.
        ..set('Sec-WebSocket-Key', 'dGhlIHNhbXBsZSBub25jZQ==')
        ..set('Origin', origin);

      final response = await request.close();
      await response.drain<void>();

      assert(
        response.statusCode == HttpStatus.unauthorized,
        'ожидался 401, пришёл ${response.statusCode}',
      );
      assert(
        response.statusCode != HttpStatus.switchingProtocols,
        'сокет открылся без сессии — это дыра, а не обновление',
      );
    } finally {
      httpClient.close(force: true);
    }
  });

  // Частичное обновление: `PATCH` с одним полем обязан отправлять **одно
  // поле**. Сгенерированная модель кладёт в JSON все ключи со значением
  // `null`, а по контракту `assigneeId: null` снимает исполнителя,
  // `description: null` очищает описание — то есть смена статуса заодно
  // стирала бы половину задачи. Проверка сторожит `PartialUpdateInterceptor`.
  await check('PATCH задачи отправляет только заданные поля', () async {
    final probe = Dio(BaseOptions(baseUrl: origin))
      ..interceptors.add(PartialUpdateInterceptor());
    Object? sent;
    probe.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options.data;
          handler.reject(
            DioException.requestCancelled(
              requestOptions: options,
              reason: 'проверка тела',
            ),
          );
        },
      ),
    );

    try {
      await SlApiClient(probe).issues.issueControllerUpdate(
        key: 'DEV-1',
        body: UpdateIssueDto(statusId: 'status-1'),
      );
    } on DioException catch (_) {
      // До сети запрос не доходит намеренно: интересует ровно тело.
    }

    final body = sent! as Map<String, dynamic>;
    assert(body.keys.length == 1, 'лишние поля в теле: $body');
    assert(body['statusId'] == 'status-1', 'тело собрано неверно: $body');
    probe.close();
  });

  stdout.writeln(
    '\n401-сигналов поймано: $unauthorized — по одному на каждый запрос '
    'без сессии. Столько же раз приложение увело бы человека на вход.',
  );
  dio.close();
}
