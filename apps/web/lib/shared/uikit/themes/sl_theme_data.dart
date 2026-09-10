import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_priority_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_status_colors.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Темы SL Tracker.
///
/// Material 3 включён, но переопределён почти целиком: дефолтные высоты M3
/// (кнопка 40, поле 56) для плотного трекера слишком просторны
/// (`docs/design/system.md`, 13).
///
/// Тем две — [light] и [dark]. Всё, что зависит от схемы, читается
/// из [ThemeExtension], поэтому обе темы собираются одним и тем же [_build]:
/// различаются только наборы цветов и [Brightness].
///
/// Цвета тёмной схемы пока повторяют светлую (см. `SLColorScheme.dark`) —
/// готов механизм, а не оформление.
abstract final class SLThemeData {
  /// Светлая тема.
  ///
  /// Собирается один раз: [ThemeData] большой, а корневой виджет
  /// перестраивается на каждой смене адреса.
  static final ThemeData light = _build(
    colors: SLColorScheme.light(),
    statuses: SLStatusColors.light(),
    priorities: SLPriorityColors.light(),
    avatars: SLAvatarColors.light(),
    brightness: Brightness.light,
  );

  /// Тёмная тема. Тоже собирается один раз — см. [light].
  static final ThemeData dark = _build(
    colors: SLColorScheme.dark(),
    statuses: SLStatusColors.dark(),
    priorities: SLPriorityColors.dark(),
    avatars: SLAvatarColors.dark(),
    brightness: Brightness.dark,
  );

  static const _text = SLTextScheme.base();

