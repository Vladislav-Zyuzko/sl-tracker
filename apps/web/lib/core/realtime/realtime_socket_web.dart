import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';

/// Реализация поверх браузерного `WebSocket`.
RealtimeSocketFactory createRealtimeSocketFactory() =>
    const _WebRealtimeSocketFactory();

class _WebRealtimeSocketFactory implements RealtimeSocketFactory {
  const _WebRealtimeSocketFactory();

  @override
  Future<RealtimeSocket> connect(String url) {
    final socket = web.WebSocket(url);
    final opened = Completer<RealtimeSocket>();
    final closed = Completer<RealtimeClosure>();
    final frames = StreamController<String>.broadcast();

    late final _WebRealtimeSocket wrapper;

    final onOpen = ((web.Event _) {
      if (!opened.isCompleted) opened.complete(wrapper);
    }).toJS;

    final onMessage = ((web.Event event) {
      final data = (event as web.MessageEvent).data;
      // Бинарных кадров сервер не отправляет; всё, что не строка, — не наше.
      if (data.isA<JSString>() && !frames.isClosed) {
        frames.add((data as JSString).toDart);
      }
    }).toJS;

    final onClose = ((web.Event event) {
      final code = event.isA<web.CloseEvent>()
          ? (event as web.CloseEvent).code
          : _abnormalClosure;

      if (opened.isCompleted) {
        if (!closed.isCompleted) closed.complete(RealtimeClosure(code));
      } else {
        // Сокет не открылся вовсе: это отказ на рукопожатии либо сеть.
        opened.completeError(RealtimeHandshakeException(code));
        if (!closed.isCompleted) closed.complete(RealtimeClosure(code));
      }

      unawaited(frames.close());
    }).toJS;

    // `error` у WebSocket не несёт подробностей по требованию стандарта:
    // иначе страница могла бы сканировать сеть по кодам ответа. Реагируем
    // на `close`, который приходит следом, — здесь только чтобы событие
    // не осталось необработанным.
    final onError = ((web.Event _) {}).toJS;

    socket
      ..addEventListener('open', onOpen)
      ..addEventListener('message', onMessage)
      ..addEventListener('close', onClose)
      ..addEventListener('error', onError);

    wrapper = _WebRealtimeSocket(
      socket: socket,
      controller: frames,
      closed: closed.future,
      detach: () {
        socket
          ..removeEventListener('open', onOpen)
          ..removeEventListener('message', onMessage)
          ..removeEventListener('close', onClose)
          ..removeEventListener('error', onError);
      },
    );

    return opened.future;
  }

  /// Закрытие без кадра закрытия: обрыв или непройденное рукопожатие.
  static const _abnormalClosure = 1006;
}

class _WebRealtimeSocket implements RealtimeSocket {
  _WebRealtimeSocket({
    required this.socket,
    required this.controller,
    required this.closed,
    required this.detach,
  }) {
    // Слушатели снимаются сразу после закрытия: сокет живёт часами,
    // а вкладку с трекером не закрывают неделями.
    unawaited(closed.whenComplete(detach));
  }

  /// Браузерный сокет.
  final web.WebSocket socket;

  /// Кадры, разложенные в поток.
  final StreamController<String> controller;

  /// Снимает слушателей событий сокета.
  final void Function() detach;

  @override
  final Future<RealtimeClosure> closed;

  @override
  Stream<String> get frames => controller.stream;

  @override
  void send(String frame) {
    if (socket.readyState != web.WebSocket.OPEN) return;

    socket.send(frame.toJS);
  }

  @override
  void close() {
    if (socket.readyState == web.WebSocket.CLOSED) return;

    // 1000 — нормальное закрытие по инициативе клиента: уход с экрана,
    // выход из приложения. Сервер по нему ничего не чинит.
    socket.close(_normalClosure);
  }

  /// Нормальное закрытие.
  static const _normalClosure = 1000;
}
