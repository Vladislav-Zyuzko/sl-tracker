/// Перевод полей задачи из контракта в значения интерфейса.
///
/// В контракте приоритет и сложность описаны перечислениями со списком
/// допустимых чисел, а компоненты дизайн-системы принимают обычный `int`.
/// Переводим в одном месте, чтобы `.json?.toInt()` не расползался по экрану.
library;

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';

/// Приоритет задачи числом.
extension IssueDtoPriorityX on IssueDtoPriority {
  /// Значение 0–100.
  ///
  /// Незнакомое значение с сервера трактуем как середину шкалы: приоритет
  /// пустым не бывает никогда (D-15), и показать «не задан» здесь нельзя.
  int get value => json?.toInt() ?? IssuePriority.initial;
}

/// Сложность задачи числом.
extension IssueDtoStoryPointsX on IssueDtoStoryPoints {
  /// Значение по шкале Фибоначчи; `null` — «не оценено».
  int? get value => json?.toInt();
}

/// Категория статуса задачи.
extension IssueStatusFullDtoCategoryX on IssueStatusFullDtoCategory {
  /// Категория статуса дизайн-системы.
  IssueStatusCategory get category => switch (json) {
    'in_progress' => IssueStatusCategory.inProgress,
    'done' => IssueStatusCategory.done,
    // Незнакомая категория — «работа не начата»: считать неизвестный статус
    // завершённым нельзя, задача пропала бы из активных (ADR-0003).
    _ => IssueStatusCategory.open,
  };
}

/// Обратный перевод: статус интерфейса в категорию контракта.
IssueStatusFullDtoCategory categoryDtoOf(IssueStatusCategory category) =>
    switch (category) {
      IssueStatusCategory.open => IssueStatusFullDtoCategory.open,
      IssueStatusCategory.inProgress => IssueStatusFullDtoCategory.inProgress,
      IssueStatusCategory.done => IssueStatusFullDtoCategory.done,
    };

/// Приоритет из числа.
///
/// Значение вне шкалы отбрасывается в `$unknown`, и такой запрос сервер
/// отвергнет — это лучше, чем молча отправить соседнее число.
IssueDtoPriority priorityDtoOf(int value) => IssueDtoPriority.fromJson(value);

/// Сложность из числа. `null` — «не оценено».
IssueDtoStoryPoints? storyPointsDtoOf(int? value) =>
    value == null ? null : IssueDtoStoryPoints.fromJson(value);

/// Пользователь задачи из строки подсказки участников.
///
/// Подсказка отдаёт `MentionSuggestionDto`, а поля задачи хранят
/// `IssueUserDto`: одни и те же люди, разные схемы контракта.
IssueUserDto issueUserOf(MentionSuggestionDto suggestion) => IssueUserDto(
  id: suggestion.id,
  displayName: suggestion.displayName,
  avatarUrl: suggestion.avatarUrl,
);

/// Имена полей задачи так, как они приходят в `changedFields` события
/// `issue.updated` и называются в ответе `GET /api/issues/{key}`.
///
/// Строками, а не перечислением: сервер вправе прислать поле, о котором
/// клиент ещё не знает, и падать на этом нельзя. Собраны в одном месте,
/// потому что опечатка в такой строке не видна ниоткуда — подсветка просто
/// не загорится.
sealed class IssueFieldNames {
  /// @nodoc
  static const title = 'title';

  /// @nodoc
  static const description = 'description';

  /// @nodoc
  static const status = 'status';

  /// @nodoc
  static const priority = 'priority';

  /// @nodoc
  static const storyPoints = 'storyPoints';

  /// @nodoc
  static const author = 'author';

  /// @nodoc
  static const assignee = 'assignee';

  /// Внешние ссылки.
  static const links = 'links';

  /// Вложения.
  static const attachments = 'attachments';
}