  static ThemeData _build({
    required SLColorScheme colors,
    required SLStatusColors statuses,
    required SLPriorityColors priorities,
    required SLAvatarColors avatars,
    required Brightness brightness,
  }) {
    final materialColors = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.textOnAccent,
      secondary: colors.accentSurface,
      onSecondary: colors.accentPressed,
      error: colors.danger,
      onError: colors.textOnAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceSunken,
      outline: colors.borderStrong,
      outlineVariant: colors.border,
      shadow: colors.textPrimary,
      scrim: colors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: materialColors,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      // При тёмной теме Material по умолчанию подмешивает в поверхности
      // «оверлей высоты» — осветляет фон тем сильнее, чем выше elevation.
      // Иерархия поверхностей в системе задаётся ролями, а не высотой
      // (`system.md`, 12.3), и такое осветление её ломает.
      applyElevationOverlayColor: false,
      // Ripple в трекере выключен: наведение и нажатие — мгновенная смена
      // цвета фона, а не анимация капли (`system.md`, 3.5).
      splashFactory: NoSplash.splashFactory,
      splashColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      visualDensity: VisualDensity.compact,
      extensions: [_text, colors, statuses, priorities, avatars],
      textTheme: _textTheme(colors),
      iconTheme: IconThemeData(
        color: colors.iconDefault,
        size: SLIconSizes.icon16,
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: SLBorders.hairline,
        space: SLBorders.hairline,
      ),
      inputDecorationTheme: _inputDecorationTheme(colors),
      tooltipTheme: _tooltipTheme(colors),
      checkboxTheme: _checkboxTheme(colors),
      tabBarTheme: _tabBarTheme(colors),
      dialogTheme: _dialogTheme(colors),
      menuTheme: _menuTheme(colors),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.trackDefault),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(SLRadii.sm),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Переход между экранами трекера не анимируется: пользователь
          // ходит по спискам десятки раз в час, анимация ощущается тормозом.
          TargetPlatform.android: _NoTransitionsBuilder(),
          TargetPlatform.iOS: _NoTransitionsBuilder(),
          TargetPlatform.linux: _NoTransitionsBuilder(),
          TargetPlatform.macOS: _NoTransitionsBuilder(),
          TargetPlatform.windows: _NoTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(SLColorScheme colors) {
    final primary = colors.textPrimary;

    return TextTheme(
      displayLarge: _text.h1.copyWith(color: primary),
      displayMedium: _text.h1.copyWith(color: primary),
      displaySmall: _text.h2.copyWith(color: primary),
      headlineLarge: _text.h2.copyWith(color: primary),
      headlineMedium: _text.h2.copyWith(color: primary),
      headlineSmall: _text.title.copyWith(color: primary),
      titleLarge: _text.h2.copyWith(color: primary),
      titleMedium: _text.title.copyWith(color: primary),
      titleSmall: _text.bodyStrong.copyWith(color: primary),
      bodyLarge: _text.body.copyWith(color: primary),
      bodyMedium: _text.bodyS.copyWith(color: primary),
      bodySmall: _text.label.copyWith(color: colors.textMuted),
      labelLarge: _text.bodySStrong.copyWith(color: primary),
      labelMedium: _text.labelStrong.copyWith(color: colors.textSecondary),
      labelSmall: _text.overline.copyWith(color: colors.textMuted),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(SLColorScheme colors) {
    OutlineInputBorder border(
      Color color, [
      double width = SLBorders.hairline,
    ]) {
      return OutlineInputBorder(
        borderRadius: SLRadii.smAll,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      hintStyle: _text.bodyS.copyWith(color: colors.textMuted),
      labelStyle: _text.label.copyWith(color: colors.textSecondary),
      helperStyle: _text.label.copyWith(color: colors.textMuted),
      errorStyle: _text.label.copyWith(color: colors.danger),
      // Один и тот же `contentPadding` во всех состояниях: рамка в фокусе
      // утолщается внутрь, и текст с кареткой при получении фокуса
      // не сдвигаются ни на пиксель (`system.md`, 10.6.1).
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SLSpacing.space2,
        vertical: SLSpacing.space1,
      ),
      // Цвет рамки означает состояние, толщина — фокус (`system.md`, 10.6.1).
      // Кольцо фокуса полю ввода не добавляется: в `borderFocus` должен быть
      // ровно один контур, и здесь это сама рамка.
      border: border(colors.borderStrong),
      enabledBorder: border(colors.borderStrong),
      focusedBorder: border(colors.borderFocus, SLBorders.controlFocus),
      errorBorder: border(colors.borderDanger),
      // Ошибка важнее того, где сейчас каретка: цвет остаётся «ошибочным»,
      // фокус передаётся утолщением.
      focusedErrorBorder: border(colors.borderDanger, SLBorders.controlFocus),
      disabledBorder: border(colors.border),
    );
  }

  static TooltipThemeData _tooltipTheme(SLColorScheme colors) {
    return TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      textStyle: _text.label.copyWith(color: colors.tooltipText),
      padding: const EdgeInsets.symmetric(
        horizontal: SLSpacing.space2,
        vertical: SLSpacing.space1,
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: colors.tooltipSurface,
        borderRadius: SLRadii.smAll,
      ),
    );
  }

  static CheckboxThemeData _checkboxTheme(SLColorScheme colors) {
    return CheckboxThemeData(
      splashRadius: 0,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colors.borderStrong, width: SLBorders.hairline),
      shape: const RoundedRectangleBorder(borderRadius: SLRadii.smAll),
      checkColor: WidgetStatePropertyAll(colors.textOnAccent),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.surfaceDisabled;
        }
        if (states.contains(WidgetState.selected)) return colors.accent;

        return colors.surface;
      }),
    );
  }

  static TabBarThemeData _tabBarTheme(SLColorScheme colors) {
    return TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: colors.accent,
      dividerColor: colors.border,
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textSecondary,
      labelStyle: _text.bodySStrong,
      unselectedLabelStyle: _text.bodyS,
      overlayColor: WidgetStatePropertyAll(colors.surfaceHover),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static DialogThemeData _dialogTheme(SLColorScheme colors) {
    return DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      barrierColor: colors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: SLRadii.mdAll),
      titleTextStyle: _text.title.copyWith(color: colors.textPrimary),
      contentTextStyle: _text.body.copyWith(color: colors.textPrimary),
    );
  }

  static MenuThemeData _menuTheme(SLColorScheme colors) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: SLSpacing.space1),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: SLRadii.mdAll,
            side: BorderSide(color: colors.border),
          ),
        ),
      ),
    );
  }
}

/// Переход между страницами без анимации.
///
/// [SLMotion] задаёт длительности для компонентов; навигация в трекере
/// намеренно мгновенна и в эту шкалу не входит.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
