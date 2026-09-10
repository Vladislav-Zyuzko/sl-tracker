import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Крошки, ключ задачи и меню «⋯».
///
/// Крошки и ключ появляются **сразу**, ещё до ответа сервера: они есть
/// в адресе страницы, и скрывать их скелетоном незачем.
class IssueHeaderBar extends StatelessWidget {
  /// @nodoc
  const IssueHeaderBar({
    required this.issueKey,
    required this.onCopyKey,
    required this.onCopyLink,
    this.issue,
    this.onDelete,
    super.key,
  });

  /// Ключ из адреса — известен до загрузки.
  final String issueKey;

  /// Задача. `null` — ещё грузится.
  final IssueDto? issue;

  /// @nodoc
  final VoidCallback onCopyKey;

  /// @nodoc
  final VoidCallback onCopyLink;

  /// Удаление задачи. `null` — прав нет: пункта в меню тогда не будет
  /// (US-44).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final current = issue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (current != null)
          _Breadcrumbs(
            projectName: current.project.name,
            projectSlug: current.project.slug,
            queueName: current.queue.name,
            queueKey: current.queue.key,
          ),
        const SizedBox(height: SLSpacing.space2),
        Row(
          children: [
            // Ключ читается по буквам-группам: «DEV дефис 42», а не слитно.
            Semantics(
              label: issueKey.replaceAll('-', ' дефис '),
              excludeSemantics: true,
              child: Text(
                issueKey,
                style: text.bodySStrong.copyWith(color: colors.accent),
              ),
            ),
            const SizedBox(width: SLSpacing.space1),
            SLIconButton(
              icon: Icons.content_copy_rounded,
              tooltip: 'Скопировать ключ',
              size: SLButtonSize.sm,
              onPressed: onCopyKey,
            ),
            const Spacer(),
            _MoreMenu(
              onCopyKey: onCopyKey,
              onCopyLink: onCopyLink,
              onDelete: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({
    required this.projectName,
    required this.projectSlug,
    required this.queueName,
    required this.queueKey,
  });

  final String projectName;
  final String projectSlug;
  final String queueName;
  final String queueKey;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    // Сама задача в крошках не повторяется: её ключ и название стоят ниже.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: SLSpacing.space1,
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.projectPath(projectSlug)),
          child: Text(
            projectName,
            style: text.bodyS.copyWith(color: colors.textMuted),
          ),
        ),
        Text('/', style: text.bodyS.copyWith(color: colors.iconMuted)),
        InkWell(
          onTap: () => context.go(AppRoutes.queuePath(queueKey)),
          child: Text(
            queueName,
            style: text.bodyS.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.onCopyKey,
    required this.onCopyLink,
    required this.onDelete,
  });

  final VoidCallback onCopyKey;
  final VoidCallback onCopyLink;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: onCopyLink,
          child: const Text('Скопировать ссылку на задачу'),
        ),
        MenuItemButton(
          onPressed: onCopyKey,
          child: const Text('Скопировать ключ'),
        ),
        if (onDelete != null) ...[
          const Divider(height: SLSpacing.space2),
          MenuItemButton(
            onPressed: onDelete,
            child: Text(
              'Удалить задачу',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          ),
        ],
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия с задачей',
        size: SLButtonSize.sm,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Название задачи, редактируемое на месте (US-42).
///
/// `Enter` — сохранить, `Esc` — отменить, потеря фокуса — сохранить.
/// Пустое название не сохраняется: поле подсвечивается и остаётся открытым
/// с прежним значением рядом.
class IssueTitle extends StatefulWidget {
  /// @nodoc
  const IssueTitle({
    required this.title,
    required this.onChanged,
    this.canEdit = false,
    super.key,
  });

  /// @nodoc
  final String title;

  /// @nodoc
  final ValueChanged<String> onChanged;

  /// @nodoc
  final bool canEdit;

  /// Предел длины из контракта.
  static const maxLength = 255;

  /// С какого символа показывается счётчик остатка.
  static const counterFrom = 200;

  /// Сколько строк показывать до многоточия.
  static const maxLines = 3;

  @override
  State<IssueTitle> createState() => _IssueTitleState();
}

class _IssueTitleState extends State<IssueTitle> {
  final _focusNode = FocusNode(debugLabel: 'issue-title');
  TextEditingController? _controller;
  var _empty = false;

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.canEdit) return;

    setState(() {
      _controller = TextEditingController(text: widget.title)
        ..selection = TextSelection.collapsed(offset: widget.title.length);
      _empty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _cancel() {
    setState(() {
      _controller?.dispose();
      _controller = null;
      _empty = false;
    });
  }

  void _save() {
    final value = _controller?.text.trim() ?? '';
    if (value.isEmpty) {
      setState(() => _empty = true);

      return;
    }

    if (value != widget.title) widget.onChanged(value);
    _cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final style = text.h2.copyWith(color: colors.textPrimary);
    final controller = _controller;

    if (controller == null) {
      final title = Text(
        widget.title,
        maxLines: IssueTitle.maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );

      return Semantics(
        header: true,
        child: widget.canEdit
            ? MouseRegion(
                cursor: SystemMouseCursors.text,
                child: GestureDetector(
                  onTap: _startEditing,
                  child: Tooltip(message: widget.title, child: title),
                ),
              )
            : SelectionArea(child: title),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          // Потеря фокуса сохраняет — кроме случая, когда сохранять нечего.
          onFocusChange: (hasFocus) {
            if (!hasFocus && _controller != null) _save();
          },
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
            },
            child: Actions(
              actions: {
                _CancelIntent: CallbackAction<_CancelIntent>(
                  onInvoke: (_) {
                    _cancel();

                    return null;
                  },
                ),
              },
              child: TextField(
                controller: controller,
                focusNode: _focusNode,
                style: style,
                maxLength: IssueTitle.maxLength,
                maxLines: IssueTitle.maxLines,
                minLines: 1,
                cursorColor: colors.accent,
                onSubmitted: (_) => _save(),
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => currentLength < IssueTitle.counterFrom
                    ? null
                    : Text(
                        '${(maxLength ?? 0) - currentLength}',
                        style: text.label.copyWith(color: colors.textMuted),
                      ),
                // Кольца фокуса нет: рамка сама окрашивается в `borderFocus`,
                // фокус показывает утолщение до 2 px (`system.md`, 10.6.1).
                // Пустое название в фокусе остаётся красным: ошибка важнее
                // того, где сейчас каретка.
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _empty ? colors.borderDanger : colors.borderStrong,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _empty ? colors.borderDanger : colors.borderFocus,
                      width: SLBorders.controlFocus,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_empty)
          Padding(
            padding: const EdgeInsets.only(top: SLSpacing.space1),
            child: Text(
              'Название не может быть пустым',
              style: text.label.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
