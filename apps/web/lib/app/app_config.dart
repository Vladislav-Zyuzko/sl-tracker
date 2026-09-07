/// Конфигурация сборки клиента.
///
/// Значения приходят через `--dart-define`, чтобы одна и та же сборка
/// не зависела от правки исходников. Секретов здесь нет и быть не может:
/// всё, что попадает в `--dart-define`, попадает и в бандл.
sealed class AppConfig {
  /// Базовый адрес API.
  ///
  /// По умолчанию относительный `/api`: фронт и API живут на одном домене,
  /// Caddy проксирует `/api/*` в NestJS (ADR-0001). Абсолютный адрес нужен
  /// только при разработке против чужого стенда.
  static const apiBaseUrl = String.fromEnvironment(
    'SL_API_BASE_URL',
    defaultValue: '/api',
  );

  /// Адрес, на который браузер уходит полным редиректом при входе.
  ///
  /// Это именно переход страницы, а не XHR: бэкенд отвечает редиректом
  /// на Яндекс, и XHR за ним пойти не может (ADR-0002).
  static const authStartPath = '$apiBaseUrl/auth/yandex/start';

  /// Таймаут установления соединения.
  static const connectTimeout = Duration(seconds: 10);

  /// Таймаут получения ответа.
  static const receiveTimeout = Duration(seconds: 20);
}
