import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comment_item.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_skeletons.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Лента комментариев как sliver.
///
/// Именно sliver, а не отдельный прокручиваемый блок: у экрана задачи одна
/// ось прокрутки — иначе внутри страницы появляется вторая полоса, и колесо
/// мыши перестаёт делать очевидное. При этом лента остаётся
/// **виртуализированной**: `SliverList.builder` строит только видимые
/// комментарии, и сотня их не превращается в сотню виджетов.
///
/// Фиксированной высоты у комментария нет — в нём Markdown, — поэтому
/// `itemExtent` не задаётся (`screens/issue.md`, «Реализация во Flutter»).
class CommentsSliver extends ConsumerWidget {
  /// @nodoc
  const CommentsSliver({
    required this.issueKey,
    required this.onOpenLink,
    required this.onOpenImage,
    required this.onEdit,
    required this.onDelete,
    required this.itemKeys,
    this.highlightedCommentId,
    super.key,
  });

  /// @nodoc
  final String issueKey;

  /// @nodoc
  final ValueChanged<String> onOpenLink;

  /// @nodoc
  final ValueChanged<String> onOpenImage;

  /// @nodoc
  final ValueChanged<CommentDto> onEdit;

  /// @nodoc
  final ValueChanged<CommentDto> onDelete;

  /// Ключи строк: по ним экран прокручивается к якорю `?comment=<id>`.
  final Map<String, GlobalKey> itemKeys;

  /// Комментарий из якоря — подсвечивается на 1200 мс (US-102).
  final String? highlightedCommentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(issueCommentsProvider(issueKey));

    return switch (comments) {
      AsyncLoading() => const SliverToBoxAdapter(child: CommentsSkeleton()),
      AsyncError(:final error) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SLSpacing.space6),
          // Частичная ошибка: остальная задача при этом работает
          // (`components.md`, 17.3).
          child: SLErrorState(
            title: 'Не удалось загрузить комментарии',
            description: 'Задача открыта, а обсуждение не доехало.',
            onAction: () =>
                ref.read(issueCommentsProvider(issueKey).notifier).refresh(),
            details: error.toString(),
          ),
        ),
      ),
      AsyncData(:final value) => _buildList(context, ref, value),
    };
  }

  Widget _buildList(BuildContext context, WidgetRef ref, CommentsPage page) {
    if (page.items.isEmpty && page.pending.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyComments());
    }

    final total = page.items.length + page.pending.length;

    return SliverList.builder(
      itemCount: total,
      itemBuilder: (context, index) {
        if (index < page.items.length) {
          final comment = page.items[index];

          return Padding(
            key: itemKeys.putIfAbsent(comment.id, GlobalKey.new),
            padding: const EdgeInsets.only(bottom: SLSpacing.space6),
            child: CommentItem(
              comment: comment,
              highlighted: comment.id == highlightedCommentId,
              onOpenLink: onOpenLink,
              onOpenImage: onOpenImage,
              onEdit: comment.permissions.canEdit
                  ? () => onEdit(comment)
                  : null,
              onDelete: comment.permissions.canDelete
                  ? () => onDelete(comment)
                  : null,
            ),
          );
        }

        final pending = page.pending[index - page.items.length];
        final notifier = ref.read(issueCommentsProvider(issueKey).notifier);

        return Padding(
          padding: const EdgeInsets.only(bottom: SLSpacing.space6),
          child: PendingCommentItem(
            pending: pending,
            onRetry: () => notifier.retrySend(pending.localId),
            onDiscard: () => notifier.discardPending(pending.localId),
          ),
        );
      },
    );
  }
}

/// Кнопка «Показать более ранние» над лентой (US-70).
class EarlierCommentsButton extends ConsumerWidget {
  /// @nodoc
  const EarlierCommentsButton({required this.issueKey, super.key});

  /// @nodoc
  final String issueKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(issueCommentsProvider(issueKey)).value;
    if (page == null || !page.hasEarlier) return const SizedBox.shrink();

    final notifier = ref.read(issueCommentsProvider(issueKey).notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: page.loadEarlierFailed
            ? SLButton(
                label: 'Не удалось загрузить. Повторить',
                variant: SLButtonVariant.secondary,
                size: SLButtonSize.sm,
                onPressed: notifier.retryLoadEarlier,
              )
            : SLButton(
                label: 'Показать более ранние',
                variant: SLButtonVariant.ghost,
                size: SLButtonSize.sm,
                isLoading: page.isLoadingEarlier,
                onPressed: notifier.loadEarlier,
              ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комментариев пока нет',
            style: text.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: SLSpacing.space1),
          Text(
            'Начните обсуждение — участники задачи получат уведомление.',
            style: text.bodyS.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
