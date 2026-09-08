import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_priority_indicator.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка моей активной задачи в сайдбаре (`screens/app-shell.md`).
///
/// Порядок элементов задан US-81: приоритет, ключ, тема. Ключ виден всегда
/// и не обрезается — по нему читается принадлежность к очереди; тема
/// обрезается первой.
///
/// Отдельной строки с названием проекта нет намеренно: она удвоила бы высоту
/// и убила плотность. Полный путь «Проект → Очередь → Название» спека просит
/// показывать в тултипе, но проекта и очереди в `GET /api/issues/my-active`
/// нет — в тултипе пока только тема.
class ActiveIssueRow extends StatefulWidget {
  /// @nodoc
  const ActiveIssueRow({
    required this.issue,
    required this.onOpen,
    required this.onOpenInNewTab,
    this.isSelected = false,
    super.key,
  });

  /// Задача.
  final MyIssue issue;

  /// Открыть задачу в области содержимого; сайдбар остаётся.
  final VoidCallback onOpen;

  /// `Ctrl/Cmd + клик` и средний клик.
  final VoidCallback onOpenInNewTab;

  /// Открыта ли эта задача прямо сейчас.
  final bool isSelected;

  /// Ширина колонки ключа. Вмещает `WORK-1234` без обрезки.
  static const keyColumnWidth = 62.0;

  @override
  State<ActiveIssueRow> createState() => _ActiveIssueRowState();
}

class _ActiveIssueRowState extends State<ActiveIssueRow> {
  var _hovered = false;
  var _focused = false;

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
    final text = SLTextScheme.of(context);
    final issue = widget.issue;

    final background = widget.isSelected
        ? (_hovered ? colors.surfaceSelectedHover : colors.surfaceSelected)
        : (_hovered ? colors.surfaceHover : const Color(0x00000000));

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label:
          '${issue.key}, ${issue.title}, '
          'статус: ${issue.status.name}, '
          'приоритет ${issue.priority} из ${IssuePriority.max}, '
          '${PriorityRange.of(issue.priority).label.toLowerCase()}',
      child: ExcludeSemantics(
        child: Tooltip(
          message: '${issue.key} · ${issue.title}',
          waitDuration: const Duration(milliseconds: 500),
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: SLRadii.smAll,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: SLBorders.selectionBar,
                          child: widget.isSelected
                              ? DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    borderRadius: SLRadii.smAll,
                                  ),
                                  child: const SizedBox.expand(),
                                )
                              : null,
                        ),
                        const SizedBox(width: SLSpacing.space1),
                        SLPriorityIndicator(value: issue.priority),
                        const SizedBox(width: SLSpacing.space2),
                        SizedBox(
                          width: ActiveIssueRow.keyColumnWidth,
                          child: Text(
                            issue.key,
                            maxLines: 1,
                            softWrap: false,
                            style: text.bodySStrong.copyWith(
                              color: colors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: SLSpacing.space1),
                        Expanded(
                          child: Text(
                            issue.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyS.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
