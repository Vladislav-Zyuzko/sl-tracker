import 'package:flutter/foundation.dart';

/// Статус задачи — пять значений MVP (`docs/design/system.md`, 4).
///
/// Порядок объявления — это и есть порядок показа в любых списках и меню:
/// открыт → в работе → ревью → тестирование → закрыт. Менять его нельзя.
///
/// Бэкенд отдаёт [code]; палитру и иконку выбирает клиент.
enum IssueStatus {
  /// Открыт.
  open('open', 'Открыт'),

  /// В работе.
  inProgress('in_progress', 'В работе'),

  /// Ревью.
  review('review', 'Ревью'),

  /// Тестирование.
  testing('testing', 'Тестирование'),

  /// Закрыт.
  closed('closed', 'Закрыт');

  /// @nodoc
  const IssueStatus(this.code, this.label);

  /// Код статуса в API.
  final String code;

  /// Название статуса в интерфейсе. Показывается всегда: цвет — четвёртый
  /// канал смысла после текста, иконки и позиции, и один он не работает.
  final String label;

  /// Разбирает код, пришедший от сервера.
  ///
  /// Возвращает `null` для незнакомого кода: клиент не должен падать
  /// на статусе, о котором ещё не знает.
  static IssueStatus? tryParse(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }

    return null;
  }
}

/// Категория статуса (ADR-0003).
///
/// Статусы — данные, а не перечисление: у каждой очереди свой набор, и клиент
/// берёт его с сервера. Категория — единственное, на что можно опираться
/// в логике: «задача не завершена» — это `category != done`, а не «ключ
/// не равен `closed`» и не «позиция меньше пятой».
enum IssueStatusCategory {
  /// Работа не начата.
  open('open'),

  /// Работа идёт: в работе, ревью, тестирование.
  inProgress('in_progress'),

  /// Работа завершена.
  done('done');

  /// @nodoc
  const IssueStatusCategory(this.code);

  /// Код категории в API.
  final String code;

  /// Завершена ли задача в этом статусе.
  bool get isDone => this == IssueStatusCategory.done;
}

/// Статус задачи так, как его отдаёт сервер (ADR-0003).
///
/// Название приходит от сервера и показывается дословно: очередь может
/// переименовать статус, и подставлять вместо этого зашитую в клиент подпись
/// нельзя. Палитру и иконку выбирает клиент — их в контракте нет.
@immutable
class IssueStatusRef {
  /// @nodoc
  const IssueStatusRef({
    required this.key,
    required this.name,
    required this.category,
    this.id,
  });

  /// Идентификатор статуса. Нужен, чтобы положить статус в задачу.
  /// `null` там, где сервер его не отдаёт (список моих активных задач).
  final String? id;

  /// Машинное имя статуса внутри очереди: `open`, `in_progress`, …
  final String key;

  /// Название для интерфейса.
  final String name;

  /// Категория.
  final IssueStatusCategory category;

  /// Завершена ли задача в этом статусе.
  bool get isDone => category.isDone;

  /// Статус дизайн-системы, чья палитра и иконка используются для показа.
  ///
  /// Сначала по ключу — пять статусов MVP совпадают с ключами по умолчанию.
  /// Незнакомый ключ (очередь переименовала статус, бэкенд добавил новый)
  /// не должен оставлять плашку без цвета, поэтому запасной вариант берётся
  /// из категории: это ровно та информация, которой достаточно.
  IssueStatus get palette =>
      IssueStatus.tryParse(key) ??
      switch (category) {
        IssueStatusCategory.open => IssueStatus.open,
        IssueStatusCategory.inProgress => IssueStatus.inProgress,
        IssueStatusCategory.done => IssueStatus.closed,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueStatusRef &&
          other.id == id &&
          other.key == key &&
          other.name == name &&
          other.category == category;

  @override
  int get hashCode => Object.hash(id, key, name, category);

  @override
  String toString() => 'IssueStatusRef($key, ${category.code})';
}
