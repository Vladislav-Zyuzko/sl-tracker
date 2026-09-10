import 'package:flutter/material.dart';

/// Тени (`docs/design/system.md`, 10.7).
///
/// Тень — признак **всплытия над контентом**, а не украшение: строки, панели
/// и карточки в общем потоке теней не имеют.
///
/// Значения зависят от схемы, поэтому это [ThemeExtension], а не константы:
/// в светлой схеме тени построены на холодном `#26395B`, в тёмной — на чистом
/// чёрном с втрое-вчетверо большей alpha. Геометрия (смещения, радиусы)
/// в обеих схемах одна: она про форму, а не про цвет (10.7.1).
///
/// **Тень в тёмной схеме вторична.** Затемнять уже тёмное почти нечем:
/// даже с alpha 0.70 `lg` отстаёт от светлой почти вдвое. Глубину там несут
/// тон поверхности и граница — все всплывающие слои у нас её имеют,
/// и модальное окно получило её именно поэтому (`components.md`, 13).
class SLShadows extends ThemeExtension<SLShadows> {
  const SLShadows._({
    required this.sm,
    required this.md,
    required this.lg,
    required this.base,
  });

  /// Залипшая шапка таблицы при прокрутке.
  final List<BoxShadow> sm;

  /// Выпадающее меню, поповер, тост, перетаскиваемый элемент.
  final List<BoxShadow> md;

  /// Модальное окно.
  final List<BoxShadow> lg;

  /// Непрозрачный базовый цвет тени. Нужен там, где тень рисует Material сам
  /// и принимает один цвет, а не список: `ColorScheme.shadow`. Без него
  /// в тёмной схеме Material подставил бы цвет текста и нарисовал бы
  /// вокруг всплывающего элемента светлый ореол.
  final Color base;

  /// Светлая схема: `#26395B` с альфами 0.10 / 0.12 + 0.08 / 0.18 + 0.08.
  const SLShadows.light()
    : sm = const [
        BoxShadow(color: Color(0x1A26395B), offset: Offset(0, 1), blurRadius: 2),
      ],
      md = const [
        BoxShadow(
          color: Color(0x1F26395B),
          offset: Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(color: Color(0x1426395B), offset: Offset(0, 1), blurRadius: 3),
      ],
      lg = const [
        BoxShadow(
          color: Color(0x2E26395B),
          offset: Offset(0, 16),
          blurRadius: 40,
        ),
        BoxShadow(color: Color(0x1426395B), offset: Offset(0, 2), blurRadius: 8),
      ],
      base = const Color(0xFF26395B);

  /// Тёмная схема: чистый чёрный с альфами 0.55 / 0.55 + 0.40 / 0.70 + 0.50.
  const SLShadows.dark()
    : sm = const [
        BoxShadow(color: Color(0x8C000000), offset: Offset(0, 1), blurRadius: 2),
      ],
      md = const [
        BoxShadow(
          color: Color(0x8C000000),
          offset: Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 3),
      ],
      lg = const [
        BoxShadow(
          color: Color(0xB3000000),
          offset: Offset(0, 16),
          blurRadius: 40,
        ),
        BoxShadow(color: Color(0x80000000), offset: Offset(0, 2), blurRadius: 8),
      ],
      base = const Color(0xFF000000);

  @override
  SLShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    Color? base,
  }) => SLShadows._(
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    base: base ?? this.base,
  );

  @override
  SLShadows lerp(covariant ThemeExtension<SLShadows>? other, double t) {
    if (other is! SLShadows) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return SLShadows._(
      sm: BoxShadow.lerpList(sm, other.sm, t)!,
      md: BoxShadow.lerpList(md, other.md, t)!,
      lg: BoxShadow.lerpList(lg, other.lg, t)!,
      base: Color.lerp(base, other.base, t)!,
    );
  }

  /// Достаёт тени из темы. Отсутствие расширения — ошибка сборки темы,
  /// поэтому падаем громко, а не подставляем значения по умолчанию.
  static SLShadows of(BuildContext context) =>
      Theme.of(context).extension<SLShadows>() ??
      (throw FlutterError('$SLShadows не найдена в теме $context'));
}

/// Порядок наложения слоёв (`docs/design/system.md`, 10.8).
///
/// Flutter не использует z-index, порядок задаётся порядком вставки
/// в [Overlay] и в [Stack]. Константы нужны там, где слои сравниваются
/// явно — например, при решении, что закрывает `Esc`.
sealed class SLLayers {
  /// Контент.
  static const content = 0;

  /// Залипшая шапка таблицы, шапка приложения.
  static const stickyHeader = 10;

  /// Выпадающее меню, автодополнение, поповер.
  static const menu = 20;

  /// Подложка модалки.
  static const scrim = 30;

  /// Модальное окно.
  static const dialog = 40;

  /// Тост и уведомление.
  static const toast = 50;

  /// Тултип.
  static const tooltip = 60;
}
