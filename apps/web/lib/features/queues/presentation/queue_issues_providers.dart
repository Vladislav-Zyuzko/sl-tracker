import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_row.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_status_ref.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';

/// Запрос списка задач: ключ очереди, фильтр по статусам и порядок.
///
/// Это ключ семейства провайдеров, поэтому он обязан быть сравнимым
/// по значению: иначе на каждой перестройке экрана создавался бы новый
/// провайдер и список перезапрашивался бы без причины.
///
/// Ключи статусов хранятся отсортированными: `?status=review,in_progress`
/// и `?status=in_progress,review` — это один и тот же список задач, и второй
/// запрос за ним не нужен.
@immutable
class QueueIssuesQuery {
  /// @nodoc
  QueueIssuesQuery({
    required this.queueKey,
    Iterable<String> statusKeys = const [],
    this.sort = IssueSort.priority,
  }) : statusKeys = List.unmodifiable(statusKeys.toSet().toList()..sort());

  /// Ключ очереди.
  final String queueKey;

  /// Ключи статусов фильтра — **ключи, не идентификаторы**: они читаемы
  /// в адресе, и именно их ждёт сервер. Пусто — фильтра нет.
  final List<String> statusKeys;

  /// Порядок.
  final IssueSort sort;

  /// Применён ли фильтр по статусу. От этого зависит текст пустого состояния:
  /// «в очереди нет задач» и «ничего не найдено» — разные сообщения.
  bool get isFiltered => statusKeys.isNotEmpty;

  /// Тот же запрос без фильтра: «Сбросить фильтры».
  QueueIssuesQuery get withoutFilters => QueueIssuesQuery(queueKey: queueKey);

  /// Разбирает `?status=in_progress,review` из адреса страницы.
  ///
  /// Пустые значения отбрасываются: `?status=` и `?status=,` — это отсутствие
  /// фильтра, а не фильтр по пустому ключу.
  static List<String> parseStatuses(String? value) => [
    if (value != null)
      for (final key in value.split(','))
        if (key.trim().isNotEmpty) key.trim(),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueIssuesQuery &&
          other.queueKey == queueKey &&
          other.sort == sort &&
          listEquals(other.statusKeys, statusKeys);

  @override
  int get hashCode => Object.hash(queueKey, sort, Object.hashAll(statusKeys));

  @override
  String toString() =>
      'QueueIssuesQuery($queueKey, ${statusKeys.join(',')}, ${sort.code})';
}

/// Загруженная часть списка задач очереди.
@immutable
class QueueIssuesPage {
  /// @nodoc
  const QueueIssuesPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    required this.role,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  /// Загруженные строки в порядке, который задал сервер.
  final List<IssueRow> items;

  /// Курсор следующей порции. `null` — задачи кончились.
  final String? nextCursor;

  /// Сколько задач подходит под текущий фильтр: счётчик «Показано N».
  final int total;

  /// Роль запросившего. Читателю не показываются ни «Создать задачу»,
  /// ни меню смены статуса (US-32, US-40).
  final SLRole role;

  /// Идёт ли дозагрузка: внизу списка строка-скелетон.
  final bool isLoadingMore;

  /// Сорвалась ли дозагрузка. Уже загруженные строки при этом остаются
  /// на месте — это ключевое требование спеки.
  final bool loadMoreFailed;

  /// @nodoc
  bool get hasMore => nextCursor != null;

  /// Может ли пользователь менять задачи: создавать и переключать статус.
  bool get canEdit => role != SLRole.reader;

