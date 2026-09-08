import 'package:dio/dio.dart';

/// Что именно пошло не так при обращении к API.
///
/// Экран выбирает состояние по [ApiFailureKind], а не по коду ответа:
/// коды в одном месте разбираются один раз, дальше по приложению ходит
/// уже понятная причина (`docs/design/components.md`, 17.1).
enum ApiFailureKind {
  /// Сеть недоступна, запрос не дошёл или оборвался.
  network,

  /// Истекло время ожидания.
  timeout,

  /// 401. Сессия истекла или её не было. Состояние сессии сбрасывается,
  /// пользователь уходит на экран входа.
  unauthorized,

  /// 403. Пользователь виден серверу, но прав не хватает.
  /// Показываем состояние «нет прав», а не белый экран.
  forbidden,

  /// 404. Объекта нет либо доступа к нему нет вовсе — с точки зрения UI
  /// это одно и то же, и различать их нельзя: иначе 404 раскрывает
  /// существование чужого объекта.
  notFound,

  /// 409. Конфликт: объект изменился, пока пользователь его редактировал.
  conflict,

  /// 422. Сервер отверг данные формы. Ошибки полей — в [ApiFailure.fieldErrors].
  validation,

  /// 5xx. Сломалось на нашей стороне.
  server,

  /// Всё остальное, включая ошибку разбора ответа.
  unknown,
}

/// Ошибка обращения к API в терминах интерфейса.
class ApiFailure implements Exception {
  /// @nodoc
  const ApiFailure({
    required this.kind,
    this.statusCode,
    this.code,
    this.requestId,
    this.message,
    this.fieldErrors = const {},
  });

  /// Причина.
  final ApiFailureKind kind;

  /// HTTP-код ответа, если он был.
  final int? statusCode;

  /// Машинный код ошибки из тела ответа: `access_entry_exists`,
  /// `last_instance_owner`, `cannot_revoke_self`, `invalid_email`,
  /// `csrf_origin_mismatch` и прочие.
  ///
  /// Бэкенд отдаёт тело вида `{"message": ..., "code": ..., "statusCode": ...}`.
  /// Экран выбирает текст по коду, а не по `message`: тексты задаёт дизайн,
  /// а не сервер.
  final String? code;

  /// Идентификатор запроса из заголовка ответа.
  ///
  /// Пользователю не показывается, но прячется под «Подробности»
  /// в состоянии ошибки — в баг-репорте он бесценен.
  final String? requestId;

  /// Техническое описание. В UI не выводится дословно: тексты ошибок
  /// задаёт дизайн, а не сервер.
  final String? message;

  /// Ошибки по полям формы: имя поля — текст ошибки.
  final Map<String, String> fieldErrors;

  /// Заголовок ответа, в котором бэкенд отдаёт идентификатор запроса.
  static const requestIdHeader = 'x-request-id';

  /// Приводит любую пойманную ошибку к [ApiFailure].
  ///
  /// Репозиторий ловит `DioException` от сгенерированного клиента и отдаёт
  /// наружу уже понятную причину: выше по стеку про `dio` никто не знает.
  /// Ошибка разбора ответа тоже становится [ApiFailure], а не улетает
  /// в никуда с белым экраном.
  static ApiFailure of(Object error) => switch (error) {
    ApiFailure() => error,
    DioException(error: final ApiFailure failure) => failure,
    DioException() => ApiFailure.fromDioException(error),
    _ => ApiFailure(kind: ApiFailureKind.unknown, message: error.toString()),
  };

  /// Разбирает ошибку `dio` в [ApiFailure].
  factory ApiFailure.fromDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final requestId = response?.headers.value(requestIdHeader);

    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.connectionError => ApiFailureKind.network,
      DioExceptionType.cancel => ApiFailureKind.unknown,
      DioExceptionType.badCertificate => ApiFailureKind.network,
      DioExceptionType.badResponse => _kindOfStatus(statusCode),
      DioExceptionType.unknown => ApiFailureKind.unknown,
      // transformTimeout — сбой преобразования тела ответа, не сети.
      DioExceptionType.transformTimeout => ApiFailureKind.timeout,
    };

    return ApiFailure(
      kind: kind,
      statusCode: statusCode,
      code: _codeOf(response?.data),
      requestId: requestId,
      message: error.message,
      fieldErrors: _fieldErrorsOf(response?.data),
    );
  }

  static ApiFailureKind _kindOfStatus(int? statusCode) {
    if (statusCode == null) return ApiFailureKind.unknown;
    if (statusCode == 401) return ApiFailureKind.unauthorized;
    if (statusCode == 403) return ApiFailureKind.forbidden;
    if (statusCode == 404) return ApiFailureKind.notFound;
    if (statusCode == 409) return ApiFailureKind.conflict;
    if (statusCode == 422) return ApiFailureKind.validation;
    if (statusCode >= 500) return ApiFailureKind.server;

    return ApiFailureKind.unknown;
  }

  /// Достаёт ошибки полей из тела ответа.
  ///
  /// Формат пока не зафиксирован контрактом: ожидается объект `errors`
  /// вида «поле — сообщение». Если его нет, список остаётся пустым и форма
  /// показывает общий баннер — падать на незнакомом теле нельзя.
  /// Достаёт машинный код ошибки из тела ответа.
  static String? _codeOf(Object? data) {
    if (data is! Map) return null;

    final code = data['code'];

    return code is String && code.isNotEmpty ? code : null;
  }

  static Map<String, String> _fieldErrorsOf(Object? data) {
    if (data is! Map) return const {};

    final errors = data['errors'];
    if (errors is! Map) return const {};

    return {
      for (final entry in errors.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  @override
  String toString() =>
      'ApiFailure(${kind.name}, status: $statusCode, code: $code)';
}
