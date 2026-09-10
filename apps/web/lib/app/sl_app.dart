import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/app_router.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_providers.dart';
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
      darkTheme: SLThemeData.dark,
      // В режиме `system` MaterialApp сам следит за platformBrightness
      // и перекрашивает приложение, когда пользователь меняет настройку ОС
      // прямо во время работы.
      themeMode: ref.watch(themeModeProvider),
      // Переключение схемы мгновенное (`system.md`, 12.5). Иначе Flutter
      // интерполирует три десятка ролей разом, и промежуточные кадры —
      // это грязные полутона, которых нет ни в одной схеме. Смена темы —
      // редкое явное действие, эффект ему не нужен; заодно это честнее
      // по отношению к `prefers-reduced-motion`.
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(routerProvider),
      // Тосты живут над всеми экранами и переживают переходы между ними,
      // поэтому их слой поднят выше роутера.
      builder: (context, child) => SLToastHost(child: child),
    );
  }
}
