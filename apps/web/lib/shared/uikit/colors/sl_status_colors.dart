import 'package:flutter/material.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_palette.dart';

/// Слой 3 дизайн-системы — палитра статусов задачи.
///
/// Вынесена в [ThemeExtension], а не в константы внутри enum: иначе для тёмной
/// темы пришлось бы править доменный код (`docs/design/system.md`, 12.5).
///
/// В спеках экранов эти значения упоминаются как `statusSurface`
/// и `statusText`.
class SLStatusColors extends ThemeExtension<SLStatusColors> {
  const SLStatusColors._({required this.surfaces, required this.texts});

  /// Фон плашки по статусу.
  final Map<IssueStatus, Color> surfaces;

  /// Цвет текста и иконки плашки по статусу.
  final Map<IssueStatus, Color> texts;

  /// Светлая схема.
  SLStatusColors.light()
    : surfaces = const {
        IssueStatus.open: SLColorPalette.n150,
        IssueStatus.inProgress: SLColorPalette.blue100,
        IssueStatus.review: SLColorPalette.purple50,
        IssueStatus.testing: SLColorPalette.amber100,
        IssueStatus.closed: SLColorPalette.green100,
      },
      texts = const {
        IssueStatus.open: SLColorPalette.n700,
        IssueStatus.inProgress: SLColorPalette.blue800,
        IssueStatus.review: SLColorPalette.purple700,
        IssueStatus.testing: SLColorPalette.amber800,
        IssueStatus.closed: SLColorPalette.green600,
      };

  /// Фон плашки статуса.
  Color surfaceOf(IssueStatus status) => surfaces[status]!;

  /// Цвет текста и иконки плашки статуса.
  Color textOf(IssueStatus status) => texts[status]!;

  @override
  SLStatusColors copyWith({
    Map<IssueStatus, Color>? surfaces,
    Map<IssueStatus, Color>? texts,
  }) {
    return SLStatusColors._(
      surfaces: surfaces ?? this.surfaces,
      texts: texts ?? this.texts,
    );
  }

  @override
  SLStatusColors lerp(
    covariant ThemeExtension<SLStatusColors>? other,
    double t,
  ) {
    if (other is! SLStatusColors) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLStatusColors._(
      surfaces: _lerpMap(surfaces, other.surfaces, t),
      texts: _lerpMap(texts, other.texts, t),
    );
  }

  static Map<IssueStatus, Color> _lerpMap(
    Map<IssueStatus, Color> a,
    Map<IssueStatus, Color> b,
    double t,
  ) {
    return {
      for (final status in IssueStatus.values)
        status: Color.lerp(a[status], b[status], t)!,
    };
  }

  /// Достаёт палитру статусов из темы.
  static SLStatusColors of(BuildContext context) =>
      Theme.of(context).extension<SLStatusColors>() ??
      (throw FlutterError('$SLStatusColors не найдена в теме $context'));
}
