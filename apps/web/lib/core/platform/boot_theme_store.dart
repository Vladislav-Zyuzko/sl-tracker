import 'dart:ui' show Brightness;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/platform/boot_theme_store_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/platform/boot_theme_store_web.dart'
    as impl;

/// Зеркало выбранной схемы для хост-страницы (`docs/design/system.md`, 12.5).
///
/// Задача одна: убрать вспышку светлого загрузчика у человека, который выбрал
/// тёмную схему при светлой системе. `index.html` рисует загрузчик **раньше**,
/// чем поднимается Flutter, и знает только `prefers-color-scheme`, то есть
/// системную настройку. Явный выбор лежит в `shared_preferences`, чей формат
/// хранения — деталь пакета, и разбирать её в `index.html` нельзя.
///
/// Поэтому рядом кладётся собственный ключ `sl.theme.boot` с **уже
/// вычисленной** схемой. Пишется он напрямую в `localStorage`, мимо
/// `shared_preferences`: договорённость с `index.html` должна быть нашей
/// целиком, иначе она снова окажется завязана на чужой формат.
///
/// Спрятан за интерфейсом по общему правилу: `dart:html` не должен протекать
/// в код приложения, а на мобильном клиенте хост-страницы нет вовсе.
abstract interface class SLBootThemeStore {
  /// Ключ, который читает `index.html`. Значения — `light` и `dark`.
  static const storageKey = 'sl.theme.boot';

  /// Значение для схемы [brightness].
  static String encode(Brightness brightness) =>
      brightness == Brightness.dark ? 'dark' : 'light';

  /// Записывает действующую схему.
  ///
  /// `null` — **стереть** ключ. Так делается в режиме «как в системе»:
  /// там правильный ответ уже знает `prefers-color-scheme`, а записанное
  /// когда-то значение со временем протухнет и начнёт врать — человек
  /// сменит тему в ОС, а загрузчик останется в старой схеме.
  void write(Brightness? brightness);
}

/// Платформенная реализация [SLBootThemeStore].
final bootThemeStoreProvider = Provider<SLBootThemeStore>(
  (ref) => impl.createBootThemeStore(),
);
