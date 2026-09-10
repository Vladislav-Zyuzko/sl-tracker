import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';

/// Состояние соединения живых обновлений.
enum RealtimeStatus {
  /// Соединение не нужно: пользователь не вошёл.
  idle,

  /// Первое подключение. Полосу офлайна на нём не показываем — приложение
  /// только что запустилось, и данные всё равно едут обычными запросами.
  connecting,

  /// Соединение живо, подписки восстановлены.
  online,

  /// Соединения нет, попытки продолжаются. Это и есть «нет соединения»
  /// для полосы офлайна (`components.md`, 17.4).
  offline,

  /// Переподключение остановлено окончательно: сессия погашена или доступ
  /// отозван. Дальше — экран входа, а не повторные попытки.
  stopped,
}

/// Клиент живых обновлений (`docs/api/websocket.md`).
///
/// Отвечает за протокол целиком: подписки с подсчётом ссылок, канонические
/// ярлыки тем, прикладной `ping`, переподключение с экспоненциальной
/// задержкой и остановку на окончательных кодах закрытия.
///
/// Три вещи, на которых клиенты ломаются чаще всего, решены здесь, а не
/// на экранах:
///
/// 1. **Ярлык темы для сравнения берётся из ответа `subscribed`**, а не из
///    того, что отправили: `issue:dev-42` и `issue:DEV-42` — одна тема,
///    а у переименованного проекта канонический ярлык вообще другой.
/// 2. **После переподключения экраны обязаны перечитать данные** — за время
///    обрыва события потеряны. Клиент присылает им [RealtimeResync], и это
///    не рекомендация, а часть протокола подписки.
/// 3. **На `4401` и `4403` цикл переподключения останавливается**, иначе
///    клиент будет молотить сервер после выхода пользователя.
///
/// Доставка не гарантирована: событие — повод перечитать, а не источник
/// правды. Приложение, которое без живых обновлений ломается, написано
/// неправильно, поэтому клиент нигде не является обязательным условием
/// загрузки данных.
class RealtimeClient {
  /// @nodoc
  RealtimeClient({
    required this.socketFactory,
    required this.url,
    required this.onSessionLost,
    required this.onHandshakeSuspect,
  });

  /// Чем открывать соединение.
  final RealtimeSocketFactory socketFactory;

  /// Адрес шлюза.
  final String url;

  /// Сессии больше нет: коды `4401` и `4403`.
  final VoidCallback onSessionLost;

  /// Рукопожатие не проходит подряд слишком долго.
  ///
  /// Браузер не показывает код ответа на апгрейд, поэтому отказ без сессии
  /// снаружи неотличим от обрыва сети. Единственный честный способ различить
  /// их — сходить обычным запросом за `GET /api/me`: он ответит 401, и
  /// приложение уйдёт на вход.
  final VoidCallback onHandshakeSuspect;

  /// Начальная задержка переподключения.
  static const baseReconnectDelay = Duration(seconds: 1);

  /// Потолок задержки переподключения.
  static const maxReconnectDelay = Duration(seconds: 30);

  /// Сколько неудачных рукопожатий подряд заставляют перепроверить сессию.
  static const handshakeFailuresBeforeSessionCheck = 3;

  /// Такт по умолчанию, если сервер не прислал `heartbeatSeconds`.
  static const defaultHeartbeat = Duration(seconds: 30);

  /// Состояние соединения. Слушается провайдером, а не экранами напрямую.
  ValueListenable<RealtimeStatus> get status => _status;
  final _status = ValueNotifier(RealtimeStatus.idle);

  final _topics = <String, _RealtimeTopic>{};
  final _byCanonical = <String, _RealtimeTopic>{};
  final _random = Random();

  RealtimeSocket? _socket;
  StreamSubscription<String>? _frames;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _pongTimer;

  var _started = false;
  var _connecting = false;
  var _everOnline = false;
  var _attempt = 0;
  var _handshakeFailures = 0;
  var _nextPingId = 0;
  var _heartbeat = defaultHeartbeat;
  var _disposed = false;

