import 'package:flutter/material.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_palette.dart';

/// Слой 3 дизайн-системы — заливки аватаров (`docs/design/system.md`, 8).
///
/// Все восемь цветов дают не менее 4.5:1 с инициалами роли `textOnAccent`
/// в обеих схемах: с белыми в светлой, с тёмными чернилами в тёмной.
/// Цвет выбирается детерминированно по идентификатору пользователя,
/// а не по имени: смена имени не должна менять цвет аватара.
class SLAvatarColors extends ThemeExtension<SLAvatarColors> {
  const SLAvatarColors._({required this.fills});

  /// Восемь заливок в порядке индексов из спеки.
  final List<Color> fills;

  /// Светлая схема (`system.md`, 8).
  SLAvatarColors.light()
    : fills = const [
        SLColorPalette.blueAvatar,
        SLColorPalette.teal600,
        SLColorPalette.green600,
        SLColorPalette.amber800,
        SLColorPalette.orange600,
        SLColorPalette.red600,
        SLColorPalette.pink600,
        SLColorPalette.violet600,
      ];

  /// Тёмная схема (`system.md`, 8).
  ///
  /// Порядок тонов тот же, что в светлой: у человека не меняется «его цвет»
  /// при переключении темы — синий остаётся синим, только светлее.
  ///
  /// Заливки светлые, потому что инициалы декорируются ролью `textOnAccent`,
  /// а она в тёмной схеме — тёмные чернила. Оставить тёмные заливки значило
  /// бы завести отдельную роль «чернила аватара», которой нет в светлой
  /// схеме. Побочная польза: светлый кружок читается на тёмном фоне
  /// (7.27–9.14 к `surface`), тогда как светлый `#2F6FD0` дал бы 2.4:1.
  SLAvatarColors.dark()
    : fills = const [
        SLColorPalette.avatarBlueD,
        SLColorPalette.avatarTealD,
        SLColorPalette.avatarGreenD,
        SLColorPalette.avatarAmberD,
        SLColorPalette.avatarOrangeD,
        SLColorPalette.avatarRedD,
        SLColorPalette.avatarPinkD,
        SLColorPalette.avatarVioletD,
      ];

  /// Заливка аватара пользователя с идентификатором [userId].
  ///
  /// Используется устойчивый хеш строки, а не встроенный `hashCode`: последний
  /// в Dart не гарантирует стабильности между запусками, и цвет аватара
  /// начал бы прыгать при перезагрузке страницы.
  Color fillOf(String userId) => fills[stableIndex(userId, fills.length)];

  /// Устойчивый индекс в диапазоне от нуля до [modulo] — FNV-1a, 32 бита.
  @visibleForTesting
  static int stableIndex(String value, int modulo) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) & 0xFFFFFFFF;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    return hash % modulo;
  }

  @override
  SLAvatarColors copyWith({List<Color>? fills}) =>
      SLAvatarColors._(fills: fills ?? this.fills);

  @override
  SLAvatarColors lerp(
    covariant ThemeExtension<SLAvatarColors>? other,
    double t,
  ) {
    if (other is! SLAvatarColors) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLAvatarColors._(
      fills: [
        for (var i = 0; i < fills.length; i++)
          Color.lerp(fills[i], other.fills[i], t)!,
      ],
    );
  }

  /// Достаёт палитру аватаров из темы.
  static SLAvatarColors of(BuildContext context) =>
      Theme.of(context).extension<SLAvatarColors>() ??
      (throw FlutterError('$SLAvatarColors не найдена в теме $context'));
}
