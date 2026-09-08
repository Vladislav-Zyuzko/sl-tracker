import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_row.dart';

/// Запрос поиска по моим активным задачам.
///
/// Отдельный провайдер, а не поле состояния списка: поле поиска живёт
/// в оболочке и переживает переходы между экранами, а список — производная
/// от запроса.
final activeIssuesSearchProvider =
    NotifierProvider<ActiveIssuesSearchController, String>(
      ActiveIssuesSearchController.new,
    );

/// Контроллер строки поиска сайдбара.
class ActiveIssuesSearchController extends Notifier<String> {
  @override
  String build() => '';

  /// Дебаунс делает само поле ввода (250 мс, US-82); сюда запрос приходит
  /// уже готовым к отправке на сервер.
  void search(String query) => state = query.trim();

  /// @nodoc
  void clear() => state = '';
}

/// Загруженная часть списка моих активных задач.
@immutable
class ActiveIssuesPage {
  /// @nodoc
  const ActiveIssuesPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    required this.query,
    this.isLoadingMore = false,
  });

  /// Приоритет по убыванию, при равенстве — сначала недавно изменённые.
  final List<MyIssue> items;

  /// @nodoc
  final String? nextCursor;

  /// Всего активных задач — **без учёта поиска**: это счётчик у заголовка
  /// списка, и он не должен прыгать, пока человек печатает.
  final int total;

  /// Запрос, которым получен этот список. Нужен, чтобы отличить «задач нет»
  /// от «поиск ничего не нашёл»: тексты у них разные и оба обязательны.
  final String query;

  /// @nodoc
  final bool isLoadingMore;

  /// @nodoc
  bool get hasMore => nextCursor != null;

  /// @nodoc
  ActiveIssuesPage copyWith({
    List<MyIssue>? items,
    String? nextCursor,
    bool? isLoadingMore,
  }) => ActiveIssuesPage(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    total: total,
    query: query,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Мои активные задачи в сайдбаре (US-81).
///
/// Поиск выполняет **сервер** (D-20): провайдер пересобирается на каждое
/// изменение запроса и уходит за новой страницей. Фильтровать уже загруженные
/// 50 строк на клиенте нельзя — за их пределами останется ровно то, что
/// человек ищет, и поиск будет выглядеть сломанным.
final activeIssuesProvider =
    AsyncNotifierProvider<ActiveIssuesController, ActiveIssuesPage>(
      ActiveIssuesController.new,
      retry: (_, _) => null,
    );

/// Контроллер списка активных задач.
class ActiveIssuesController extends AsyncNotifier<ActiveIssuesPage> {
  @override
  Future<ActiveIssuesPage> build() async {
    final query = ref.watch(activeIssuesSearchProvider);
    final page = await ref
        .read(issuesRepositoryProvider)
        .myActive(query: query);

    return ActiveIssuesPage(
      items: [for (final item in page.items) item.issue],
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
      query: query,
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую порцию.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref
          .read(issuesRepositoryProvider)
          .myActive(cursor: current.nextCursor, query: current.query);

      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, for (final item in page.items) item.issue],
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Object {
      // Сбой дозагрузки в сайдбаре не должен обрушивать оболочку: уже
      // загруженные строки остаются, следующая попытка уйдёт при следующей
      // прокрутке.
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }
}