  /// Открывает соединение. Повторный вызов ничего не делает.
  void start() {
    if (_started || _disposed) return;

    _started = true;
    _attempt = 0;
    unawaited(_connect());
  }

  /// Закрывает соединение и оставляет клиент готовым к повторному запуску.
  ///
  /// Вызывается при выходе пользователя: сокет надо закрыть немедленно,
  /// а не ждать, пока сервер заметит погашенную сессию.
  void stop() {
    _teardown();
    _started = false;
    _everOnline = false;
    _setStatus(RealtimeStatus.idle);
  }

  /// Останавливает переподключение окончательно.
  void _stopFinally() {
    _teardown();
    _started = false;
    _everOnline = false;
    _setStatus(RealtimeStatus.stopped);
  }

  /// Подписка на тему.
  ///
  /// Возвращает поток сигналов: события темы, [RealtimeResync] после
  /// восстановления связи и [RealtimeTopicLost], когда права на тему
  /// потеряны. Пока поток никто не слушает, подписки на сервере нет —
  /// отмена подписки уходит на сервер сама, и «протекших» тем не остаётся.
  ///
  /// Несколько слушателей одной темы допустимы: подписка на сервере одна,
  /// клиент считает ссылки.
  Stream<RealtimeSignal> signals(String label) {
    final key = label.toLowerCase();
    late StreamController<RealtimeSignal> output;
    StreamSubscription<RealtimeSignal>? inner;

    output = StreamController<RealtimeSignal>(
      onListen: () {
        final topic = _retain(key, label);
        inner = topic.signals.stream.listen(output.add);
      },
      onCancel: () async {
        await inner?.cancel();
        _release(key);
      },
    );

    return output.stream;
  }

  /// @nodoc
  void dispose() {
    _disposed = true;
    _teardown();
    for (final topic in _topics.values) {
      unawaited(topic.signals.close());
    }
    _topics.clear();
    _byCanonical.clear();
    _status.dispose();
  }

  // --- Подписки -------------------------------------------------------------

  _RealtimeTopic _retain(String key, String label) {
    final topic = _topics.putIfAbsent(key, () => _RealtimeTopic(label));
    topic.listeners++;

    if (topic.listeners == 1 && _isOnline) _sendSubscribe(topic);

    return topic;
  }

  void _release(String key) {
    final topic = _topics[key];
    if (topic == null) return;

    topic.listeners--;
    if (topic.listeners > 0) return;

    // Тему держать больше некому: снимаем подписку на сервере. Сокет живёт
    // часами, а предел тем на соединение — 20, и «забытые» темы его съедят.
    if (_isOnline && topic.active && !topic.automatic) {
      _send({'type': 'unsubscribe', 'id': topic.label, 'topic': topic.label});
    }

    _topics.remove(key);
    _byCanonical.removeWhere((_, value) => identical(value, topic));
    unawaited(topic.signals.close());
  }

  void _sendSubscribe(_RealtimeTopic topic) {
    // Ярлык корреляции — сам ярлык темы: он уникален в пределах соединения
    // и укладывается в предел длины `id`.
    _send({'type': 'subscribe', 'id': topic.label, 'topic': topic.label});
  }

  bool get _isOnline => _status.value == RealtimeStatus.online;

  // --- Соединение -----------------------------------------------------------

