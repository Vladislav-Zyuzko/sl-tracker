import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';

/// Реализация для платформ без браузерного `WebSocket`.
///
/// Осознанно падает, а не молчит: живые обновления — не украшение, и если
/// однажды приложение соберут под мобильный клиент, отсутствие транспорта
/// должно быть видно сразу. Приложение при этом остаётся рабочим:
/// `RealtimeClient` ловит отказ и переходит в состояние «нет соединения»,
/// а данные грузятся обычными запросами (`websocket.md`, 1).
RealtimeSocketFactory createRealtimeSocketFactory() =>
    const _UnsupportedRealtimeSocketFactory();

class _UnsupportedRealtimeSocketFactory implements RealtimeSocketFactory {
  const _UnsupportedRealtimeSocketFactory();

  @override
  Future<RealtimeSocket> connect(String url) => throw UnsupportedError(
    'Живые обновления вне браузера требуют своей реализации транспорта: '
    'на мобильном клиенте сессия предъявляется заголовком Authorization, '
    'а не cookie (ADR-0002).',
  );
}
