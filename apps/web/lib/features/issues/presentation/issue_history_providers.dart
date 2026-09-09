import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';

/// Загруженная часть истории изменений.
@immutable
class HistoryPage {
  /// @nodoc
  const HistoryPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  /// Группы изменений, сначала новые (US-90). Клиент ничего не группирует:
  /// сервер уже отдал готовые группы.
  final List<IssueHistoryGroupDto> items;

  /// Курсор более старых записей.
  final String? nextCursor;

  /// Всего действий по задаче. Минимум одно есть всегда — «Задача создана».
  final int total;

  /// @nodoc
  final bool isLoadingMore;

  /// @nodoc
  final bool loadMoreFailed;

  /// @nodoc
  bool get hasMore => nextCursor != null;

  /// Есть ли изменения за последний час.
  ///
  /// От этого зависит точка `accent` у вкладки «История»: счётчик записей
  /// ничего не значит, а «недавно что-то поменяли» — значит
  /// (`screens/issue.md`, «Решение: где живёт история»).
  bool hasRecentChanges({DateTime? now}) {
    if (items.isEmpty) return false;

    final moment = (now ?? DateTime.now()).toUtc();

    return items.first.createdAt.toUtc().isAfter(
      moment.subtract(const Duration(hours: 1)),
    );
  }

  /// @nodoc
  HistoryPage copyWith({
    List<IssueHistoryGroupDto>? items,
    String? nextCursor,
    bool clearCursor = false,
    int? total,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => HistoryPage(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// История изменений задачи (US-90 … US-92).
///
/// Отдельный провайдер, а не часть задачи: история грузится только когда
/// на неё переключились, и лишний запрос на каждом открытии задачи не нужен.
final issueHistoryProvider =
    AsyncNotifierProvider.family<HistoryController, HistoryPage, String>(
      HistoryController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер истории.
class HistoryController extends AsyncNotifier<HistoryPage> {
  /// @nodoc
  HistoryController(this.issueKey);

  /// @nodoc
  final String issueKey;

  /// За сколько записей до конца уходит запрос следующей порции.
  static const loadMoreThreshold = 5;

  @override
  Future<HistoryPage> build() async {
    // История нужна и вкладке «Комментарии» — ради точки «есть свежие
    // изменения», — поэтому провайдер живёт, пока открыт экран, а не пока
    // выбрана вкладка.
    final link = ref.keepAlive();
    ref.onDispose(link.close);

    final page = await ref.read(issuesRepositoryProvider).history(issueKey);

    return HistoryPage(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает более старые записи.
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
          .history(issueKey, cursor: current.nextCursor);

      if (!ref.mounted) return;

      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...page.items],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          total: page.total.toInt(),
          isLoadingMore: false,
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
}
