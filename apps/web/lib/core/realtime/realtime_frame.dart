import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Ярлыки тем живых обновлений (`docs/api/websocket.md`, 4).
///
/// Собираются в одном месте, потому что ошибка в ярлыке не видна ниоткуда:
/// сервер ответит `topic_forbidden`, и экран просто перестанет обновляться.
sealed class RealtimeTopics {
  /// Тема задачи: комментарии, изменения полей, вложения, удаление.
  static String issue(String key) => 'issue:$key';

  /// Тема проекта: состав участников.
  static String project(String slug) => 'project:$slug';

  /// Своя тема: уведомления и счётчик непрочитанных. Сервер подписывает
  /// на неё сам при открытии соединения.
  static const me = 'user:me';
}

/// Имена событий каталога (`docs/api/websocket.md`, 5).
sealed class RealtimeEvents {
  /// @nodoc
  static const issueUpdated = 'issue.updated';

  /// @nodoc
  static const issueDeleted = 'issue.deleted';

  /// @nodoc
  static const commentCreated = 'comment.created';

  /// @nodoc
  static const commentUpdated = 'comment.updated';

  /// @nodoc
  static const commentDeleted = 'comment.deleted';

  /// @nodoc
  static const memberJoined = 'project.member_joined';

  /// @nodoc
  static const memberUpdated = 'project.member_updated';

  /// @nodoc
  static const memberRemoved = 'project.member_removed';

  /// @nodoc
  static const notificationCreated = 'notification.created';

  /// @nodoc
  static const notificationRead = 'notification.read';
}

/// Коды ошибок команд (`docs/api/websocket.md`, 3).
sealed class RealtimeErrorCodes {
  /// Темы нет либо она недоступна — снаружи неотличимо.
  static const topicForbidden = 'topic_forbidden';

  /// Тема не разбирается, в том числе `user:<чужой-id>`.
  static const invalidTopic = 'invalid_topic';

  /// Превышен предел тем на соединение.
  static const tooManyTopics = 'too_many_topics';
}

/// Коды закрытия соединения (`docs/api/websocket.md`, 6).
sealed class RealtimeCloseCodes {
  /// Сессия истекла или погашена. Переподключаться нельзя.
  static const sessionExpired = 4401;

  /// Доступ к трекеру отозван или пользователь вышел. Переподключаться нельзя.
  static const accessRevoked = 4403;

  /// Сервер выключается: переподключиться с задержкой.
  static const serverShutdown = 4499;

  /// Окончателен ли код: на нём цикл переподключения останавливается,
  /// иначе клиент молотит сервер после выхода пользователя.
  static bool isFinal(int code) =>
      code == sessionExpired || code == accessRevoked;
}

/// Кадр, пришедший от сервера.
///
/// Разбирается руками, а не генерацией: WebSocket в OpenAPI не описан
/// (`docs/api/websocket.md`, вступление), и генератору взять форму кадров
/// неоткуда. Правило «DTO руками не пишутся» касается контракта REST —
/// здесь его источника просто не существует.
///
/// Незнакомый кадр — это [RealtimeUnknownFrame], а не исключение: сервер
/// имеет право добавить тип, и клиент от этого падать не должен.
sealed class RealtimeFrame {
  /// @nodoc
  const RealtimeFrame();

  /// Разбирает текстовый кадр.
  ///
  /// Возвращает [RealtimeUnknownFrame] на всё, что не разобралось: битый
  /// JSON, не объект, неизвестный `type`. Бинарных кадров сервер не шлёт.
  static RealtimeFrame decode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const RealtimeUnknownFrame('invalid_json');
    }

    if (decoded is! Map<String, Object?>) {
      return const RealtimeUnknownFrame('not_an_object');
    }

    final type = decoded['type'];
    if (type is! String) return const RealtimeUnknownFrame('no_type');

    return switch (type) {
      'ready' => RealtimeReadyFrame(
        topics: _stringList(decoded['topics']),
        heartbeat: Duration(seconds: _int(decoded['heartbeatSeconds']) ?? 30),
        maxTopics: _int(decoded['maxTopics']) ?? 20,
      ),
      'subscribed' => RealtimeSubscribedFrame(
        id: _string(decoded['id']),
        topic: _string(decoded['topic']) ?? '',
      ),
      'unsubscribed' => RealtimeUnsubscribedFrame(
        id: _string(decoded['id']),
        topic: _string(decoded['topic']) ?? '',
      ),
      'pong' => RealtimePongFrame(id: _string(decoded['id'])),
      'error' => RealtimeErrorFrame(
        id: _string(decoded['id']),
        code: _string(decoded['code']) ?? 'unknown',
        message: _string(decoded['message']),
      ),
      'event' => RealtimeEvent(
        topic: _string(decoded['topic']) ?? '',
        event: _string(decoded['event']) ?? '',
        at: DateTime.tryParse(_string(decoded['at']) ?? ''),
        actorId: _string(decoded['actorId']),
        data: _map(decoded['data']),
      ),
      _ => RealtimeUnknownFrame(type),
    };
  }

  static String? _string(Object? value) => value is String ? value : null;

  static int? _int(Object? value) => switch (value) {
    final int value => value,
    final num value => value.toInt(),
    _ => null,
  };

  static List<String> _stringList(Object? value) => switch (value) {
    final List<Object?> list => [
      for (final item in list)
        if (item is String) item,
    ],
    _ => const [],
  };

  static Map<String, Object?> _map(Object? value) =>
      value is Map<String, Object?> ? value : const {};
}

