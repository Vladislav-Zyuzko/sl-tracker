import 'package:flutter/widgets.dart';

/// Длительности и кривые анимаций (`docs/design/system.md`, 11).
///
/// Ничего не пружинит: `Curves.elasticOut`, `bounceOut` и подобные в трекере
/// запрещены. Перемещение по списку клавишами не анимируется вовсе — задержка
/// ощущается как тормоз.
///
/// Уважение к системной настройке «уменьшить движение» — через
/// [durationOf]: на вебе Flutter прокидывает `prefers-reduced-motion`
/// в `MediaQuery.disableAnimations`, JS-интероп для этого не нужен.
sealed class SLMotion {
  /// 0 мс. Смена цвета фона при наведении на строку списка.
  static const instant = Duration.zero;

  /// 120 мс. Наведение, фокус, появление тултипа, чекбокс.
  static const fast = Duration(milliseconds: 120);

  /// 200 мс. Меню, поповер, тост, модалка, вкладки.
  static const base = Duration(milliseconds: 200);

  /// 320 мс. Раскрытие и сворачивание сайдбара, правой панели.
  static const slow = Duration(milliseconds: 320);

  /// 1400 мс, цикл. Шиммер скелетона.
  static const shimmer = Duration(milliseconds: 1400);

  /// Кривая для [fast].
  static const fastCurve = Curves.easeOut;

  /// Кривая входа для [base].
  static const baseInCurve = Curves.easeOutCubic;

  /// Кривая выхода для [base].
  static const baseOutCurve = Curves.easeInCubic;

  /// Кривая для [slow].
  static const slowCurve = Curves.easeInOutCubic;

  /// Кривая для [shimmer].
  static const shimmerCurve = Curves.linear;

  /// Длительность с учётом системной настройки «уменьшить движение».
  ///
  /// Если пользователь просил уменьшить движение, все длительности становятся
  /// нулевыми — компонент при этом обязан остаться рабочим, а не исчезнуть.
  static Duration durationOf(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
