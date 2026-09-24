import 'package:sl_tracker_web/core/platform/unload_guard.dart';

/// Реализация для платформ без браузера.
///
/// Молча ничего не делает, и это правильно: вкладки, которую можно закрыть
/// мимо приложения, там нет. Падать здесь нельзя — экран токенов обязан
/// работать и без подстраховки.
UnloadGuard createUnloadGuard() => const _UnsupportedUnloadGuard();

class _UnsupportedUnloadGuard implements UnloadGuard {
  const _UnsupportedUnloadGuard();

  @override
  void arm() {}

  @override
  void disarm() {}
}
