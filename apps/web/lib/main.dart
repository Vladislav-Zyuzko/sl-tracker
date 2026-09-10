import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/url_strategy.dart';
import 'package:sl_tracker_web/app/sl_app.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_preference.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_providers.dart';
import 'package:sl_tracker_web/core/storage/local_store.dart';

/// Точка входа приложения.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Адреса без решётки: /issues/DEV-42, а не /#/issues/DEV-42 (ADR-0005).
  configureUrlStrategy();

  // Выбранная тема читается до первого кадра. Асинхронное восстановление уже
  // после старта дало бы вспышку светлой темы у того, кто выбрал тёмную:
  // это чтение одного ключа из localStorage, а лоадер в index.html всё
  // равно на экране.
  final store = createLocalStore();
  final themeMode = await SLThemeModePreference.read(store);

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const SLApp(),
    ),
  );
}
