import 'dart:ui' show Brightness;

import 'package:sl_tracker_web/core/platform/boot_theme_store.dart';

/// Зеркальный ключ в памяти вместо `localStorage`.
///
/// Проверять надо намерение — какую схему приложение сообщило хост-странице
/// и когда стёрло ключ, — а не то, что тестовый рендерер умеет писать
/// в хранилище браузера.
class FakeBootThemeStore implements SLBootThemeStore {
  /// Что лежит в ключе. `null` — ключа нет, значит `index.html` упадёт
  /// на `prefers-color-scheme`.
  Brightness? value;

  /// Всё, что записывали, по порядку. Нужен именно порядок: стирание —
  /// такая же запись, как и остальные.
  final writes = <Brightness?>[];

  @override
  void write(Brightness? brightness) {
    value = brightness;
    writes.add(brightness);
  }
}
