import 'package:flutter/material.dart';

import 'package:sl_tracker_web/features/issues/presentation/widgets/markdown_editor.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Заголовок секции: `overline` плюс действие справа.
///
/// Помечается `Semantics(header: true)`, чтобы работала навигация
/// по заголовкам у скринридера.
class IssueSectionHeader extends StatelessWidget {
  /// @nodoc
  const IssueSectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// @nodoc
  final String title;

  /// Счётчик рядом с заголовком.
  final int? count;

  /// @nodoc
  final String? actionLabel;

  /// @nodoc
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Row(
      children: [
        Semantics(
          header: true,
          child: Text(
            count == null ? title : '$title $count',
            style: text.overline.copyWith(color: colors.textMuted),
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          SLButton(
            label: actionLabel!,
            variant: SLButtonVariant.ghost,
            size: SLButtonSize.sm,
            onPressed: onAction,
          ),
      ],
    );
  }
}

/// Описание задачи: просмотр и редактор на одном месте.
///
/// Разметка приходит **несанитизированной** (`IssueDto.description`), поэтому
/// рендерит её [SLMarkdown] — он не исполняет сырой HTML и не делает
/// кликабельными схемы, кроме `http`, `https` и `mailto` (D-22, US-43).
class IssueDescription extends StatelessWidget {
  /// @nodoc
  const IssueDescription({
    required this.issueKey,
    required this.description,
    required this.isEditing,
    required this.controller,
    required this.canEdit,
    required this.onStartEditing,
    required this.onCancel,
    required this.onSave,
    required this.onOpenLink,
    required this.onOpenImage,
    this.isSaving = false,
    super.key,
  });

  /// @nodoc
  final String issueKey;

  /// Текст. `null` или пусто — описание не заполнено.
  final String? description;

  /// @nodoc
  final bool isEditing;

  /// @nodoc
  final TextEditingController controller;

  /// @nodoc
  final bool canEdit;

  /// @nodoc
  final VoidCallback onStartEditing;

  /// @nodoc
  final VoidCallback onCancel;

  /// @nodoc
  final VoidCallback onSave;

  /// @nodoc
  final ValueChanged<String> onOpenLink;

  /// @nodoc
  final ValueChanged<String> onOpenImage;

  /// @nodoc
  final bool isSaving;

  /// Высота, на которой длинное описание сворачивается (`components.md`,
  /// 18.2).
  static const collapsedHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final body = description?.trim() ?? '';

    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IssueSectionHeader(title: 'ОПИСАНИЕ'),
          const SizedBox(height: SLSpacing.space2),
          SLMarkdownEditor(
            controller: controller,
            issueKey: issueKey,
            hint: 'Опишите задачу…',
            hintText: 'Ctrl+Enter — сохранить',
            autofocus: true,
            enabled: !isSaving,
            onSubmit: onSave,
            actions: [
              SLButton(
                label: 'Отмена',
                variant: SLButtonVariant.secondary,
                size: SLButtonSize.sm,
                onPressed: isSaving ? null : onCancel,
              ),
              SLButton(
                label: 'Сохранить',
                size: SLButtonSize.sm,
                isLoading: isSaving,
                onPressed: onSave,
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssueSectionHeader(
          title: 'ОПИСАНИЕ',
          actionLabel: canEdit && body.isNotEmpty ? 'Изменить' : null,
          onAction: canEdit && body.isNotEmpty ? onStartEditing : null,
        ),
        const SizedBox(height: SLSpacing.space2),
        if (body.isEmpty)
          // `Wrap`, а не `Row`: на телефоне подпись и кнопка в строку
          // не помещаются, и текст уезжал бы за край экрана.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: SLSpacing.space2,
            runSpacing: SLSpacing.space1,
            children: [
              Text(
                'Описание не заполнено',
                style: text.body.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (canEdit)
                SLButton(
                  label: 'Добавить описание',
                  variant: SLButtonVariant.ghost,
                  size: SLButtonSize.sm,
                  onPressed: onStartEditing,
                ),
            ],
          )
        else
          // В вебе люди ожидают, что текст можно выделить и скопировать.
          SLMarkdown(
            data: body,
            collapsedHeight: collapsedHeight,
            onOpenLink: onOpenLink,
            onOpenImage: onOpenImage,
          ),
      ],
    );
  }
}
