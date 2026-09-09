import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/features/issues/presentation/issue_history_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/history_group_row.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_skeletons.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Лента истории как sliver (US-90).
///
/// Порядок обратный ленте комментариев — сначала новые, — и это ровно та
/// причина, по которой история живёт вкладкой, а не блоком под обсуждением:
/// две соседние ленты с противоположной сортировкой в одном скролле читаются
/// как ошибка (`screens/issue.md`, «Решение: где живёт история»).
///
/// Виртуализируется тем же `SliverList.builder`: у задачи, которую год
/// перекидывали между людьми, записей бывает много.
class HistorySliver extends ConsumerWidget {
  /// @nodoc
  const HistorySliver({required this.issueKey, super.key});

  /// @nodoc
  final String issueKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(issueHistoryProvider(issueKey));

    return switch (history) {
      AsyncLoading() => const SliverToBoxAdapter(child: HistorySkeleton()),
      AsyncError(:final error) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SLSpacing.space6),
          child: SLErrorState(
            title: 'Не удалось загрузить историю',
            description: 'Задача открыта, а журнал изменений не доехал.',
            onAction: () =>
                ref.read(issueHistoryProvider(issueKey).notifier).refresh(),
            details: error.toString(),
          ),
        ),
      ),
      AsyncData(:final value) => _buildList(ref, value),
    };
  }

  Widget _buildList(WidgetRef ref, HistoryPage page) {
    final notifier = ref.read(issueHistoryProvider(issueKey).notifier);

    // «Пусто» здесь невозможно: запись «Задача создана» есть всегда (US-90).
    // Но падать на пустом ответе всё равно нельзя.
    return SliverList.builder(
      itemCount: page.items.length + (page.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= page.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: SLSpacing.space3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: page.loadMoreFailed
                  ? SLButton(
                      label: 'Не удалось загрузить. Повторить',
                      variant: SLButtonVariant.secondary,
                      size: SLButtonSize.sm,
                      onPressed: notifier.retryLoadMore,
                    )
                  : SLButton(
                      label: 'Показать более ранние',
                      variant: SLButtonVariant.ghost,
                      size: SLButtonSize.sm,
                      isLoading: page.isLoadingMore,
                      onPressed: notifier.loadMore,
                    ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: SLSpacing.space2),
          child: HistoryGroupRow(group: page.items[index]),
        );
      },
    );
  }
}
