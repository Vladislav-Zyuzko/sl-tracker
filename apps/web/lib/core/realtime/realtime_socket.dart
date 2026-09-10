import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/app_config.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/realtime/realtime_socket_web.dart'
    as impl;

/// Рукопожатие не прошло: соединение не открылось вовсе.
///
/// Ровно так выглядит отказ без сессии: сервер отвечает `401` на HTTP-запрос
/// апгрейда, и открытого сокета не появляется (`docs/api/websocket.md`, 2).
/// Беда в том, что **браузерный JS кода ответа не видит**: и отказ, и сетевой
/// сбой приходят одинаково, кодом `1006`. Поэтому отличить их клиент может
/// только повторной проверкой сессии — этим занимается `RealtimeClient`.
class RealtimeHandshakeException implements Exception {
  /// @nodoc
  const RealtimeHandshakeException(this.code);

  /// Код закрытия, если браузер его сообщил. `1006` — обычный случай.
  final int code;

  @override
  String toString() => 'RealtimeHandshakeException(code: $code)';
}

/// Почему закрылось уже открытое соединение.
///
/// Код нужен целиком, а не «закрылось или нет»: на `4401` и `4403` цикл
/// переподключения обязан остановиться (`docs/api/websocket.md`, 6).
class RealtimeClosure {
  /// @nodoc
  const RealtimeClosure(this.code);

  /// Код закрытия. `1006`, `1001` и прочие сетевые — обрыв.
  final int code;

  @override
  String toString() => 'RealtimeClosure(code: $code)';
}

/// Одно соединение живых обновлений.
///
/// Только транспорт: ни подписок, ни переподключения, ни разбора кадров.
/// Всё это живёт в `RealtimeClient` — иначе платформенная реализация
/// содержала бы логику протокола и её пришлось бы писать дважды.
abstract interface class RealtimeSocket {
  /// Текстовые кадры от сервера. Бинарных сервер не шлёт.
  Stream<String> get frames;

  /// Завершается, когда соединение закрылось.
  Future<RealtimeClosure> get closed;

  /// Отправляет текстовый кадр.
  void send(String frame);

  /// Закрывает соединение по инициативе клиента.
  void close();
}

/// Открывает соединения живых обновлений.
///
/// Спрятано за интерфейсом по той же причине, что [BrowserNavigator]:
/// веб-специфика не должна протекать в доменный код, а на мобильном клиенте
/// сессия предъявляется заголовком `Authorization`, а не cookie (ADR-0002).
abstract interface class RealtimeSocketFactory {
  /// Открывает соединение по адресу [url].
  ///
  /// Завершается, когда сокет **открыт**. Если рукопожатие не прошло,
  /// бросает [RealtimeHandshakeException].
  ///
  /// Cookie браузер прикладывает к рукопожатию сам — заголовки из браузерного
  /// JS задать нельзя, и веб-клиенту специально делать нечего
  /// (`websocket.md`, 2).
  Future<RealtimeSocket> connect(String url);
}

/// Платформенная реализация [RealtimeSocketFactory].
///
/// Подменяется в тестах: тестовому рендереру взять сервер негде, а проверять
/// надо логику протокола, а не браузерный `WebSocket`.
final realtimeSocketFactoryProvider = Provider<RealtimeSocketFactory>(
  (ref) => impl.createRealtimeSocketFactory(),
);

/// Адрес шлюза живых обновлений.
///
/// Тот же домен и тот же префикс `/api`, что и у HTTP (ADR-0001): Caddy
/// проксирует `/api/*` целиком, включая `Upgrade`.
final realtimeUrlProvider = Provider<String>(
  (ref) => realtimeUrlOf(
    AppConfig.apiOrigin.isNotEmpty
        ? AppConfig.apiOrigin
        : ref.watch(browserNavigatorProvider).origin,
  ),
);

/// Собирает адрес шлюза из origin приложения.
///
/// Схема меняется на `ws` или `wss` по схеме страницы, а не по догадке:
/// `wss` со страницы, открытой по `http`, не соединится, и наоборот.
///
/// Открыто для теста: ошибка здесь не видна ниоткуда — сокет просто
/// не откроется, а экран молча перестанет обновляться.
String realtimeUrlOf(String origin) {
  const path = '${AppConfig.apiPathPrefix}/ws';

  if (origin.startsWith('https://')) {
    return 'wss://${origin.substring('https://'.length)}$path';
  }
  if (origin.startsWith('http://')) {
    return 'ws://${origin.substring('http://'.length)}$path';
  }

  // Origin неизвестен — вне браузера. Открыть соединение по такому адресу
  // нельзя, и это правильно: платформенная заглушка откажет громко.
  return '$origin$path';
}
