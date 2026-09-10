import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/theme/theme_mode_preference.dart';
import 'package:sl_tracker_web/core/storage/local_store.dart';

/// Режим, с которым приложение поднимается.
///
/// Читается в `main` **до** первого кадра и подставляется сюда через
/// `overrideWithValue`. Асинхронное восстановление уже после старта дало бы
/// вспышку светлой темы у того, кто выбрал тёмную, — самый заметный сорт
/// мигания, какой бывает.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) => SLThemeModePreference.defaultMode,
);

/// Текущий режим темы.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Контроллер выбора темы.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  /// Выбрать режим.
  ///
  /// Тема меняется сразу, запись в хранилище — следом: ждать диска ради
  /// перекраски интерфейса пользователь не должен. Не сохранилось — выбор
  /// не переживёт перезагрузку, и это всё.
  Future<void> select(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;
    await SLThemeModePreference.write(ref.read(localStoreProvider), mode);
  }
}
