import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Относительное время первые сутки, дальше абсолютное
/// (`docs/design/components.md`, 20).
String commentTimeLabel(DateTime moment, {DateTime? now}) {
  final local = moment.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final elapsed = current.difference(local);

  if (elapsed.inSeconds < 60) return 'только что';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} мин назад';
  if (elapsed.inHours < 24) return '${elapsed.inHours} ч назад';

  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';

  return '${SLDateFormat.short(local, now: current)} в $time';
}

/// Один комментарий ленты (`components.md`, 20).
///
/// Свой комментарий ничем не подсвечен: различать «мои» и «чужие» фоном —
/// привычка мессенджеров, в треде она мешает читать.
class CommentItem extends StatefulWidget {
  /// @nodoc
  const CommentItem({
    required this.comment,
    required this.onOpenLink,
    required this.onOpenImage,
    this.onEdit,
    this.onDelete,
    this.highlighted = false,
    super.key,
  });

  /// @nodoc
  final CommentDto comment;

  /// @nodoc
  final ValueChanged<String> onOpenLink;

  /// @nodoc
  final ValueChanged<String> onOpenImage;

  /// Правка. `null` — прав нет: править может **только автор**, даже
  /// администратор чужой комментарий не трогает (US-72).
  final VoidCallback? onEdit;

  /// Удаление. `null` — прав нет (US-73).
  final VoidCallback? onDelete;

  /// Пришли по якорю `?comment=<id>`: подсветка `accentSurface` на 1200 мс.
  final bool highlighted;

  /// Сколько держится подсветка перехода по уведомлению (US-102).
  static const highlightDuration = Duration(milliseconds: 1200);

  /// Высота, на которой очень длинный комментарий сворачивается.
  static const collapsedHeight = 400.0;

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final comment = widget.comment;

    return Semantics(
      container: true,
      label:
          '${comment.author.displayName}, '
          '${SLDateFormat.exact(comment.createdAt)}, комментарий: '
          '${MentionToken.toPlainText(comment.body, names: {for (final m in comment.mentions) m.id: m.displayName})}',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: SLMotion.durationOf(context, SLMotion.base),
          decoration: BoxDecoration(
            color: widget.highlighted
                ? colors.accentSurface
                : _hovered
                ? colors.surfaceHover
                : null,
            borderRadius: SLRadii.smAll,
          ),
          padding: const EdgeInsets.all(SLSpacing.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                comment: comment,
                showMenu: _hovered && (widget.onEdit != null || widget.onDelete != null),
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
              ),
              const SizedBox(height: SLSpacing.space1),
              SLMarkdown(
                data: comment.body,
                mentions: [
                  for (final mention in comment.mentions)
                    MentionRef(
                      id: mention.id,
                      displayName: mention.displayName,
                      avatarUrl: mention.avatarUrl,
                    ),
                ],
                collapsedHeight: CommentItem.collapsedHeight,
                onOpenLink: widget.onOpenLink,
                onOpenImage: widget.onOpenImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.comment,
    required this.showMenu,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentDto comment;
  final bool showMenu;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final editedAt = comment.editedAt;

    return Row(
      children: [
        SLAvatar(
          userId: comment.author.id,
          fullName: comment.author.displayName,
          photoUrl: comment.author.avatarUrl,
          size: SLAvatarSize.sm,
          decorative: true,
        ),
        const SizedBox(width: SLSpacing.space2),
        Flexible(
          child: Text(
            comment.author.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyStrong.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(width: SLSpacing.space2),
        Tooltip(
          message: SLDateFormat.exact(comment.createdAt),
          child: Text(
            commentTimeLabel(comment.createdAt),
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ),
        if (editedAt != null) ...[
          const SizedBox(width: SLSpacing.space2),
          Tooltip(
            message: 'Изменён ${SLDateFormat.exact(editedAt)}',
            child: Text(
              'изменён',
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ),
        ],
        const Spacer(),
        // Меню доступно с клавиатуры всегда, а не только при наведении:
        // иначе для клавиатуры действий просто нет (`components.md`, 20).
        if (onEdit != null || onDelete != null)
          Opacity(
            opacity: showMenu ? 1 : 0,
            child: _CommentMenu(onEdit: onEdit, onDelete: onDelete),
          ),
      ],
    );
  }
}

class _CommentMenu extends StatelessWidget {
  const _CommentMenu({required this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        if (onEdit != null)
          MenuItemButton(
            onPressed: onEdit,
            child: Text(
              'Редактировать',
              style: text.bodyS.copyWith(color: colors.textPrimary),
            ),
          ),
        if (onDelete != null)
          MenuItemButton(
            onPressed: onDelete,
            child: Text(
              'Удалить',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия с комментарием',
        size: SLButtonSize.sm,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Комментарий, который ещё отправляется или не отправился (US-71).
class PendingCommentItem extends StatelessWidget {
  /// @nodoc
  const PendingCommentItem({
    required this.pending,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  /// @nodoc
  final PendingComment pending;

  /// @nodoc
  final VoidCallback onRetry;

  /// @nodoc
  final VoidCallback onDiscard;

  /// Прозрачность отправляемого комментария.
  static const sendingOpacity = 0.6;

  /// Ширина полосы у неотправленного.
  static const failureStripe = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SLAvatar(
              userId: pending.author.id,
              fullName: pending.author.displayName,
              photoUrl: pending.author.avatarUrl,
              size: SLAvatarSize.sm,
              decorative: true,
            ),
            const SizedBox(width: SLSpacing.space2),
            Text(
              pending.author.displayName,
              style: text.bodyStrong.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(width: SLSpacing.space2),
            Text(
              pending.failed ? 'Не отправлено' : 'отправляется…',
              style: text.label.copyWith(
                color: pending.failed ? colors.danger : colors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: SLSpacing.space1),
        // Текст показывается как есть, без разбора разметки: пока сервер
        // его не принял, упоминания ещё не связаны ни с кем.
        Text(
          MentionToken.toPlainText(pending.body),
          style: text.body.copyWith(color: colors.textPrimary),
        ),
        if (pending.failed) ...[
          const SizedBox(height: SLSpacing.space2),
          Row(
            children: [
              SLButton(
                label: 'Повторить',
                variant: SLButtonVariant.secondary,
                size: SLButtonSize.sm,
                onPressed: onRetry,
              ),
              const SizedBox(width: SLSpacing.space2),
              SLButton(
                label: 'Удалить',
                variant: SLButtonVariant.ghost,
                size: SLButtonSize.sm,
                onPressed: onDiscard,
              ),
            ],
          ),
        ],
      ],
    );

    return Semantics(
      liveRegion: pending.failed,
      label: pending.failed ? 'Комментарий не отправлен' : null,
      child: Container(
        padding: const EdgeInsets.all(SLSpacing.space2),
        decoration: pending.failed
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.danger, width: failureStripe),
                ),
              )
            : null,
        child: pending.failed
            ? content
            : Opacity(opacity: sendingOpacity, child: content),
      ),
    );
  }
}
