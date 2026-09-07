import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Счётчик-пилюля (`docs/design/components.md`, 23).
///
/// Порог показывается словами, а не обрезкой: счётчик уведомлений выше 99
/// пишется как «99+», счётчик задач выше 999 — как «999+»
/// (`screens/README.md`, 8).
class SLCounterBadge extends StatelessWidget {
  /// @nodoc
  const SLCounterBadge({
    required this.count,
    this.threshold = 99,
    this.accented = false,
    super.key,
  });

  /// Значение счётчика.
  final int count;

  /// Порог, выше которого показывается «N+».
  final int threshold;

  /// Акцентный вариант: заливка `accent`, текст `textOnAccent`.
  /// Обычный — заливка `surfaceSunken`, текст `textSecondary`.
  final bool accented;

  /// Высота пилюли.
  static const height = 16.0;

  /// Форматирует значение с учётом порога.
  static String format(int count, int threshold) =>
      count > threshold ? '$threshold+' : '$count';

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      height: height,
      constraints: const BoxConstraints(minWidth: height),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space1),
      decoration: BoxDecoration(
        color: accented ? colors.accent : colors.surfaceSunken,
        borderRadius: SLRadii.fullAll,
      ),
      child: Text(
        format(count, threshold),
        style: text.overline.copyWith(
          color: accented ? colors.textOnAccent : colors.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
