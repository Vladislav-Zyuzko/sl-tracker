/// Конфигурация сборки клиента.
///
/// Значения приходят через `--dart-define`, чтобы одна и та же сборка
/// не зависела от правки исходников. Секретов здесь нет и быть не может:
/// всё, что попадает в `--dart-define`, попадает и в бандл.
sealed class AppConfig {
  /// Источник API: схема и хост, без пути.
  ///
  /// Пустая строка по умолчанию — «тот же origin, что и у страницы»: фронт
  /// и API живут на одном домене, Caddy проксирует `/api/*` в NestJS
  /// (ADR-0001), и относительный адрес запроса браузер разрешит сам.
  /// Абсолютный адрес нужен только при разработке против чужого стенда.
  static const apiOrigin = String.fromEnvironment('SL_API_ORIGIN');

  /// Префикс всех адресов API.
  ///
  /// Дублировать его в коде запросов не нужно: сгенерированный клиент несёт
  /// полные пути из контракта (`/api/me`, `/api/access-entries`), поэтому
  /// `baseUrl` у `Dio` — это именно origin, а не origin с префиксом.
  /// Здесь префикс нужен только для адресов, по которым уходит **браузер**,
  /// а не XHR.
  static const apiPathPrefix = '/api';

  /// Адрес, на который браузер уходит полным редиректом при входе.
  ///
  /// Это переход страницы, а не XHR: бэкенд отвечает редиректом на Яндекс,
  /// и запрос за ним пойти не может (ADR-0002).
  ///
  /// [next] — куда вернуть человека после входа (US-01). Сервер принимает
  /// только путь внутри приложения и внешние адреса игнорирует, но и клиент
  /// не отправляет ничего, кроме пути.
  static String authStartUrl({String? next, String? invite}) {
    final query = <String, String>{
      if (next != null && next.startsWith('/')) 'next': next,
      if (invite != null && invite.isNotEmpty) 'invite': invite,
    };

    final path = '$apiOrigin$apiPathPrefix/auth/yandex/start';

    return query.isEmpty ? path : '$path?${Uri(queryParameters: query).query}';
  }

  /// Таймаут установления соединения.
  static const connectTimeout = Duration(seconds: 10);

  /// Таймаут получения ответа.
  static const receiveTimeout = Duration(seconds: 20);
}