  /// @nodoc
  QueueIssuesPage copyWith({
    List<IssueRow>? items,
    String? nextCursor,
    int? total,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => QueueIssuesPage(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    total: total ?? this.total,
    role: role,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// Список задач очереди (US-32).
///
/// Сам не обновляется: строки, самопроизвольно меняющие порядок под курсором,
/// — источник ошибочных кликов (`screens/queue-issues.md`, «Свежесть данных»).
/// Список перезапрашивается при открытии экрана и при смене фильтра.
final queueIssuesProvider =
    AsyncNotifierProvider.family<
      QueueIssuesController,
      QueueIssuesPage,
      QueueIssuesQuery
    >(QueueIssuesController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер списка задач очереди.
class QueueIssuesController extends AsyncNotifier<QueueIssuesPage> {
  /// @nodoc
  QueueIssuesController(this.query);

  /// Ключ очереди, фильтр и порядок.
  final QueueIssuesQuery query;

  /// За сколько строк до конца списка уходит запрос следующей порции.
  static const loadMoreThresholdRows = 10;

  @override
  Future<QueueIssuesPage> build() async {
    final page = await ref
        .read(issuesRepositoryProvider)
        .queueIssues(
          query.queueKey,
          statusKeys: query.statusKeys,
          sort: query.sort,
        );

    return QueueIssuesPage(
      items: [for (final item in page.items) item.row],
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
      // Роли в ответе может не быть. Без явного разрешения считаем
      // пользователя читателем: скорее не покажем кнопку, чем покажем лишнюю.
      role: page.role?.role ?? SLRole.reader,
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую порцию.
  ///
  /// Ошибка не выбрасывается наружу и не роняет список: она превращается
  /// в строку «Не удалось загрузить ещё» в конце. Уже загруженные строки
  /// остаются на месте.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreFailed) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );

    try {
      final page = await ref
          .read(issuesRepositoryProvider)
          .queueIssues(
            query.queueKey,
            cursor: current.nextCursor,
            statusKeys: query.statusKeys,
            sort: query.sort,
          );

      if (!ref.mounted) return;

      final latest = state.value ?? current;
      state = AsyncData(
        QueueIssuesPage(
          items: [...latest.items, for (final item in page.items) item.row],
          nextCursor: page.nextCursor,
          total: page.total.toInt(),
          role: latest.role,
        ),
      );
    } on Object {
      if (!ref.mounted) return;

      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }

  /// Повторяет сорвавшуюся дозагрузку.
  Future<void> retryLoadMore() async {
    final current = state.value;
    if (current == null || !current.loadMoreFailed) return;

    state = AsyncData(current.copyWith(loadMoreFailed: false));

    await loadMore();
  }

  /// Меняет статус задачи прямо из списка — оптимистично.
  ///
  /// Строка принимает новый статус мгновенно; при ошибке возвращается ровно
  /// прежнее значение, а не перезагружается весь список: перезагрузка стёрла
  /// бы прокрутку и чужие изменения заодно.
  ///
  /// Задача, переставшая подходить под фильтр, из списка **не исчезает**:
  /// выдёргивать из-под курсора строку, которую человек только что изменил,
  /// нельзя. Она уйдёт при следующем открытии экрана.
  Future<void> changeStatus(String issueKey, IssueStatusRef status) async {
    final statusId = status.id;
    if (statusId == null) return;

    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.key == issueKey);
    if (index < 0) return;

    final previous = current.items[index];
    if (previous.status.id == statusId) return;

    state = AsyncData(
      current.copyWith(
        items: _replace(
          current.items,
          index,
          previous.copyWith(status: status),
        ),
      ),
    );

    try {
      final updated = await ref
          .read(issuesRepositoryProvider)
          .changeStatus(issueKey, statusId);

      if (!ref.mounted) return;

      _write(issueKey, (row) => row.copyWith(status: updated.status.ref));
      // Задача могла уйти из активных (или вернуться в них) — список
      // в сайдбаре об этом иначе не узнает.
      ref.read(myActiveIssuesRevisionProvider.notifier).bump();
    } on Object {
      if (ref.mounted) _write(issueKey, (_) => previous);

      rethrow;
    }
  }

  /// Заменяет строку по ключу, если она ещё в списке.
  void _write(String issueKey, IssueRow Function(IssueRow) transform) {
    final page = state.value;
    if (page == null) return;

    final at = page.items.indexWhere((item) => item.key == issueKey);
    if (at < 0) return;

    state = AsyncData(
      page.copyWith(items: _replace(page.items, at, transform(page.items[at]))),
    );
  }

  static List<IssueRow> _replace(List<IssueRow> items, int index, IssueRow v) =>
      [...items]..[index] = v;
}
