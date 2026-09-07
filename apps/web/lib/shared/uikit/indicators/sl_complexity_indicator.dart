import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Индикатор сложности задачи в story points (`docs/design/system.md`, 6).
///
/// Цветом не кодируется намеренно: это шкала оценки, а не срочности,
/// и цвет здесь конкурировал бы с приоритетом за внимание.
///
/// Когда значение не задано, рисуется прочерк в тех же габаритах —
/// колонка не должна прыгать.
class SLComplexityIndicator extends StatelessWidget {
  /// @nodoc
  const SLComplexityIndicator({required this.value, super.key}) : isSum = false;

  /// Сумма story points в заголовке группы или фильтра: тот же бейдж
  /// с префиксом и шириной по содержимому.
  const SLComplexityIndicator.sum({required int this.value, super.key})
    : isSum = true;

  /// Значение. `null` — сложность не задана.
  final int? value;

  /// Показывать ли значение как сумму.
  final bool isSum;

  /// Минимальная ширина бейджа: двузначное «13» помещается без скачка.
  static const minWidth = 22.0;

  /// Высота бейджа.
  static const height = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final hasValue = value != null;
    final label = hasValue ? (isSum ? 'Σ $value' : '$value') : '—';

    return Semantics(
      label: hasValue
          ? (isSum
                ? 'Сумма сложности $value story points'
                : 'Сложность $value story points')
          : 'Сложность не задана',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          constraints: const BoxConstraints(minWidth: minWidth),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space1),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: SLRadii.smAll,
            border: Border.all(
              color: colors.borderSubtle,
              width: SLBorders.hairline,
            ),
          ),
          child: Text(
            label,
            style: text.labelStrong.copyWith(
              color: hasValue ? colors.textSecondary : colors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
