import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';

/// Перевод статусов из контракта в статус интерфейса.
///
/// В контракте один и тот же статус описан тремя схемами — по одной на список
/// задач, на список моих активных задач и на набор статусов очереди.
/// Приводим их к [IssueStatusRef] в одном месте, чтобы палитра, подписи
/// и логика «завершена ли задача» не расползались по экранам.
///
/// Незнакомая категория с сервера трактуется как [IssueStatusCategory.open]:
/// «работа не начата» — самое безобидное предположение. Считать неизвестный
/// статус завершённым нельзя: тогда задача пропала бы из списка активных
/// и из счётчика незавершённых.
IssueStatusCategory _categoryOf(String code) => switch (code) {
  'open' => IssueStatusCategory.open,
  'in_progress' => IssueStatusCategory.inProgress,
  'done' => IssueStatusCategory.done,
  _ => IssueStatusCategory.open,
};

/// Статус строки списка задач.
extension IssueRowStatusDtoX on IssueRowStatusDto {
  /// @nodoc
  IssueStatusRef get ref => IssueStatusRef(
    id: id,
    key: key,
    name: name,
    category: _categoryOf(category.json ?? ''),
  );
}

/// Статус в списке моих активных задач. Идентификатора там нет: менять статус
/// из сайдбара нельзя, и поле было бы лишним весом на каждой строке.
extension IssueStatusDtoX on IssueStatusDto {
  /// @nodoc
  IssueStatusRef get ref => IssueStatusRef(
    key: key,
    name: name,
    category: _categoryOf(category.json ?? ''),
  );
}

/// Статус из набора очереди: он же пункт фильтра и пункт меню смены статуса.
extension QueueStatusDtoX on QueueStatusDto {
  /// @nodoc
  IssueStatusRef get ref => IssueStatusRef(
    id: id,
    key: key,
    name: name,
    category: _categoryOf(category.json ?? ''),
  );
}

/// Статус задачи целиком (карточка задачи, ответ на создание).
extension IssueStatusFullDtoX on IssueStatusFullDto {
  /// @nodoc
  IssueStatusRef get ref => IssueStatusRef(
    id: id,
    key: key,
    name: name,
    category: _categoryOf(category.json ?? ''),
  );
}
