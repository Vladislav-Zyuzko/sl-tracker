import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/storage/local_store.dart';

/// Хранимый выбор темы.
///
/// Режимов ровно три, и это [ThemeMode] из Flutter, а не свой enum:
/// [MaterialApp] принимает именно его, а промежуточный тип пришлось бы
/// переводить туда-обратно без единой выгоды.
///
/// Значение по умолчанию — [ThemeMode.system]: пока дизайнер не сказал
/// иного, приложение уважает настройку ОС, а не навязывает свою.
abstract final class SLThemeModePreference {
  /// Ключ в локальном хранилище.
  static const storageKey = 'sl.theme.mode';

  /// Режим для пользователя, который ещё не выбирал.
  static const defaultMode = ThemeMode.system;

  /// Порядок в интерфейсе: сперва «как в системе» — это значение
  /// по умолчанию, и оно должно быть первым в списке выбора.
  static const order = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  /// Читает сохранённый выбор. Нет значения или оно испорчено —
  /// [defaultMode].
  static Future<ThemeMode> read(SLLocalStore store) async =>
      decode(await store.readString(storageKey));

  /// Сохраняет выбор.
  static Future<void> write(SLLocalStore store, ThemeMode mode) =>
      store.writeString(storageKey, encode(mode));

  /// Строка для хранилища. Имя значения enum, а не его индекс: индекс
  /// поедет при любой правке [ThemeMode] на стороне Flutter.
  static String encode(ThemeMode mode) => mode.name;

  /// Разбирает хранимое значение. Чужое или устаревшее — [defaultMode].
  static ThemeMode decode(String? stored) {
    for (final mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }

    return defaultMode;
  }
}
