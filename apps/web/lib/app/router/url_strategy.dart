import 'package:sl_tracker_web/app/router/url_strategy_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/app/router/url_strategy_web.dart'
    as impl;

/// Включает path-стратегию адресов: `/issues/DEV-42`, а не `/#/issues/DEV-42`
/// (ADR-0005).
///
/// На платформах без браузера ничего не делает. Условный импорт нужен,
/// чтобы `flutter_web_plugins` не попал в мобильную сборку.
void configureUrlStrategy() => impl.configureUrlStrategy();
