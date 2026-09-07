import 'package:flutter/widgets.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_palette.dart';

/// Тени (`docs/design/system.md`, 10.7).
///
/// Все построены на `#26395B`, чтобы совпадать с холодным семейством.
/// Тень — признак всплытия над контентом, а не украшение: строки, панели
/// и карточки в общем потоке теней не имеют.
sealed class SLShadows {
  /// Залипшая шапка таблицы при прокрутке.
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x1A26395B), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Выпадающее меню, поповер, тост, перетаскиваемый элемент.
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x1F26395B), offset: Offset(0, 4), blurRadius: 12),
    BoxShadow(color: Color(0x1426395B), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Модальное окно.
  static const lg = <BoxShadow>[
    BoxShadow(color: Color(0x2E26395B), offset: Offset(0, 16), blurRadius: 40),
    BoxShadow(color: Color(0x1426395B), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// Базовый цвет теней. Вынесен отдельно, чтобы было видно: значения выше —
  /// это [SLColorPalette.n800] с альфой из спеки, а не случайные числа.
  static const base = SLColorPalette.n800;
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
