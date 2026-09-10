import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';

/// Переключатель (`docs/design/components.md`, 23).
///
/// Свой, а не материаловский `Switch`: у Material 3 переключатель 52 × 32
/// и темой не уменьшается, а спека требует 32 × 18 с бегунком 14. Разница
/// не косметическая — в плотной строке настроек 32 px высоты ломают ритм
/// списка.
///
/// Состояние передаётся **положением бегунка**, а не только цветом: у
/// выключенного трек `trackDefault`, и различить его с включённым можно
/// без цветового зрения.
///
/// Использовать только для настроек, применяемых мгновенно: кнопки
/// «Сохранить» рядом с переключателем не бывает.
class SLSwitch extends StatefulWidget {
  /// @nodoc
  const SLSwitch({
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
    super.key,
  });

  /// Включён ли переключатель.
  final bool value;

  /// Обработчик. `null` — переключатель отключён.
  final ValueChanged<bool>? onChanged;

  /// Доступное имя. `null` — имя даёт строка, в которой живёт переключатель.
  final String? semanticsLabel;

  /// Ширина трека.
  static const width = 32.0;

  /// Высота трека.
  static const height = 18.0;

  /// Диаметр бегунка.
  static const thumbSize = 14.0;

  @override
  State<SLSwitch> createState() => _SLSwitchState();
}

class _SLSwitchState extends State<SLSwitch> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final enabled = widget.onChanged != null;
    final padding = (SLSwitch.height - SLSwitch.thumbSize) / 2;

    final track = AnimatedContainer(
      duration: SLMotion.durationOf(context, SLMotion.fast),
      curve: SLMotion.fastCurve,
      width: SLSwitch.width,
      height: SLSwitch.height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: !enabled
            ? colors.surfaceDisabled
            : widget.value
            ? colors.accent
            : colors.trackDefault,
        borderRadius: SLRadii.fullAll,
      ),
      child: AnimatedAlign(
        duration: SLMotion.durationOf(context, SLMotion.fast),
        curve: SLMotion.fastCurve,
        alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: SLSwitch.thumbSize,
          height: SLSwitch.thumbSize,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    return Semantics(
      toggled: widget.value,
      label: widget.semanticsLabel,
      child: ExcludeSemantics(
        child: Focus(
          canRequestFocus: enabled,
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (node, event) {
            // Пробел переключает то, что под фокусом (`profile.md`,
            // «Клавиатура»). `Enter` здесь не нужен: он принадлежит форме.
            if (event is! KeyDownEvent ||
                event.logicalKey != LogicalKeyboardKey.space ||
                !enabled) {
              return KeyEventResult.ignored;
            }

            widget.onChanged!(!widget.value);

            return KeyEventResult.handled;
          },
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
              // Зона нажатия на тач — не меньше 44 × 44, при том что сам
              // переключатель остаётся 32 × 18.
              child: SizedBox(
                width: SLSizes.touchTarget,
                height: SLSizes.touchTarget,
                child: Center(
                  child: SLFocusRing(
                    focused: _focused,
                    borderRadius: SLRadii.full,
                    child: track,
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
