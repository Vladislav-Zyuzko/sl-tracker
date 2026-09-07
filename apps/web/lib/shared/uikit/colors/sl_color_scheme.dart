import 'package:flutter/material.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_palette.dart';

/// Слой 2 дизайн-системы — семантические роли цвета SL Tracker.
///
/// Это контракт между дизайном и кодом: спеки экранов и `components.md`
/// оперируют именами ролей, а не hex. Виджет берёт цвет только отсюда —
/// `SLColorScheme.of(context).<роль>`.
///
/// В MVP реализована одна схема — [SLColorScheme.light]. Тёмная добавляется
/// подстановкой значений в новый именованный конструктор: набор ролей и
/// сигнатуры виджетов при этом не меняются (`docs/design/system.md`, 12).
class SLColorScheme extends ThemeExtension<SLColorScheme> {
  const SLColorScheme._({
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.surfaceSelected,
    required this.surfaceSelectedHover,
    required this.surfaceDisabled,
    required this.scrim,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.trackDefault,
    required this.tooltipSurface,
    required this.tooltipText,
    required this.borderSubtle,
    required this.border,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderDanger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textOnAccent,
    required this.textOnWarning,
    required this.iconDefault,
    required this.iconMuted,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSurface,
    required this.accentBorder,
    required this.success,
    required this.successSurface,
    required this.successBorder,
    required this.warning,
    required this.warningAccent,
    required this.warningSurface,
    required this.danger,
    required this.dangerHover,
    required this.dangerSurface,
    required this.dangerBorder,
    required this.info,
    required this.overlayHover,
    required this.overlayPressed,
    required this.overlayOnAccentHover,
    required this.overlayOnAccentPressed,
  });

  /// Основная поверхность: контент, карточки, модалки, меню.
  final Color surface;

  /// Фон приложения под панелями, сайдбар, шапка таблицы.
  final Color surfaceSunken;

  /// Наведение на строку, элемент сайдбара, вторичную кнопку.
  final Color surfaceHover;

  /// Нажатие на те же элементы.
  final Color surfacePressed;

  /// Выбранная строка, активный пункт сайдбара, активная вкладка.
  final Color surfaceSelected;

  /// Наведение на уже выбранный элемент.
  final Color surfaceSelectedHover;

  /// Заливка отключённых контролов.
  final Color surfaceDisabled;

  /// Подложка модального окна.
  final Color scrim;

  /// Заливка скелетона.
  final Color skeletonBase;

  /// Светлая полоса шиммера.
  final Color skeletonHighlight;

  /// Трек переключателя и линейного прогресса.
  final Color trackDefault;

  /// Фон тултипа.
  final Color tooltipSurface;

  /// Текст тултипа, контраст 11.55.
  final Color tooltipText;

  /// Разделители строк списка и разделители внутри карточки.
  final Color borderSubtle;

  /// Контур панели, карточки, таблицы, меню.
  final Color border;

  /// Контур интерактивных элементов: поле ввода, селект, вторичная кнопка, чекбокс. Намеренно тёмный: WCAG 1.4.11 требует не менее 3:1.
  final Color borderStrong;

  /// Кольцо фокуса.
  final Color borderFocus;

  /// Поле ввода в состоянии ошибки.
  final Color borderDanger;

  /// Тема задачи, заголовки, значения полей.
  final Color textPrimary;

  /// Подписи полей, вторичные колонки.
  final Color textSecondary;

  /// Метаданные, время, счётчики, плейсхолдер.
  final Color textMuted;

  /// Только отключённые контролы. Поле без прав на правку рендерится как read-only с [textPrimary], а не как disabled.
  final Color textDisabled;

  /// Текст на [accent], [danger], [success].
  final Color textOnAccent;

  /// Текст на [warningAccent]: жёлтый требует тёмного текста.
  final Color textOnWarning;

  /// Иконки в строках и панелях.
  final Color iconDefault;

  /// Декоративные иконки, шеврон — не несут смысла в одиночку.
  final Color iconMuted;

  /// Основная кнопка, ссылка, ключ задачи, чекбокс.
  final Color accent;

