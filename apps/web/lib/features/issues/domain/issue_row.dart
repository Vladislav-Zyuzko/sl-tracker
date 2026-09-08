import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_status_ref.dart';

/// Исполнитель в строке списка.
///
/// Отдельный маленький тип, а не DTO: строка списка живёт в виртуализированном
/// списке на тысячу элементов, и тащить туда контрактную схему со всеми
/// её `num` и `nullable` — значит преобразовывать типы в `build`.
@immutable
class IssueRowUser {
  /// @nodoc
  const IssueRowUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  /// @nodoc
  final String id;

  /// @nodoc
  final String displayName;

  /// @nodoc
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueRowUser &&
          other.id == id &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, displayName, avatarUrl);
}

/// Строка списка задач очереди.
///
/// Ровно те поля, что рисует строка: описания, автора и ссылок здесь нет —
/// их нет и в ответе сервера, и это не упущение контракта, а его смысл
/// (прокрутка на 1000 задач не должна возить лишние килобайты).
@immutable
class IssueRow {
  /// @nodoc
  const IssueRow({
    required this.key,
    required this.title,
    required this.status,
    required this.priority,
    this.storyPoints,
    this.assignee,
  });

  /// Ключ вида `DEV-42`. Он же адрес задачи.
  final String key;

  /// Тема задачи.
  final String title;

  /// Статус: палитра, название и категория.
  final IssueStatusRef status;

  /// Приоритет 0–100 с шагом 10. Пустым не бывает (D-15).
  final int priority;

  /// Сложность в story points. `null` — «не оценено» (D-16).
  final int? storyPoints;

  /// Исполнитель. `null` — «Не назначен».
  final IssueRowUser? assignee;

  /// Закрыта ли задача: ключ и тема в строке приглушаются.
  bool get isDone => status.isDone;

  /// @nodoc
  IssueRow copyWith({IssueStatusRef? status}) => IssueRow(
    key: key,
    title: title,
    status: status ?? this.status,
    priority: priority,
    storyPoints: storyPoints,
    assignee: assignee,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueRow &&
          other.key == key &&
          other.title == title &&
          other.status == status &&
          other.priority == priority &&
          other.storyPoints == storyPoints &&
          other.assignee == assignee;

  @override
  int get hashCode =>
      Object.hash(key, title, status, priority, storyPoints, assignee);
}

/// Перевод строки списка из контракта.
extension IssueRowDtoX on IssueRowDto {
  /// @nodoc
  IssueRow get row => IssueRow(
    key: key,
    title: title,
    status: status.ref,
    priority: priority.toInt(),
    storyPoints: storyPoints?.toInt(),
    assignee: assignee == null
        ? null
        : IssueRowUser(
            id: assignee!.id,
            displayName: assignee!.displayName,
            avatarUrl: assignee!.avatarUrl,
          ),
  );
}

/// Моя активная задача — строка сайдбара (US-81).
///
/// Полей меньше, чем у [IssueRow], и это не урезанная копия: в сайдбаре
/// на 240 px помещаются только приоритет, ключ и тема.
@immutable
class MyIssue {
  /// @nodoc
  const MyIssue({
    required this.key,
    required this.title,
    required this.status,
    required this.priority,
  });

  /// @nodoc
  final String key;

  /// @nodoc
  final String title;

  /// @nodoc
  final IssueStatusRef status;

  /// @nodoc
  final int priority;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyIssue &&
          other.key == key &&
          other.title == title &&
          other.status == status &&
          other.priority == priority;

  @override
  int get hashCode => Object.hash(key, title, status, priority);
}

/// @nodoc
extension MyIssueDtoX on MyIssueDto {
  /// @nodoc
  MyIssue get issue => MyIssue(
    key: key,
    title: title,
    status: status.ref,
    priority: priority.toInt(),
  );
}
