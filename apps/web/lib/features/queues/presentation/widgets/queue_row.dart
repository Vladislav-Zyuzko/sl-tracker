import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_plural.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка очереди на вкладке «Очереди» (`docs/design/screens/project.md`).
///
/// Описание очереди в строке не показывается: оно нужно внутри очереди,
/// а не в списке. Счётчик — незавершённые задачи, то есть те, чей статус
/// не в категории `done` (US-31).
class QueueRow extends StatefulWidget {
  /// @nodoc
  const QueueRow({
    required this.queue,
    required this.onOpen,
    required this.onOpenInNewTab,
    this.onRename,
    this.onDelete,
    this.compact = false,
    super.key,
  });

  /// Очередь.
  final QueueDto queue;

  /// Открыть список задач очереди.
  final VoidCallback onOpen;

  /// `Ctrl/Cmd + клик` и средний клик.
  final VoidCallback onOpenInNewTab;

  /// Переименовать. `null` — у пользователя нет прав, меню «⋯» не появляется
  /// вовсе, а не становится серым.
  final VoidCallback? onRename;

  /// Удалить. `null` — прав нет.
  final VoidCallback? onDelete;

  /// Телефонная раскладка: две строки, высота 56.
  final bool compact;

  /// Высота строки на десктопе.
  static const height = 44.0;

  /// Высота строки на телефоне.
  static const compactHeight = 56.0;

  /// Ширина колонки ключа. Ключ не обрезается никогда.
  static const keyColumnWidth = 56.0;

  /// Ширина колонки меню «⋯».
  static const actionsColumnWidth = 32.0;

  /// Высота строки для раскладки.
  static double heightOf({required bool compact}) =>
      compact ? compactHeight : height;

  @override
  State<QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<QueueRow> {
  final _menuController = MenuController();
  var _hovered = false;
  var _focused = false;

  bool get _canManage => widget.onRename != null || widget.onDelete != null;

  bool get _isModifierPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _onTap() =>
      _isModifierPressed ? widget.onOpenInNewTab() : widget.onOpen();

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) widget.onOpenInNewTab();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final queue = widget.queue;
    final count = queue.openIssueCount.toInt();

    return Semantics(
      button: true,
      label: '${queue.key}, ${queue.name}, ${SLPlural.issues(count)}, открыть',
      child: ExcludeSemantics(
        child: SLFocusRing(
          focused: _focused,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowHoverHighlight: (value) => setState(() => _hovered = value),
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onOpen();

                  return null;
                },
              ),
            },
            child: Listener(
              onPointerDown: _onPointerDown,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: Container(
                  height: QueueRow.heightOf(compact: widget.compact),
                  decoration: BoxDecoration(
                    color: _hovered ? colors.surfaceHover : colors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colors.borderSubtle,
                        width: SLBorders.hairline,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SLSpacing.space3,
                  ),
                  child: widget.compact
                      ? _buildCompact(context, count)
                      : _buildWide(context, count),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, int count) => Row(
    children: [
      SizedBox(width: QueueRow.keyColumnWidth, child: _buildKey(context)),
      const SizedBox(width: SLSpacing.space3),
      Expanded(child: _buildName(context)),
      const SizedBox(width: SLSpacing.space3),
      _buildCount(context, count),
      SizedBox(
        width: QueueRow.actionsColumnWidth,
        child: _canManage ? _buildMenu(context) : null,
      ),
    ],
  );

  Widget _buildCompact(BuildContext context, int count) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          _buildKey(context),
          const SizedBox(width: SLSpacing.space2),
          Expanded(child: _buildName(context)),
          if (_canManage)
            SizedBox(
              width: QueueRow.actionsColumnWidth,
              child: _buildMenu(context),
            ),
        ],
      ),
      const SizedBox(height: SLSpacing.space1),
      Align(
        alignment: Alignment.centerLeft,
        child: _buildCount(context, count),
      ),
    ],
  );

  Widget _buildKey(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Text(
      widget.queue.key,
      maxLines: 1,
      softWrap: false,
      style: text.bodySStrong.copyWith(color: colors.accent),
    );
  }

  Widget _buildName(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Tooltip(
      message: widget.queue.name,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        widget.queue.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyS.copyWith(color: colors.textPrimary),
      ),
    );
  }

  Widget _buildCount(BuildContext context, int count) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Text(
      SLPlural.issues(count),
      style: text.label.copyWith(color: colors.textMuted),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        if (widget.onRename != null)
          MenuItemButton(
            leadingIcon: Icon(
              Icons.edit_outlined,
              size: SLIconSizes.icon16,
              color: colors.iconDefault,
            ),
            onPressed: widget.onRename,
            child: Text(
              'Изменить',
              style: text.bodyS.copyWith(color: colors.textPrimary),
            ),
          ),
        if (widget.onDelete != null)
          MenuItemButton(
            leadingIcon: Icon(
              Icons.delete_outline_rounded,
              size: SLIconSizes.icon16,
              color: colors.danger,
            ),
            onPressed: widget.onDelete,
            child: Text(
              'Удалить',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          ),
      ],
      builder: (context, controller, child) => Semantics(
        button: true,
        label: 'Действия с очередью ${widget.queue.key}',
        child: ExcludeSemantics(
          child: IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            iconSize: SLIconSizes.icon16,
            color: colors.iconDefault,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            tooltip: 'Действия с очередью',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Создать очередь» под списком. Только администратор (US-30).
class CreateQueueButton extends StatelessWidget {
  /// @nodoc
  const CreateQueueButton({
    required this.onPressed,
    this.expand = false,
    super.key,
  });

  /// @nodoc
  final VoidCallback onPressed;

  /// На телефоне кнопка занимает всю ширину внизу списка.
  final bool expand;

  @override
  Widget build(BuildContext context) => SLButton(
    label: 'Создать очередь',
    icon: Icons.add_rounded,
    expand: expand,
    onPressed: onPressed,
  );
}
