import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_description.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown_syntax.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Блок внешних ссылок (US-47).
///
/// Скрывается целиком, когда ссылок нет (US-48): контрол «Добавить ссылку»
/// в этом случае живёт в строке действий под описанием.
class IssueLinks extends StatefulWidget {
  /// @nodoc
  const IssueLinks({
    required this.links,
    required this.canEdit,
    required this.onAdd,
    required this.onRemove,
    required this.onOpen,
    super.key,
  });

  /// @nodoc
  final List<IssueLinkDto> links;

  /// @nodoc
  final bool canEdit;

  /// @nodoc
  final VoidCallback onAdd;

  /// @nodoc
  final ValueChanged<String> onRemove;

  /// @nodoc
  final ValueChanged<String> onOpen;

  /// Высота строки ссылки.
  static const rowHeight = 32.0;

  /// Сколько ссылок видно, пока не нажали «Показать все».
  static const collapsedCount = 5;

  /// С какого числа ссылок список сворачивается.
  static const collapseFrom = 10;

  @override
  State<IssueLinks> createState() => _IssueLinksState();
}

class _IssueLinksState extends State<IssueLinks> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.links.isEmpty) return const SizedBox.shrink();

    final collapsed =
        !_expanded && widget.links.length >= IssueLinks.collapseFrom;
    final visible = collapsed
        ? widget.links.take(IssueLinks.collapsedCount).toList()
        : widget.links;

    return Padding(
      padding: const EdgeInsets.only(top: SLSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IssueSectionHeader(
            title: 'ССЫЛКИ',
            count: widget.links.length,
            actionLabel: widget.canEdit ? 'Добавить' : null,
            onAction: widget.canEdit ? widget.onAdd : null,
          ),
          const SizedBox(height: SLSpacing.space1),
          for (final link in visible)
            _LinkRow(
              link: link,
              onOpen: () => widget.onOpen(link.url),
              onRemove: widget.canEdit ? () => widget.onRemove(link.id) : null,
            ),
          if (collapsed)
            SLButton(
              label: 'Показать все (${widget.links.length})',
              variant: SLButtonVariant.ghost,
              size: SLButtonSize.sm,
              onPressed: () => setState(() => _expanded = true),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatefulWidget {
  const _LinkRow({
    required this.link,
    required this.onOpen,
    required this.onRemove,
  });

  final IssueLinkDto link;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final title = widget.link.title;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: IssueLinks.rowHeight,
        child: Row(
          children: [
            Icon(
              Icons.open_in_new_rounded,
              size: SLIconSizes.icon16,
              color: colors.iconMuted,
            ),
            const SizedBox(width: SLSpacing.space2),
            Expanded(
              child: InkWell(
                onTap: widget.onOpen,
                child: title == null || title.isEmpty
                    // Подписи нет — показываем сам адрес, обрезанный
                    // посередине: конец адреса обычно содержательнее начала.
                    ? SLMiddleEllipsisText(
                        value: widget.link.url,
                        style: text.bodyS.copyWith(color: colors.accent),
                      )
                    : Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyS.copyWith(color: colors.accent),
                      ),
              ),
            ),
            if (widget.onRemove != null)
              Opacity(
                opacity: _hovered ? 1 : 0,
                child: SLIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Удалить ссылку',
                  size: SLButtonSize.sm,
                  onPressed: widget.onRemove,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Результат диалога добавления ссылки.
@immutable
class NewIssueLink {
  /// @nodoc
  const NewIssueLink({required this.url, this.title});

  /// @nodoc
  final String url;

  /// @nodoc
  final String? title;
}

/// Диалог «Добавить ссылку».
///
/// Схема проверяется на клиенте до отправки: контракт принимает только
/// `http` и `https`, и отправлять заведомо негодный адрес ради 400 незачем.
class AddLinkDialog extends StatefulWidget {
  /// @nodoc
  const AddLinkDialog({super.key});

  /// Показывает диалог.
  static Future<NewIssueLink?> show(BuildContext context) =>
      showDialog<NewIssueLink>(
        context: context,
        builder: (context) => const AddLinkDialog(),
      );

  /// Предел длины подписи из контракта.
  static const titleMaxLength = 100;

  /// Предел длины адреса из контракта.
  static const urlMaxLength = 2048;

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _url = TextEditingController();
  final _title = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    final scheme = uri?.scheme.toLowerCase();

    if (uri == null || (scheme != 'http' && scheme != 'https')) {
      setState(
        () => _error = 'Адрес должен начинаться с http:// или https://',
      );

      return;
    }

    Navigator.of(context).pop(
      NewIssueLink(
        url: url,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Добавить ссылку',
        style: text.title.copyWith(color: colors.textPrimary),
      ),
      content: SizedBox(
        width: SLSizes.dialogSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SLTextField(
              controller: _url,
              label: 'Адрес',
              hint: 'https://example.com/spec',
              maxLength: AddLinkDialog.urlMaxLength,
              errorText: _error,
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SLSpacing.space3),
            SLTextField(
              controller: _title,
              label: 'Подпись',
              hint: 'Необязательно',
              maxLength: AddLinkDialog.titleMaxLength,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        SLButton(
          label: 'Отмена',
          variant: SLButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SLButton(label: 'Добавить', onPressed: _submit),
      ],
    );
  }
}

/// Модалка подтверждения с перечислением последствий.
///
/// Используется для удаления задачи и комментария: оба действия необратимы,
/// и «вы уверены?» без объяснения последствий тут недостаточно.
class ConfirmDialog extends StatelessWidget {
  /// @nodoc
  const ConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    super.key,
  });

  /// @nodoc
  final String title;

  /// @nodoc
  final String description;

  /// @nodoc
  final String confirmLabel;

  /// Показывает модалку. `true` — подтвердили.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          title: title,
          description: description,
          confirmLabel: confirmLabel,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        title,
        style: text.title.copyWith(color: colors.textPrimary),
      ),
      content: SizedBox(
        width: SLSizes.dialogSm,
        child: Text(
          description,
          style: text.body.copyWith(color: colors.textSecondary),
        ),
      ),
      actions: [
        SLButton(
          label: 'Отмена',
          variant: SLButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SLButton(
          label: confirmLabel,
          variant: SLButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Открывать ли этот адрес: та же проверка схемы, что и в Markdown.
bool isOpenableLink(String url) => SLMarkdownSyntax.isSafeLink(url);
