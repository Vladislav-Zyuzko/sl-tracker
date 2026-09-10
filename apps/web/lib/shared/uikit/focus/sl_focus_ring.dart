import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Кольцо клавиатурного фокуса — одно на весь проект
/// (`docs/design/components.md`, 23).
///
/// 2 px цветом `borderFocus`, смещение 1 px наружу, радиус равен радиусу
/// элемента плюс 1. Кольцо рисуется **поверх и снаружи** ребёнка и не влияет
/// на раскладку: иначе при получении фокуса строка списка сдвигалась бы.
///
/// Фокус виден всегда — кольцо не убирается «потому что мышью и так понятно»
/// (`components.md`, 1).
///
/// **Кому кольцо не нужно.** В `borderFocus` должен быть ровно один контур
/// (`system.md`, 10.6.1). Кольцо — для элементов, чья рамка нейтральна
/// (кнопка, включая вторичную, строка списка, карточка, вкладка, чип,
/// чекбокс, плитка) или отсутствует вовсе. Элементу, чья **собственная рамка
/// окрашивается в `borderFocus`** — поле ввода, многострочное поле, поиск,
/// выпадающий список, селектор пользователя, — кольцо добавлять нельзя:
/// получатся два синих контура с зазором, читается как «инпут внутри инпута».
/// Такой элемент показывает фокус утолщением своей рамки
/// до [SLBorders.controlFocus].
class SLFocusRing extends StatelessWidget {
  /// @nodoc
  const SLFocusRing({
    required this.focused,
    required this.child,
    this.borderRadius = SLRadii.sm,
    this.inset = false,
    super.key,
  });

  /// Показывать ли кольцо.
  final bool focused;

  /// Радиус элемента, вокруг которого рисуется кольцо. К нему прибавляется
  /// зазор, чтобы кольцо шло эквидистантно.
  final double borderRadius;

  /// Рисовать кольцо внутрь элемента, а не наружу.
  ///
  /// Нужно там, где снаружи кольцо обрезали бы соседи — например, в строке
  /// виртуализированного списка (`components.md`, 10.2).
  final bool inset;

  /// Оформляемый элемент.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!focused) return child;

    final colors = SLColorScheme.of(context);
    final offset = inset
        ? SLBorders.focusRing
        : -(SLBorders.focusRingGap + SLBorders.focusRing);
    final radius = inset
        ? borderRadius
        : borderRadius + SLBorders.focusRingGap + SLBorders.focusRing;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: offset,
          top: offset,
          right: offset,
          bottom: offset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: colors.borderFocus,
                  width: SLBorders.focusRing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