  /// Наведение на акцент.
  final Color accentHover;

  /// Нажатие; текст на [accentSurface].
  final Color accentPressed;

  /// Фон инфо-плашки, выделенная строка.
  final Color accentSurface;

  /// Граница инфо-плашки.
  final Color accentBorder;

  /// «Закрыт», подтверждение, тост об успехе.
  final Color success;

  /// Фон success-плашки.
  final Color successSurface;

  /// Граница success-плашки.
  final Color successBorder;

  /// Текст и иконка предупреждения.
  final Color warning;

  /// Заливка: полоса баннера, точка индикатора.
  final Color warningAccent;

  /// Фон warning-плашки.
  final Color warningSurface;

  /// Опасная кнопка, ошибка, удаление.
  final Color danger;

  /// Наведение на опасную кнопку.
  final Color dangerHover;

  /// Фон плашки ошибки.
  final Color dangerSurface;

  /// Граница плашки ошибки.
  final Color dangerBorder;

  /// Нейтральное уведомление; значение совпадает с [accent].
  final Color info;

  /// Наведение поверх произвольной подложки, если нет готового токена фона.
  final Color overlayHover;

  /// Нажатие поверх произвольной подложки.
  final Color overlayPressed;

  /// Наведение поверх заливок [accent], [danger], [success].
  final Color overlayOnAccentHover;

  /// Нажатие поверх тех же заливок.
  final Color overlayOnAccentPressed;

  /// Светлая схема SL Tracker — единственная в MVP.
  SLColorScheme.light()
    : surface = SLColorPalette.n0,
      surfaceSunken = SLColorPalette.n50,
      surfaceHover = SLColorPalette.n100,
      surfacePressed = SLColorPalette.n150,
      surfaceSelected = SLColorPalette.blue50,
      surfaceSelectedHover = SLColorPalette.blue150,
      surfaceDisabled = SLColorPalette.n100,
      scrim = SLColorPalette.n900.withValues(alpha: 0.45),
      skeletonBase = SLColorPalette.n150,
      skeletonHighlight = SLColorPalette.n100,
      trackDefault = SLColorPalette.n300,
      tooltipSurface = SLColorPalette.n800,
      tooltipText = SLColorPalette.n0,
      borderSubtle = SLColorPalette.n150,
      border = SLColorPalette.n200,
      borderStrong = SLColorPalette.n500,
      borderFocus = SLColorPalette.blue600,
      borderDanger = SLColorPalette.red600,
      textPrimary = SLColorPalette.n800,
      textSecondary = SLColorPalette.n700,
      textMuted = SLColorPalette.n600,
      textDisabled = SLColorPalette.n400,
      textOnAccent = SLColorPalette.n0,
      textOnWarning = SLColorPalette.n800,
      iconDefault = SLColorPalette.n600,
      iconMuted = SLColorPalette.n500,
      accent = SLColorPalette.blue600,
      accentHover = SLColorPalette.blue700,
      accentPressed = SLColorPalette.blue800,
      accentSurface = SLColorPalette.blue50,
      accentBorder = SLColorPalette.blue200,
      success = SLColorPalette.green600,
      successSurface = SLColorPalette.green50,
      successBorder = SLColorPalette.green200,
      warning = SLColorPalette.amber800,
      warningAccent = SLColorPalette.amber500,
      warningSurface = SLColorPalette.amber50,
      danger = SLColorPalette.red600,
      dangerHover = SLColorPalette.red700,
      dangerSurface = SLColorPalette.red50,
      dangerBorder = SLColorPalette.red400,
      info = SLColorPalette.blue600,
      overlayHover = SLColorPalette.n800.withValues(alpha: 0.05),
      overlayPressed = SLColorPalette.n800.withValues(alpha: 0.09),
      overlayOnAccentHover = SLColorPalette.n0.withValues(alpha: 0.10),
      overlayOnAccentPressed = SLColorPalette.n0.withValues(alpha: 0.18);