  Future<void> _connect() async {
    if (!_started || _disposed || _connecting || _socket != null) return;

    _connecting = true;
    _setStatus(
      _everOnline ? RealtimeStatus.offline : RealtimeStatus.connecting,
    );

    try {
      final socket = await socketFactory.connect(url);

      // Пока шло рукопожатие, пользователь мог выйти.
      if (!_started || _disposed) {
        socket.close();

        return;
      }

      _socket = socket;
      _handshakeFailures = 0;
      _frames = socket.frames.listen(_onFrame);
      unawaited(socket.closed.then(_onClosed));
    } on RealtimeHandshakeException {
      _handshakeFailures++;
      _scheduleReconnect();

      if (_handshakeFailures >= handshakeFailuresBeforeSessionCheck) {
        _handshakeFailures = 0;
        onHandshakeSuspect();
      }
    } on UnsupportedError {
      // Транспорта нет вовсе: платформа не умеет WebSocket. Повторять
      // нечего — через секунду он не появится. Приложение остаётся рабочим,
      // просто без живых обновлений, и полосу офлайна показывать нельзя:
      // соединение с сервером тут ни при чём.
      _started = false;
      _setStatus(RealtimeStatus.idle);
    } on Object {
      // Адрес непригоден или транспорт отказал иначе. Приложение обязано
      // работать и так — просто без живых обновлений.
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onClosed(RealtimeClosure closure) {
    if (_disposed) return;

    _dropSocket();

    if (RealtimeCloseCodes.isFinal(closure.code)) {
      // Сессия погашена или доступ отозван: переподключаться нельзя,
      // иначе клиент будет молотить сервер после выхода пользователя.
      _stopFinally();
      onSessionLost();

      return;
    }

    if (!_started) return;

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_started || _disposed) return;

    _setStatus(RealtimeStatus.offline);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_backoff(), () => unawaited(_connect()));
  }

  /// Экспоненциальная задержка со случайной добавкой.
  ///
  /// Добавка не для красоты: после перезапуска сервера все вкладки всех
  /// пользователей проснулись бы одновременно и положили бы его снова.
  Duration _backoff() {
    final step = min(
      baseReconnectDelay.inMilliseconds * pow(2, _attempt).toInt(),
      maxReconnectDelay.inMilliseconds,
    );
    _attempt++;

    return Duration(milliseconds: step + _random.nextInt(step ~/ 2 + 1));
  }

  void _dropSocket() {
    _heartbeatTimer?.cancel();
    _pongTimer?.cancel();
    unawaited(_frames?.cancel());
    _frames = null;
    _socket = null;

    // Состояние подписок живёт в соединении: закрылся сокет — на сервере
    // не осталось ничего (`websocket.md`, 6).
    for (final topic in _topics.values) {
      topic.active = false;
    }
    _byCanonical.clear();
  }

