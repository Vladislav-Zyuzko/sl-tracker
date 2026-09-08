import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/app_router.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

/// Корневой виджет SL Tracker.
class SLApp extends ConsumerStatefulWidget {
  /// @nodoc
  const SLApp({super.key});

  @override
  ConsumerState<SLApp> createState() => _SLAppState();
}

class _SLAppState extends ConsumerState<SLApp> {
  @override
  void initState() {
    super.initState();
    // Первое, что делает приложение, — выясняет, есть ли сессия.
    // Запрос идёт один раз за запуск; всё остальное состояние сессии
    // приходит от 401-х и от кнопки выхода.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(sessionControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SL Tracker',
      debugShowCheckedModeBanner: false,
      theme: SLThemeData.light,
      // Тёмной темы в MVP нет. Явное указание themeMode гарантирует, что
      // системная настройка не подсунет полупустую тему по умолчанию.
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
      // Тосты живут над всеми экранами и переживают переходы между ними,
      // поэтому их слой поднят выше роутера.
      builder: (context, child) => SLToastHost(child: child),
    );
  }
}
