import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/platform/unload_guard.dart';

/// Реализация для веба на событии `beforeunload`.
///
/// Текст диалога задаёт браузер: свой показать нельзя с 2017 года, а без
/// взаимодействия со страницей диалога может не быть вовсе. Поэтому это
/// подстраховка поверх подтверждения внутри приложения, а не замена ему.
UnloadGuard createUnloadGuard() => _WebUnloadGuard();

class _WebUnloadGuard implements UnloadGuard {
  JSFunction? _listener;

  @override
  void arm() {
    if (_listener != null) return;

    // Обе строки обязательны: `preventDefault` — современный способ,
    // `returnValue` — то, на что до сих пор смотрят некоторые браузеры.
    final listener = ((web.Event event) {
      event.preventDefault();
      (event as web.BeforeUnloadEvent).returnValue = '';
    }).toJS;

    web.window.addEventListener('beforeunload', listener);
    _listener = listener;
  }

  @override
  void disarm() {
    final listener = _listener;
    if (listener == null) return;

    web.window.removeEventListener('beforeunload', listener);
    _listener = null;
  }
}
