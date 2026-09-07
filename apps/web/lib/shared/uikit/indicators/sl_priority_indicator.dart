import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_priority_colors.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Индикатор приоритета задачи (`docs/design/system.md`, 5).
///
/// Точное значение несёт **число** — оно всегда видно, всегда читается
/// скринридером и не требует легенды. Быстрое сканирование глазами
/// обеспечивает вертикальная шкала: высота столбика пропорциональна значению,
/// и эта форма читается даже в оттенках серого. Цвет кодирует лишь четыре
/// диапазона — столько человек различает надёжно.
///
/// Приоритет пустым не бывает: значение `0` — это «Низкий», а не «пусто»
/// (D-15). Прочерк рисуется только в [SLPriorityIndicator.unset], который
/// нужен ровно для одного случая — колонка ещё не загрузилась и не должна
/// прыгать по ширине.
class SLPriorityIndicator extends StatelessWidget {
  /// @nodoc
  const SLPriorityIndicator({
    required int this.value,
    this.expanded = false,
    super.key,
  });

  /// Значение не задано. В рабочих экранах не встречается: поле приоритета
  /// всегда заполнено. Оставлено для мест, где значение ещё неизвестно.
  const SLPriorityIndicator.unset({this.expanded = false, super.key})
    : value = null;

  /// Значение приоритета, 0–100 с шагом 10.
  final int? value;

  /// Расширенная форма для сайдбара задачи: шкала, число и название
  /// диапазона — например, «80 · Высокий».
  final bool expanded;

  /// Габариты компактной формы.
  static const compactSize = Size(34, 20);

  /// Ширина трека.
  static const trackWidth = 3.0;

  /// Высота трека.
  static const trackHeight = 14.0;

  /// Минимальная ширина блока с числом. Двузначные и трёхзначные значения
  /// не должны менять ширину колонки.
  static const numberWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final priorityValue = value;

    if (priorityValue == null) {
      return SizedBox.fromSize(
        size: compactSize,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '—',
            style: text.labelStrong.copyWith(color: colors.textDisabled),
          ),
        ),
      );
    }

    final priorityColors = SLPriorityColors.of(context);
    final range = PriorityRange.of(priorityValue);
    // Значение 0 — это «Низкий»: трек пустой, число цветом textMuted.
    final numberColor = priorityValue == 0
        ? colors.textMuted
        : priorityColors.numberOf(priorityValue);

    final bar = CustomPaint(
      size: const Size(trackWidth, trackHeight),
      painter: _PriorityBarPainter(
        fraction: priorityValue / IssuePriority.max,
        trackColor: colors.borderSubtle,
        fillColor: priorityColors.barOf(priorityValue),
      ),
    );

    final number = Text(
      '$priorityValue',
      textAlign: TextAlign.right,
      style: text.labelStrong.copyWith(color: numberColor),
    );

    return Semantics(
      label:
          'Приоритет $priorityValue из ${IssuePriority.max}, '
          '${range.label.toLowerCase()}',
      child: ExcludeSemantics(
        child: expanded
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar,
                  const SizedBox(width: SLSpacing.space1),
                  number,
                  const SizedBox(width: SLSpacing.space2),
                  Text(
                    range.label,
                    style: text.bodyS.copyWith(color: colors.textSecondary),
                  ),
                ],
              )
            : SizedBox.fromSize(
                size: compactSize,
                child: Row(
                  children: [
                    bar,
                    const SizedBox(width: SLSpacing.space1),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: numberWidth,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: number,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Рисует трек и заливку шкалы приоритета.
///
/// [CustomPaint] вместо стопки виджетов: индикатор живёт в каждой строке
/// виртуализированного списка, и три виджета на строку против одного —
/// заметная разница на двух тысячах задач.
class _PriorityBarPainter extends CustomPainter {
  const _PriorityBarPainter({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
  });

  final double fraction;
  final Color trackColor;
  final Color fillColor;

  static const _radius = Radius.circular(2);

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _radius,
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    // Заливка растёт снизу вверх: высота = round(value / 100 * 14).
    final fillHeight = (fraction * size.height).roundToDouble();
    if (fillHeight <= 0) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
        _radius,
      ),
      Paint()..color = fillColor,
    );
  }

  @override
  bool shouldRepaint(_PriorityBarPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}
