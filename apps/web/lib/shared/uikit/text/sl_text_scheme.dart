import 'package:flutter/material.dart';

/// Типографическая шкала SL Tracker (`docs/design/system.md`, 9).
///
/// Вынесена в [ThemeExtension] по той же причине, что и цвет: виджет не должен
/// собирать [TextStyle] руками. `height` — множитель Flutter, то есть
/// `lineHeight / fontSize`; значения перенесены из спеки без пересчёта.
///
/// Табличные цифры включены во всех интерфейсных стилях: без них числа
/// в колонках (приоритет, story points, счётчики, даты) меняют ширину
/// при обновлении.
class SLTextScheme extends ThemeExtension<SLTextScheme> {
  const SLTextScheme._({
    required this.overline,
    required this.caption,
    required this.label,
    required this.labelStrong,
    required this.bodyS,
    required this.bodySStrong,
    required this.body,
    required this.bodyStrong,
    required this.title,
    required this.h2,
    required this.h1,
    required this.mono,
  });

  /// Интерфейсное семейство. Подключается файлами из `fonts/`,
  /// а не пакетом `google_fonts`.
  static const interFamily = 'Inter';

  /// Моноширинное семейство для кода.
  static const monoFamily = 'JetBrains Mono';

  /// Резервные семейства на случай, если файл шрифта не загрузился.
  static const _fallback = <String>['Segoe UI', 'Roboto', 'Helvetica', 'Arial'];

  /// Табличные цифры — обязательны для всех интерфейсных стилей.
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// 11/16/600, UPPERCASE. Заголовки колонок таблицы, разделители групп
  /// в сайдбаре, бейдж роли.
  final TextStyle overline;

  /// 11/16/400. Плашка статуса в строке, самые плотные метаданные.
  final TextStyle caption;

  /// 12/16/400. Метаданные: дата, автор, счётчики.
  final TextStyle label;

  /// 12/16/600. Плашка статуса в карточке, число приоритета, story points.
  final TextStyle labelStrong;

  /// 13/18/400. Рабочая лошадь: строка списка, поля ввода, меню, вкладки.
  final TextStyle bodyS;

  /// 13/18/600. Акцент внутри строки, кнопки, активная вкладка, ключ задачи.
  final TextStyle bodySStrong;

  /// 14/20/400. Описание задачи, комментарии, тексты модалок.
  final TextStyle body;

  /// 14/20/600. Подзаголовки в тексте, имя автора комментария.
  final TextStyle bodyStrong;

  /// 16/22/600. Заголовок секции, модалки, панели.
  final TextStyle title;

  /// 20/28/600. Тема задачи на странице задачи, заголовок экрана.
  final TextStyle h2;

  /// 24/32/700. Пустые состояния и экран входа. В рабочих экранах
  /// не встречается.
  final TextStyle h1;

  /// 13/18/400, JetBrains Mono. Инлайн-код и блок кода.
  final TextStyle mono;

  /// Базовая шкала. Схема одна на светлую и тёмную тему: меняется цвет,
  /// а не метрика.
  const SLTextScheme.base()
    : overline = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 11,
        height: 1.4545,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFeatures: _tabular,
      ),
      caption = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 11,
        height: 1.4545,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        fontFeatures: _tabular,
      ),
      label = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 12,
        height: 1.3333,
        fontWeight: FontWeight.w400,
        fontFeatures: _tabular,
      ),
      labelStrong = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 12,
        height: 1.3333,
        fontWeight: FontWeight.w600,
        fontFeatures: _tabular,
      ),
      bodyS = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 13,
        height: 1.3846,
        fontWeight: FontWeight.w400,
        fontFeatures: _tabular,
      ),
      bodySStrong = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 13,
        height: 1.3846,
        fontWeight: FontWeight.w600,
        fontFeatures: _tabular,
      ),
      body = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 14,
        height: 1.4286,
        fontWeight: FontWeight.w400,
        fontFeatures: _tabular,
      ),
      bodyStrong = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 14,
        height: 1.4286,
        fontWeight: FontWeight.w600,
        fontFeatures: _tabular,
      ),
      title = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 16,
        height: 1.375,
        fontWeight: FontWeight.w600,
        fontFeatures: _tabular,
      ),
      h2 = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFeatures: _tabular,
      ),
      h1 = const TextStyle(
        fontFamily: interFamily,
        fontFamilyFallback: _fallback,
        fontSize: 24,
        height: 1.3333,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFeatures: _tabular,
      ),
      mono = const TextStyle(
        fontFamily: monoFamily,
        fontSize: 13,
        height: 1.3846,
        fontWeight: FontWeight.w400,
      );

  @override
  SLTextScheme copyWith({
    TextStyle? overline,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? labelStrong,
    TextStyle? bodyS,
    TextStyle? bodySStrong,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? title,
    TextStyle? h2,
    TextStyle? h1,
    TextStyle? mono,
  }) {
    return SLTextScheme._(
      overline: overline ?? this.overline,
      caption: caption ?? this.caption,
      label: label ?? this.label,
      labelStrong: labelStrong ?? this.labelStrong,
      bodyS: bodyS ?? this.bodyS,
      bodySStrong: bodySStrong ?? this.bodySStrong,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      title: title ?? this.title,
      h2: h2 ?? this.h2,
      h1: h1 ?? this.h1,
      mono: mono ?? this.mono,
    );
  }

  @override
  SLTextScheme lerp(covariant ThemeExtension<SLTextScheme>? other, double t) {
    if (other is! SLTextScheme) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLTextScheme._(
      overline: TextStyle.lerp(overline, other.overline, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      labelStrong: TextStyle.lerp(labelStrong, other.labelStrong, t)!,
      bodyS: TextStyle.lerp(bodyS, other.bodyS, t)!,
      bodySStrong: TextStyle.lerp(bodySStrong, other.bodySStrong, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }

  /// Достаёт типографическую шкалу из темы.
  static SLTextScheme of(BuildContext context) =>
      Theme.of(context).extension<SLTextScheme>() ??
      (throw FlutterError('$SLTextScheme не найдена в теме $context'));
}