  @override
  SLColorScheme copyWith({
    Color? surface,
    Color? surfaceSunken,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? surfaceSelected,
    Color? surfaceSelectedHover,
    Color? surfaceDisabled,
    Color? scrim,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? trackDefault,
    Color? tooltipSurface,
    Color? tooltipText,
    Color? borderSubtle,
    Color? border,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderDanger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textOnAccent,
    Color? textOnWarning,
    Color? iconDefault,
    Color? iconMuted,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? accentSurface,
    Color? accentBorder,
    Color? success,
    Color? successSurface,
    Color? successBorder,
    Color? warning,
    Color? warningAccent,
    Color? warningSurface,
    Color? danger,
    Color? dangerHover,
    Color? dangerSurface,
    Color? dangerBorder,
    Color? info,
    Color? overlayHover,
    Color? overlayPressed,
    Color? overlayOnAccentHover,
    Color? overlayOnAccentPressed,
  }) {
    return SLColorScheme._(
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      surfaceSelectedHover: surfaceSelectedHover ?? this.surfaceSelectedHover,
      surfaceDisabled: surfaceDisabled ?? this.surfaceDisabled,
      scrim: scrim ?? this.scrim,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      trackDefault: trackDefault ?? this.trackDefault,
      tooltipSurface: tooltipSurface ?? this.tooltipSurface,
      tooltipText: tooltipText ?? this.tooltipText,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderDanger: borderDanger ?? this.borderDanger,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      textOnWarning: textOnWarning ?? this.textOnWarning,
      iconDefault: iconDefault ?? this.iconDefault,
      iconMuted: iconMuted ?? this.iconMuted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSurface: accentSurface ?? this.accentSurface,
      accentBorder: accentBorder ?? this.accentBorder,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningAccent: warningAccent ?? this.warningAccent,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
      dangerHover: dangerHover ?? this.dangerHover,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      info: info ?? this.info,
      overlayHover: overlayHover ?? this.overlayHover,
      overlayPressed: overlayPressed ?? this.overlayPressed,
      overlayOnAccentHover: overlayOnAccentHover ?? this.overlayOnAccentHover,
      overlayOnAccentPressed:
          overlayOnAccentPressed ?? this.overlayOnAccentPressed,
    );
  }

  @override
  SLColorScheme lerp(covariant ThemeExtension<SLColorScheme>? other, double t) {
    if (other is! SLColorScheme) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLColorScheme._(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      surfaceSelectedHover: Color.lerp(
        surfaceSelectedHover,
        other.surfaceSelectedHover,
        t,
      )!,
      surfaceDisabled: Color.lerp(surfaceDisabled, other.surfaceDisabled, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
      trackDefault: Color.lerp(trackDefault, other.trackDefault, t)!,
      tooltipSurface: Color.lerp(tooltipSurface, other.tooltipSurface, t)!,
      tooltipText: Color.lerp(tooltipText, other.tooltipText, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderDanger: Color.lerp(borderDanger, other.borderDanger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      textOnWarning: Color.lerp(textOnWarning, other.textOnWarning, t)!,
      iconDefault: Color.lerp(iconDefault, other.iconDefault, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningAccent: Color.lerp(warningAccent, other.warningAccent, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerHover: Color.lerp(dangerHover, other.dangerHover, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      info: Color.lerp(info, other.info, t)!,
      overlayHover: Color.lerp(overlayHover, other.overlayHover, t)!,
      overlayPressed: Color.lerp(overlayPressed, other.overlayPressed, t)!,
      overlayOnAccentHover: Color.lerp(
        overlayOnAccentHover,
        other.overlayOnAccentHover,
        t,
      )!,
      overlayOnAccentPressed: Color.lerp(
        overlayOnAccentPressed,
        other.overlayOnAccentPressed,
        t,
      )!,
    );
  }

  /// Достаёт схему из темы. Отсутствие расширения — ошибка сборки темы,
  /// поэтому падаем громко, а не подставляем значения по умолчанию.
  static SLColorScheme of(BuildContext context) =>
      Theme.of(context).extension<SLColorScheme>() ??
      (throw FlutterError('$SLColorScheme не найдена в теме $context'));
}
