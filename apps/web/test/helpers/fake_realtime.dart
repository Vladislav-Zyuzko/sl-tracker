import 'dart:async';
import 'dart:convert';

import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';

/// Подставной сокет живых обновлений.
///
/// Тест управляет им как сервером: подсовывает кадры, читает отправленные
/// команды, закрывает соединение нужным кодом. Настоящий `WebSocket` в тесте
/// взять негде, а проверять надо протокол, а не браузер.
class FakeRealtimeSocket implements RealtimeSocket {
  /// @nodoc
  FakeRealtimeSocket();

  final _frames = StreamController<String>.broadcast();
  final _closed = Completer<RealtimeClosure>();

  /// Всё, что клиент отправил, в порядке отправки.
  final sent = <Map<String, Object?>>[];

  /// Закрыл ли клиент соединение сам.
  var closedByClient = false;

  @override
  Stream<String> get frames => _frames.stream;

  @override
  Future<RealtimeClosure> get closed => _closed.future;

  @override
  void send(String frame) =>
      sent.add(jsonDecode(frame) as Map<String, Object?>);

  @override
  void close() {
    closedByClient = true;
    emitClose(1000);
  }

  /// Команды одного типа, отправленные клиентом.
  Iterable<Map<String, Object?>> commands(String type) =>
      sent.where((frame) => frame['type'] == type);

  /// Отправляет кадр «от сервера».
  void emit(Map<String, Object?> frame) {
    if (!_frames.isClosed) _frames.add(jsonEncode(frame));
  }

  /// Кадр `ready`.
  void emitReady({
    List<String> topics = const ['user:me'],
    int heartbeatSeconds = 30,
  }) => emit({
    'type': 'ready',
    'topics': topics,
    'heartbeatSeconds': heartbeatSeconds,
    'maxTopics': 20,
  });

  /// Кадр `subscribed` с каноническим ярлыком.
  void emitSubscribed({required String id, required String topic}) =>
      emit({'type': 'subscribed', 'id': id, 'topic': topic});

  /// Событие темы.
  void emitEvent({
    required String topic,
    required String event,
    String? actorId,
    Map<String, Object?> data = const {},
  }) => emit({
    'type': 'event',
    'topic': topic,
    'event': event,
    'at': '2026-09-09T10:15:30.412Z',
    'actorId': actorId,
    'data': data,
  });

  /// Закрытие соединения сервером.
  void emitClose(int code) {
    if (!_closed.isCompleted) _closed.complete(RealtimeClosure(code));
    if (!_frames.isClosed) unawaited(_frames.close());
  }
}

/// Подставная фабрика соединений.
class FakeRealtimeSocketFactory implements RealtimeSocketFactory {
  /// @nodoc
  FakeRealtimeSocketFactory({this.handshakeFailures = 0});

  /// Сколько первых рукопожатий провалится: так выглядит и отказ без сессии,
  /// и обрыв сети — браузер их не различает.
  int handshakeFailures;

  /// Все открытые соединения по порядку.
  final sockets = <FakeRealtimeSocket>[];

  /// Сколько раз пытались подключиться.
  var attempts = 0;

  /// Последнее открытое соединение.
  FakeRealtimeSocket get last => sockets.last;

  @override
  Future<RealtimeSocket> connect(String url) async {
    attempts++;

    if (handshakeFailures > 0) {
      handshakeFailures--;

      throw const RealtimeHandshakeException(1006);
    }

    final socket = FakeRealtimeSocket();
    sockets.add(socket);

    return socket;
  }
}
