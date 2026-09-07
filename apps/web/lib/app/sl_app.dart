import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/app_router.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

/// Корневой виджет SL Tracker.
class SLApp extends ConsumerWidget {
  /// @nodoc
  const SLApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SL Tracker',
      debugShowCheckedModeBanner: false,
      theme: SLThemeData.light,
      // Тёмной темы в MVP нет. Явное указание themeMode гарантирует, что
      // системная настройка не подсунет полупустую тему по умолчанию.
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
