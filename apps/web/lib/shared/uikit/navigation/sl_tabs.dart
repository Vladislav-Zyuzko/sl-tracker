import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Одна вкладка.
@immutable
class SLTabItem<T> {
  /// @nodoc
  const SLTabItem({required this.value, required this.label, this.count});

  /// Значение, которое приходит в `onChanged`.
  final T value;

  /// Подпись.
  final String label;

  /// Счётчик рядом с подписью. `null` — счётчика нет; [SLTabItem.loading]
  /// вместо числа рисует скелетон-точку.
  final int? count;

  /// Счётчик ещё не загружен.
  static const loading = -1;
}

/// Ряд вкладок (`docs/design/components.md`, 12).
///
/// Своя реализация вместо `TabBar` — по одной причине, и она не про
/// оформление: набор вкладок на экране проекта зависит от роли и меняется
/// **на лету** (US-15). Смена длины `TabController` в живом дереве —
/// известный источник исключений, и спека экрана прямо об этом предупреждает.
/// Здесь выбранная вкладка хранится значением, а не индексом, поэтому
/// исчезновение вкладки — это обычная перерисовка, а не пересоздание
/// контроллера.
///
/// Клавиатура: `←` и `→` переключают вкладки, когда фокус в ряду; `Tab`
/// уводит в содержимое.
class SLTabBar<T> extends StatelessWidget {
  /// @nodoc
  const SLTabBar({
    required this.tabs,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Вкладки слева направо.
  final List<SLTabItem<T>> tabs;

  /// Выбранная вкладка.
  final T value;

  /// @nodoc
  final ValueChanged<T> onChanged;

  /// Толщина подчёркивания активной вкладки.
  static const indicatorThickness = 2.0;

  void _move(int delta) {
    final index = tabs.indexWhere((tab) => tab.value == value);
    if (index < 0) return;

    final next = (index + delta) % tabs.length;
    onChanged(tabs[next < 0 ? next + tabs.length : next].value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final density = SLDensity.ofContext(context);

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            _move(-1);

            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowRight:
            _move(1);

            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      },
      child: Container(
        height: density.tabHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
          ),
        ),
        // Ряд прокручивается, когда вкладки не помещаются; на телефоне —
        // всегда.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in tabs)
                _SLTab<T>(
                  tab: tab,
                  selected: tab.value == value,
                  onSelect: () => onChanged(tab.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SLTab<T> extends StatefulWidget {
  const _SLTab({
    required this.tab,
    required this.selected,
    required this.onSelect,
  });

  final SLTabItem<T> tab;
  final bool selected;
  final VoidCallback onSelect;

  @override
  State<_SLTab<T>> createState() => _SLTabState<T>();
}

class _SLTabState<T> extends State<_SLTab<T>> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final selected = widget.selected;
    final count = widget.tab.count;

    final labelColor = selected || _hovered
        ? colors.textPrimary
        : colors.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: count == null || count == SLTabItem.loading
          ? widget.tab.label
          : '${widget.tab.label}, $count',
      excludeSemantics: true,
      child: SLFocusRing(
        focused: _focused,
        inset: true,
        child: Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            if (key != LogicalKeyboardKey.enter &&
                key != LogicalKeyboardKey.numpadEnter &&
                key != LogicalKeyboardKey.space) {
              return KeyEventResult.ignored;
            }
            widget.onSelect();

            return KeyEventResult.handled;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onSelect,
              child: AnimatedContainer(
                duration: SLMotion.durationOf(context, SLMotion.base),
                curve: SLMotion.baseInCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: _hovered && !selected ? colors.surfaceHover : null,
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? colors.accent : const Color(0x00000000),
                      width: SLTabBar.indicatorThickness,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.tab.label,
                      style: selected
                          ? text.bodySStrong.copyWith(color: labelColor)
                          : text.bodyS.copyWith(color: labelColor),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: SLSpacing.space1),
                      if (count == SLTabItem.loading)
                        const SLSkeletonBox(width: 12, height: 12)
                      else
                        Text(
                          '$count',
                          style: text.label.copyWith(
                            color: selected
                                ? colors.textSecondary
                                : colors.textMuted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
