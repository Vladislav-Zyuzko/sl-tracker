import 'dart:ui' show Brightness;

import 'package:sl_tracker_web/core/platform/boot_theme_store.dart';

/// Реализация для платформ без хост-страницы.
///
/// Молча ничего не делает, а не падает: зеркальный ключ существует ради
/// загрузчика в `index.html`, и вне браузера его просто некому читать.
/// На мобильном клиенте первый кадр рисует сам Flutter.
SLBootThemeStore createBootThemeStore() => const _AbsentBootThemeStore();

class _AbsentBootThemeStore implements SLBootThemeStore {
  const _AbsentBootThemeStore();

  @override
  void write(Brightness? brightness) {}
}
