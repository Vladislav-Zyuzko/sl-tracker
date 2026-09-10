import 'package:flutter/material.dart';
import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_palette.dart';

/// Слой 3 дизайн-системы — палитра приоритета (`docs/design/system.md`, 5).
///
/// Диапазоны «низкий» и «обычный» нейтральны по цвету намеренно: иначе обычная
/// задача, а таких большинство, раскрасит весь список и цвет перестанет
/// что-либо значить. Внимание привлекают только значения 70 и выше.
///
/// Все заливки шкалы дают не менее 3:1 к роли `surface` — требование
/// WCAG 1.4.11 к графическим объектам выполняется в обеих схемах:
/// минимум по системе — 3.46 в светлой и 5.08 в тёмной.
class SLPriorityColors extends ThemeExtension<SLPriorityColors> {
  const SLPriorityColors._({required this.bars, required this.numbers});

  /// Цвет заливки шкалы по диапазону.
  final Map<PriorityRange, Color> bars;

  /// Цвет числа по диапазону.
  final Map<PriorityRange, Color> numbers;

  /// Светлая схема (`system.md`, 5).
  SLPriorityColors.light()
    : bars = const {
        PriorityRange.low: SLColorPalette.n500,
        PriorityRange.normal: SLColorPalette.n600,
        PriorityRange.high: SLColorPalette.amber700,
        PriorityRange.critical: SLColorPalette.red600,
      },
      numbers = const {
        PriorityRange.low: SLColorPalette.n600,
        PriorityRange.normal: SLColorPalette.n700,
        PriorityRange.high: SLColorPalette.amber800,
        PriorityRange.critical: SLColorPalette.red600,
      };

  /// Тёмная схема (`system.md`, 5).
  ///
  /// Главное свойство шкалы сохранено: диапазоны «низкий» и «обычный»
  /// остаются нейтральными по цвету, цвет появляется только с 70. Шкала
  /// диапазона «высокий» на ступень темнее числа — как и в светлой, где
  /// заливка светлее текста: заливке достаточно 3:1, и разведение двух
  /// значений не даёт столбику спорить по яркости с числом.
  SLPriorityColors.dark()
    : bars = const {
        PriorityRange.low: SLColorPalette.d500,
        PriorityRange.normal: SLColorPalette.d600,
        PriorityRange.high: SLColorPalette.amberD600,
        PriorityRange.critical: SLColorPalette.redD500,
      },
      numbers = const {
        PriorityRange.low: SLColorPalette.d600,
        PriorityRange.normal: SLColorPalette.d700,
        PriorityRange.high: SLColorPalette.amberD500,
        PriorityRange.critical: SLColorPalette.redD500,
      };

  /// Цвет заливки шкалы для значения приоритета.
  Color barOf(int value) => bars[PriorityRange.of(value)]!;

  /// Цвет числа для значения приоритета.
  Color numberOf(int value) => numbers[PriorityRange.of(value)]!;

  @override
  SLPriorityColors copyWith({
    Map<PriorityRange, Color>? bars,
    Map<PriorityRange, Color>? numbers,
  }) {
    return SLPriorityColors._(
      bars: bars ?? this.bars,
      numbers: numbers ?? this.numbers,
    );
  }

  @override
  SLPriorityColors lerp(
    covariant ThemeExtension<SLPriorityColors>? other,
    double t,
  ) {
    if (other is! SLPriorityColors) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLPriorityColors._(
      bars: _lerpMap(bars, other.bars, t),
      numbers: _lerpMap(numbers, other.numbers, t),
    );
  }

  static Map<PriorityRange, Color> _lerpMap(
    Map<PriorityRange, Color> a,
    Map<PriorityRange, Color> b,
    double t,
  ) {
    return {
      for (final range in PriorityRange.values)
        range: Color.lerp(a[range], b[range], t)!,
    };
  }

  /// Достаёт палитру приоритета из темы.
  static SLPriorityColors of(BuildContext context) =>
      Theme.of(context).extension<SLPriorityColors>() ??
      (throw FlutterError('$SLPriorityColors не найдена в теме $context'));
}