/// Соединение открыто и готово принимать команды.
@immutable
final class RealtimeReadyFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimeReadyFrame({
    required this.topics,
    required this.heartbeat,
    required this.maxTopics,
  });

  /// Темы, на которые сервер подписал соединение сам: как минимум `user:me`.
  final List<String> topics;

  /// Такт проверки живости соединения.
  final Duration heartbeat;

  /// Предел тем на одно соединение.
  final int maxTopics;
}

/// Подписка принята. `topic` — **канонический** ярлык.
@immutable
final class RealtimeSubscribedFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimeSubscribedFrame({required this.id, required this.topic});

  /// Корреляция запроса.
  final String? id;

  /// Канонический ярлык темы: сравнивать события надо с ним, а не с тем,
  /// что отправил клиент (`websocket.md`, 4).
  final String topic;
}

/// Подписка снята.
@immutable
final class RealtimeUnsubscribedFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimeUnsubscribedFrame({required this.id, required this.topic});

  /// @nodoc
  final String? id;

  /// @nodoc
  final String topic;
}

/// Ответ на прикладной `ping`.
@immutable
final class RealtimePongFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimePongFrame({required this.id});

  /// @nodoc
  final String? id;
}

/// Команда отклонена. Соединение при этом остаётся живым.
@immutable
final class RealtimeErrorFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimeErrorFrame({required this.id, required this.code, this.message});

  /// Корреляция отклонённой команды. `null` — сервер снял подписку сам:
  /// права на тему потеряны уже после подписки (`websocket.md`, 4).
  final String? id;

  /// @nodoc
  final String code;

  /// Техническое описание. В интерфейс не выводится.
  final String? message;
}

/// Незнакомый кадр. Игнорируется, но не роняет соединение.
@immutable
final class RealtimeUnknownFrame extends RealtimeFrame {
  /// @nodoc
  const RealtimeUnknownFrame(this.type);

  /// Значение `type` или причина, по которой кадр не разобрался.
  final String type;
}

/// Что экран узнаёт из подписки на тему.
///
/// Не только события: восстановление подписки после обрыва и потеря темы —
/// такие же поводы что-то сделать, и обрабатываются они там же, где события.
sealed class RealtimeSignal {
  /// @nodoc
  const RealtimeSignal();

  /// Тема, к которой относится сигнал.
  String get topic;
}

/// Событие темы.
///
/// Это **сигнал, а не состояние** (`websocket.md`, 1): полные данные клиент
/// забирает обычным HTTP-запросом.
@immutable
final class RealtimeEvent extends RealtimeSignal implements RealtimeFrame {
  /// @nodoc
  const RealtimeEvent({
    required this.topic,
    required this.event,
    required this.at,
    required this.actorId,
    required this.data,
  });

  @override
  final String topic;

  /// Имя события из каталога, см. [RealtimeEvents].
  final String event;

  /// Момент публикации на сервере. `null` — сервер прислал кадр без `at`.
  final DateTime? at;

  /// Кто вызвал событие. `null` — системное.
  final String? actorId;

  /// Полезная нагрузка события.
  final Map<String, Object?> data;

  /// Своё ли это действие.
  ///
  /// По нему отличают чужую правку от собственной: подсветку «внешнее
  /// изменение» на своё действие ставить не нужно (`websocket.md`, 9).
  bool isMine(String? currentUserId) =>
      currentUserId != null && actorId == currentUserId;

  /// Строковое поле нагрузки.
  String? text(String key) {
    final value = data[key];

    return value is String ? value : null;
  }

  /// Числовое поле нагрузки: `unreadCount`.
  int? number(String key) => switch (data[key]) {
    final int value => value,
    final num value => value.toInt(),
    _ => null,
  };

  /// Изменённые поля задачи. Имена совпадают с полями `GET /api/issues/{key}`.
  List<String> get changedFields => switch (data['changedFields']) {
    final List<Object?> list => [
      for (final item in list)
        if (item is String) item,
    ],
    _ => const [],
  };

  @override
  String toString() => 'RealtimeEvent($event, topic: $topic)';
}

/// Подписка восстановлена после обрыва.
///
/// Обязывает экран **перечитать данные обычным запросом**: за время обрыва
/// события были потеряны, и без этого лента останется устаревшей
/// (`websocket.md`, 6).
@immutable
final class RealtimeResync extends RealtimeSignal {
  /// @nodoc
  const RealtimeResync(this.topic);

  @override
  final String topic;
}

/// Тема потеряна: прав на неё больше нет.
///
/// Экран перечитывает данные обычным запросом и показывает то, что вернёт
/// сервер, — для чужого проекта это будет 404 (`websocket.md`, 4).
@immutable
final class RealtimeTopicLost extends RealtimeSignal {
  /// @nodoc
  const RealtimeTopicLost(this.topic);

  @override
  final String topic;
}