  void _teardown() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final socket = _socket;
    _dropSocket();
    socket?.close();
  }

  void _setStatus(RealtimeStatus value) {
    if (_disposed || _status.value == value) return;

    _status.value = value;
  }

  void _send(Map<String, Object?> frame) => _socket?.send(jsonEncode(frame));

  // --- Кадры ----------------------------------------------------------------

  void _onFrame(String raw) {
    final frame = RealtimeFrame.decode(raw);

    switch (frame) {
      case RealtimeReadyFrame():
        _onReady(frame);
      case RealtimeSubscribedFrame():
        _onSubscribed(frame);
      case RealtimeUnsubscribedFrame():
        break;
      case RealtimePongFrame():
        _pongTimer?.cancel();
      case RealtimeErrorFrame():
        _onError(frame);
      case RealtimeEvent():
        _onEvent(frame);
      case RealtimeUnknownFrame():
        // Сервер вправе добавить тип кадра; клиент от этого не падает.
        break;
    }
  }

  void _onReady(RealtimeReadyFrame frame) {
    _attempt = 0;
    _heartbeat = frame.heartbeat;
    _everOnline = true;
    _setStatus(RealtimeStatus.online);

    // Сервер сам подписал соединение на `user:me` — просить его отдельной
    // командой незачем, а лишняя команда на чужую тему была бы отказом.
    final automatic = {for (final topic in frame.topics) topic.toLowerCase()};

    for (final topic in _topics.values) {
      final canonical = frame.topics.firstWhere(
        (item) => item.toLowerCase() == topic.label.toLowerCase(),
        orElse: () => '',
      );

      if (canonical.isEmpty) {
        topic.automatic = false;
        _sendSubscribe(topic);

        continue;
      }

      topic.automatic = automatic.contains(topic.label.toLowerCase());
      _activate(topic, canonical);
    }

    _startHeartbeat();
  }

  void _onSubscribed(RealtimeSubscribedFrame frame) {
    final topic = _topics[(frame.id ?? frame.topic).toLowerCase()];
    if (topic == null) return;

    _activate(topic, frame.topic);
  }

  /// Отмечает тему живой и, если это восстановление после обрыва, просит
  /// экран перечитать данные.
  void _activate(_RealtimeTopic topic, String canonical) {
    final resync = topic.everActive;

    topic
      ..active = true
      ..everActive = true
      ..canonical = canonical;
    _byCanonical[canonical.toLowerCase()] = topic;

    // Порядок важен: сначала подписка восстановлена, потом перечитывание.
    // Наоборот — и события, случившиеся между запросом и подпиской,
    // потерялись бы во второй раз.
    if (resync) topic.emit(RealtimeResync(canonical));
  }

  void _onError(RealtimeErrorFrame frame) {
    final id = frame.id;

    if (id != null) {
      // Отказ на нашу команду: тему считаем потерянной, экран перечитает
      // данные и покажет то, что вернёт сервер.
      final topic = _topics[id.toLowerCase()];
      if (topic == null) return;

      topic.active = false;
      topic.emit(RealtimeTopicLost(topic.canonical ?? topic.label));

      return;
    }

    if (frame.code != RealtimeErrorCodes.topicForbidden) return;

    // Сервер снял подписку сам: человека исключили из проекта уже после
    // подписки. Кадр отказа **не несёт ярлыка темы** (`websocket.md`, 4),
    // поэтому какую именно тему отобрали, клиент не знает: просим перечитать
    // все, кроме своей собственной, — её отобрать нельзя. Запрос добавить
    // `topic` в кадр отказа записан в отчёте.
    for (final topic in _topics.values) {
      if (topic.automatic || !topic.active) continue;

      topic.active = false;
      topic.emit(RealtimeTopicLost(topic.canonical ?? topic.label));
    }
  }

  void _onEvent(RealtimeEvent event) {
    // Сравниваем с каноническим ярлыком, а не с тем, что отправляли:
    // `issue:dev-42` и `issue:DEV-42` — одна тема, а у переименованного
    // проекта ярлык вовсе другой (`websocket.md`, 4).
    final topic =
        _byCanonical[event.topic.toLowerCase()] ??
        _topics[event.topic.toLowerCase()];

    topic?.emit(event);
  }

  // --- Живость соединения ---------------------------------------------------

  /// Прикладной `ping`.
  ///
  /// Кадры протокола браузерный JS не видит, поэтому молчащий сервер иначе
  /// не заметить: вкладка будет считать себя подключённой часами
  /// (`websocket.md`, 6).
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) {
      _send({'type': 'ping', 'id': 'p${_nextPingId++}'});

      _pongTimer?.cancel();
      _pongTimer = Timer(_pongTimeout, () {
        // Ответа нет: соединение мертво, хотя браузер об этом не знает.
        // Закрываем его сами — дальше работает обычный путь обрыва,
        // с той же задержкой и тем же переподключением.
        _socket?.close();
      });
    });
  }

  /// Сколько ждать `pong`.
  ///
  /// Ровно половина такта, и это не вкусовщина: ожидание длиннее такта
  /// сбрасывалось бы следующим тиком, и молчащий сервер не обнаружился бы
  /// никогда.
  Duration get _pongTimeout =>
      Duration(milliseconds: max(_heartbeat.inMilliseconds ~/ 2, 500));
}

/// Одна тема с её подписчиками.
class _RealtimeTopic {
  _RealtimeTopic(this.label);

  /// Ярлык, которым тему запросили. Может быть прежним именем проекта.
  final String label;

  /// Канонический ярлык из ответа сервера.
  String? canonical;

  /// Сколько экранов держат тему.
  int listeners = 0;

  /// Подтверждена ли подписка сейчас.
  bool active = false;

  /// Была ли подписка активной хоть раз: по этому признаку отличается
  /// восстановление после обрыва от первой подписки, ради которой
  /// перечитывать ничего не нужно — экран только что загрузил данные сам.
  bool everActive = false;

  /// Подписал ли сервер соединение на тему сам (`user:me`).
  bool automatic = false;

  final signals = StreamController<RealtimeSignal>.broadcast();

  void emit(RealtimeSignal signal) {
    if (!signals.isClosed) signals.add(signal);
  }
}
