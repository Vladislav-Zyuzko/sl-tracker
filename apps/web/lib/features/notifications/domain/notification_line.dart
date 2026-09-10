import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/markdown_plain.dart';

/// Роль куска текста в строке уведомления.
enum NotificationSpanKind {
  /// Имя инициатора: `bodySStrong`, у непрочитанного — вес 600.
  actor,

  /// Само действие: `bodyS` `textSecondary`.
  plain,

  /// Ключ задачи: `bodySStrong` `accent`. Главный ориентир в ленте,
  /// поэтому не обрезается никогда.
  key,
}

/// Кусок первой строки уведомления.
@immutable
class NotificationSpan {
  /// @nodoc
  const NotificationSpan(this.text, this.kind);

  /// @nodoc
  final String text;

  /// @nodoc
  final NotificationSpanKind kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSpan && other.text == text && other.kind == kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => text;
}

/// Тексты и адреса строки уведомления
/// (`docs/design/screens/notifications.md`).
///
/// Текст собирается из `type`, `actor` и `payload`. **`payload` — снимок
/// на момент события**: он не меняется вслед за переименованием задачи или
/// правкой комментария (US-102). Поля `issueKey` и `commentId` верхнего
/// уровня — наоборот, состояние сейчас, и по ним строится переход.
sealed class NotificationLine {
  /// Сколько символов превью показывается во второй строке.
  ///
  /// Сервер присылает около сотни; после снятия разметки строка становится
  /// короче, а не длиннее, поэтому обрезка здесь — страховка от очень
  /// длинного слова, а не основной механизм.
  static const excerptLimit = 100;

  /// Имя инициатора. `null` у системного события — тогда «Система».
  static String actorOf(NotificationDto notification) {
    if (notification.type == NotificationDtoType.projectMemberJoined) {
      // Вступивший и есть герой строки: «Анна присоединилась к проекту».
      final member = notification.payload.memberName;
      if (member != null && member.isNotEmpty) return member;
    }

    return notification.actor?.displayName ?? 'Система';
  }

  /// Первая строка: событие.
  static List<NotificationSpan> spansOf(NotificationDto notification) {
    final payload = notification.payload;
    final key = payload.issueKey ?? notification.issueKey;
    final actor = NotificationSpan(
      actorOf(notification),
      NotificationSpanKind.actor,
    );

    List<NotificationSpan> aboutIssue(String action) => [
      actor,
      NotificationSpan(' $action', NotificationSpanKind.plain),
      if (key != null) ...[
        const NotificationSpan(' ', NotificationSpanKind.plain),
        NotificationSpan(key, NotificationSpanKind.key),
      ],
    ];

    return switch (notification.type) {
      NotificationDtoType.issueAssigned => aboutIssue(
        'назначил вас исполнителем',
      ),
      NotificationDtoType.issueAuthorAssigned => aboutIssue(
        'указал вас автором',
      ),
      NotificationDtoType.issueMentioned => aboutIssue('упомянул вас в'),
      NotificationDtoType.issueCommented => aboutIssue('прокомментировал'),
      NotificationDtoType.issueStatusChanged => [
        ...aboutIssue('перевёл'),
        NotificationSpan(
          ' из ${_quoted(payload.fromStatusName)} '
          'в ${_quoted(payload.toStatusName)}',
          NotificationSpanKind.plain,
        ),
      ],
      NotificationDtoType.projectMemberJoined => [
        actor,
        const NotificationSpan(
          ' присоединился к проекту',
          NotificationSpanKind.plain,
        ),
        NotificationSpan(
          ' ${payload.projectName ?? ''}'.trimRight(),
          NotificationSpanKind.plain,
        ),
      ],
      // Сервер вправе добавить тип уведомления, и строка от этого не должна
      // становиться пустой: показываем то, что точно известно.
      NotificationDtoType.$unknown => aboutIssue('обновил'),
    };
  }

  /// Вторая строка: контекст. Пустая строка — строки нет, высота не меняется.
  static String contextOf(NotificationDto notification) {
    final payload = notification.payload;

    return switch (notification.type) {
      NotificationDtoType.issueAssigned ||
      NotificationDtoType.issueAuthorAssigned => payload.issueTitle ?? '',
      NotificationDtoType.issueMentioned ||
      NotificationDtoType.issueCommented => MarkdownPlain.of(
        payload.excerpt ?? '',
        limit: excerptLimit,
      ),
      _ => '',
    };
  }

  /// Доступное имя строки целиком.
  ///
  /// Слово «Непрочитанное» в начале обязательно: точка и жирность незрячему
  /// недоступны (`notifications.md`, «Доступность»).
  ///
  /// Строка, которой некуда вести, заканчивается словом «недоступно», а не
  /// «Открыть»: обещать действие, которого нет, нельзя.
  static String semanticsOf(
    NotificationDto notification, {
    required String time,
  }) {
    final line = spansOf(notification).map((span) => span.text).join();
    final context = contextOf(notification);

    return [
      if (notification.readAt == null) 'Непрочитанное.',
      '$line.',
      if (context.isNotEmpty) '$context.',
      '$time.',
      if (targetOf(notification) == null) unavailableLabel else 'Открыть',
    ].join(' ');
  }

  /// Пометка строки, которой некуда вести (`notifications.md`,
  /// «Когда переходить некуда»).
  static const unavailableLabel = 'недоступно';

  /// Тост-страховка на случай, когда нажатие всё же произошло: гонка
  /// с удалением задачи, клавиатура из устаревшего состояния.
  ///
  /// Формулировка дизайнера: называет вещи из глоссария («задача», «проект»),
  /// объясняет причину и не звучит как отказ по правам.
  static const noTargetToast = 'Открывать нечего: задача или проект удалены';

  /// Адрес перехода. `null` — переходить некуда.
  ///
  /// Задача, которой больше нет или которая в чужом теперь проекте, приходит
  /// с `issueKey: null` наверху. Переход всё равно строится — по ключу
  /// из снимка: человек попадёт на честное «Задача не найдена» (US-103),
  /// а не на строку, которая молча не нажимается.
  static String? targetOf(NotificationDto notification) {
    if (notification.type == NotificationDtoType.projectMemberJoined) {
      final slug = notification.projectSlug ?? notification.payload.projectSlug;

      return slug == null ? null : '${AppRoutes.projectPath(slug)}?tab=members';
    }

    final key = notification.issueKey ?? notification.payload.issueKey;
    if (key == null) return null;

    final path = AppRoutes.issuePath(key);
    final comment = notification.commentId;

    // Упоминание в описании прокручивает к описанию, а не к комментарию
    // (US-104): якорь в таком уведомлении не нужен.
    if (comment == null || _mentionsDescription(notification)) return path;

    return '$path?comment=$comment';
  }

  /// Ведёт ли уведомление к комментарию, которого больше нет.
  ///
  /// Тогда открывается сама задача, а человеку говорят, что комментарий
  /// удалён (US-102) — иначе он будет искать глазами то, чего нет.
  static bool pointsToDeletedComment(NotificationDto notification) {
    if (notification.commentId != null) return false;

    return switch (notification.type) {
      NotificationDtoType.issueCommented => true,
      NotificationDtoType.issueMentioned => !_mentionsDescription(notification),
      _ => false,
    };
  }

  static bool _mentionsDescription(NotificationDto notification) =>
      notification.payload.source == NotificationPayloadDtoSource.description;

  /// Название статуса в кавычках и с заглавной, как в глоссарии.
  static String _quoted(String? name) {
    if (name == null || name.isEmpty) return '«—»';

    return '«${name[0].toUpperCase()}${name.substring(1)}»';
  }
}
