import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/platform/browser_navigator_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/platform/browser_navigator_web.dart'
    as impl;

/// Уход браузера за пределы приложения.
///
/// Нужен ровно для одного: вход через Яндекс ID — это **полный переход
/// страницы** на `/api/auth/yandex/start`, а не XHR. Бэкенд отвечает
/// редиректом на внешний домен, и запрос за ним пойти не может (ADR-0002).
///
/// Спрятан за интерфейсом, потому что веб-специфика не должна протекать
/// в доменный код: на мобильном клиенте тот же шаг будет системным браузером
/// и app link, а не сменой `window.location`.
abstract interface class BrowserNavigator {
  /// Уводит браузер по адресу [url] полным переходом.
  ///
  /// Текущая страница выгружается: всё, что не сохранено, теряется.
  void assign(String url);
}

/// Платформенная реализация [BrowserNavigator].
///
/// Подменяется в тестах: проверять надо намерение уйти по адресу,
/// а не то, что тестовый рендерер умеет менять адресную строку.
final browserNavigatorProvider = Provider<BrowserNavigator>(
  (ref) => impl.createBrowserNavigator(),
);
