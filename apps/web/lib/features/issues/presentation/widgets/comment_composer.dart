import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/markdown_editor.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Поле комментария (`docs/design/components.md`, 19).
///
/// Свёрнутое — одна строка 40 px; по клику или по фокусу разворачивается
/// в редактор с вкладками, панелью форматирования и подвалом.
///
/// Текст **не теряется никогда**: ни при сворачивании, ни при неудачной
/// отправке — контроллер живёт у родителя, и виджет его не чистит сам.
class CommentComposer extends StatefulWidget {
  /// @nodoc
  const CommentComposer({
    required this.controller,
    required this.issueKey,
    required this.onSubmit,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl,
    this.submitLabel = 'Отправить',
    this.isSubmitting = false,
    this.onCancel,
    this.startExpanded = false,
    this.focusNode,
    super.key,
  });

  /// @nodoc
  final TextEditingController controller;

  /// @nodoc
  final String issueKey;

  /// Отправка. `null` — кнопка неактивна.
  final VoidCallback? onSubmit;

  /// @nodoc
  final String currentUserId;

  /// @nodoc
  final String currentUserName;

  /// @nodoc
  final String? currentUserAvatarUrl;

  /// @nodoc
  final String submitLabel;

  /// @nodoc
  final bool isSubmitting;

  /// «Отмена». `null` — кнопки нет (у поля новой записи её и не должно быть,
  /// пока текст пуст).
  final VoidCallback? onCancel;

  /// Открыть сразу развёрнутым: так работает правка существующего
  /// комментария.
  final bool startExpanded;

  /// @nodoc
  final FocusNode? focusNode;

  /// Высота свёрнутого поля.
  static const collapsedHeight = 40.0;

  /// Сколько символов черновика видно в свёрнутом виде.
  static const draftPreviewLength = 40;

  @override
  State<CommentComposer> createState() => CommentComposerState();
}

/// Состояние поля комментария.
///
/// Публичное ради одного метода — [focus]. Хоткей `m` обязан разворачивать
/// свёрнутое поле и ставить в него курсор, а пока поле свёрнуто, узла ввода
/// не существует и просить у него фокус бессмысленно.
class CommentComposerState extends State<CommentComposer> {
  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'comment-composer');
  final _collapsedFocus = FocusNode(debugLabel: 'comment-composer-collapsed');
  late var _expanded = widget.startExpanded;

  @override
  void dispose() {
    _collapsedFocus.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Разворачивает поле и ставит в него курсор.
  void focus() => _expand();

  void _expand() {
    if (!_expanded) setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _collapse() {
    setState(() => _expanded = false);
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      // Свёрнутое поле само по себе достижимо с клавиатуры и по фокусу
      // разворачивается: иначе `Tab` доводил бы до пустой рамки, в которой
      // нельзя писать (`components.md`, 19).
      return Focus(
        focusNode: _collapsedFocus,
        onFocusChange: (hasFocus) {
          if (hasFocus) _expand();
        },
        child: _Collapsed(
          controller: widget.controller,
          userId: widget.currentUserId,
          userName: widget.currentUserName,
          avatarUrl: widget.currentUserAvatarUrl,
          onTap: _expand,
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final isEmpty = value.text.trim().isEmpty;

        return SLMarkdownEditor(
          controller: widget.controller,
          focusNode: _focusNode,
          issueKey: widget.issueKey,
          hint: 'Написать комментарий…',
          hintText: 'Ctrl+Enter — отправить',
          minLines: 4,
          maxLines: 12,
          autofocus: widget.startExpanded,
          enabled: !widget.isSubmitting,
          onSubmit: isEmpty ? null : widget.onSubmit,
          actions: [
            SLButton(
              label: 'Отмена',
              variant: SLButtonVariant.secondary,
              size: SLButtonSize.sm,
              onPressed: widget.isSubmitting ? null : _collapse,
            ),
            SLButton(
              label: widget.submitLabel,
              size: SLButtonSize.sm,
              isLoading: widget.isSubmitting,
              onPressed: isEmpty ? null : widget.onSubmit,
            ),
          ],
        );
      },
    );
  }
}

/// Свёрнутое состояние: аватар и плейсхолдер либо начало черновика.
class _Collapsed extends StatelessWidget {
  const _Collapsed({
    required this.controller,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.onTap,
  });

  final TextEditingController controller;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final draft = MentionToken.toPlainText(value.text).trim();
        final label = draft.isEmpty
            ? 'Написать комментарий…'
            : 'Черновик: '
                  '${draft.length > CommentComposer.draftPreviewLength ? '${draft.substring(0, CommentComposer.draftPreviewLength)}…' : draft}';

        return Semantics(
          textField: true,
          label: 'Написать комментарий. Ctrl+Enter — отправить',
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: CommentComposer.collapsedHeight,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: SLRadii.smAll,
                  border: Border.all(
                    color: colors.borderStrong,
                    width: SLBorders.hairline,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space3,
                ),
                child: Row(
                  children: [
                    SLAvatar(
                      userId: userId,
                      fullName: userName,
                      photoUrl: avatarUrl,
                      size: SLAvatarSize.sm,
                      decorative: true,
                    ),
                    const SizedBox(width: SLSpacing.space2),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.body.copyWith(color: colors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Строка вместо поля для того, кому нельзя комментировать (US-71).
class CommentComposerDenied extends StatelessWidget {
  /// @nodoc
  const CommentComposerDenied({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Text(
      'У вас нет прав комментировать эту задачу',
      style: text.label.copyWith(color: colors.textMuted),
    );
  }
}
