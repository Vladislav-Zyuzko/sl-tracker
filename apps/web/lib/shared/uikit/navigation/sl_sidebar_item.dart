import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Элемент сайдбара (`docs/design/components.md`, 11).
///
/// Дерево строится плоским списком с уровнем вложенности в модели, а не
/// рекурсивными `ExpansionTile`: плоский список виртуализируется, рекурсия —
/// нет. Максимальная глубина — 2 (проект, очередь).
class SLSidebarItem extends StatefulWidget {
  /// @nodoc
  const SLSidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.count,
    this.isActive = false,
    this.depth = 0,
    this.collapsed = false,
    super.key,
  });

  /// Иконка элемента.
  final IconData icon;

  /// Название. При нехватке места обрезается, полное — в тултипе.
  final String title;

  /// @nodoc
  final VoidCallback onTap;

  /// Счётчик задач справа. `null` — счётчика нет.
  final int? count;

  /// Активный элемент: фон `surfaceSelected`, слева полоса `accent`.
  final bool isActive;

  /// Уровень вложенности: 0 — проект, 1 — очередь.
  final int depth;

  /// Свёрнутый сайдбар: только иконка по центру, название в тултипе.
  final bool collapsed;

  /// Порог счётчика задач.
  static const countThreshold = 999;

  @override
  State<SLSidebarItem> createState() => _SLSidebarItemState();
}

class _SLSidebarItemState extends State<SLSidebarItem> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final height = SLDensity.ofContext(context).sidebarItemHeight;

    final background = widget.isActive
        ? (_hovered ? colors.surfaceSelectedHover : colors.surfaceSelected)
        : (_hovered ? colors.surfaceHover : const Color(0x00000000));

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.title,
      child: ExcludeSemantics(
        child: Tooltip(
          message: widget.title,
          // Тултип нужен только когда название могло не поместиться.
          triggerMode: widget.collapsed
              ? TooltipTriggerMode.longPress
              : TooltipTriggerMode.manual,
          child: SLFocusRing(
            focused: _focused,
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowHoverHighlight: (value) => setState(() => _hovered = value),
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap();

                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: SLRadii.smAll,
                    border: widget.isActive
                        ? Border(
                            left: BorderSide(
                              color: colors.accent,
                              width: SLBorders.selectionBar,
                            ),
                          )
                        : null,
                  ),
                  padding: EdgeInsets.only(
                    left:
                        SLSpacing.space2 +
                        widget.depth * SLSpacing.space4 -
                        (widget.isActive ? SLBorders.selectionBar : 0),
                    right: SLSpacing.space2,
                  ),
                  child: widget.collapsed
                      ? _buildCollapsed(colors)
                      : _buildExpanded(colors, text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed(SLColorScheme colors) {
    final icon = Icon(
      widget.icon,
      size: SLIconSizes.icon16,
      color: widget.isActive ? colors.accent : colors.iconMuted,
    );

    // В свёрнутом сайдбаре счётчик превращается в точку 6 px в правом
    // верхнем углу иконки.
    if (widget.count == null || widget.count == 0) return Center(child: icon);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(SLColorScheme colors, SLTextScheme text) {
    return Row(
      children: [
        Icon(
          widget.icon,
          size: SLIconSizes.icon16,
          color: widget.isActive ? colors.accent : colors.iconMuted,
        ),
        const SizedBox(width: SLSpacing.space2),
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.isActive
                ? text.bodyS.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )
                : text.bodyS.copyWith(color: colors.textSecondary),
          ),
        ),
        if (widget.count != null) ...[
          const SizedBox(width: SLSpacing.space2),
          Text(
            widget.count! > SLSidebarItem.countThreshold
                ? '${SLSidebarItem.countThreshold}+'
                : '${widget.count}',
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
