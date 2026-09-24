import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Состояние записи в административном списке
/// (`docs/design/components.md`, 23.3).
enum SLRecordState {
  /// Запись действует.
  active,

  /// Срок записи истёк.
  expired,

  /// Запись отозвана человеком.
  revoked,
}

/// Плашка состояния записи (`docs/design/components.md`, 23.3).
///
/// Одна плашка на все списки, где запись бывает действующей, просроченной
/// или отозванной: приглашения, токены доступа.
///
/// Цвет — **не единственный носитель смысла**: состояние названо словом,
/// поэтому плашка читается и на скриншоте в оттенках серого.
///
/// Плашка не дублирует то, что уже сказано текстом соседней колонки: если
/// колонка «Истекает» пишет «истёк 1 фев», плашки «Истёк» в той же строке
/// быть не должно — это решает вызывающий экран.
class SLRecordStateBadge extends StatelessWidget {
  /// @nodoc
  const SLRecordStateBadge({
    required this.label,
    required this.state,
    this.tooltip,
    super.key,
  });

  /// Текст: «Действует», «Истёк», «Отозван». Задаётся экраном — род слова
  /// зависит от того, что за запись.
  final String label;

  /// @nodoc
  final SLRecordState state;

  /// Уточнение по наведению: «Отозван 3 марта 2026, 14:32».
  final String? tooltip;

  /// Высота плашки.
  static const height = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final (background, foreground) = switch (state) {
      SLRecordState.active => (colors.successSurface, colors.success),
      SLRecordState.expired => (colors.surfaceSunken, colors.textSecondary),
      SLRecordState.revoked => (colors.dangerSurface, colors.danger),
    };

    final badge = Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: SLRadii.fullAll,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.caption.copyWith(color: foreground),
      ),
    );

    final tooltip = this.tooltip;

    return tooltip == null ? badge : Tooltip(message: tooltip, child: badge);
  }
}
