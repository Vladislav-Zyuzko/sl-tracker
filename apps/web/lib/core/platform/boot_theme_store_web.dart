import 'dart:ui' show Brightness;

import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/platform/boot_theme_store.dart';

/// Реализация для веба: собственный ключ в `localStorage`.
SLBootThemeStore createBootThemeStore() => const _WebBootThemeStore();

class _WebBootThemeStore implements SLBootThemeStore {
  const _WebBootThemeStore();

  @override
  void write(Brightness? brightness) {
    // Хранилище может быть запрещено настройками сайта — тогда доступ
    // к нему бросает. Потеря зеркального ключа стоит одной вспышки
    // загрузчика и не стоит поломанного переключения темы.
    try {
      if (brightness == null) {
        web.window.localStorage.removeItem(SLBootThemeStore.storageKey);

        return;
      }

      web.window.localStorage.setItem(
        SLBootThemeStore.storageKey,
        SLBootThemeStore.encode(brightness),
      );
    } on Object {
      // Осознанно молча.
    }
  }
}
