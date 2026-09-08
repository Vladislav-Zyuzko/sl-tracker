import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/platform/browser_navigator.dart';

/// Реализация для веба.
///
/// `location.assign` — именно переход, а не замена записи в истории: кнопка
/// «Назад» после входа должна возвращать туда, откуда человек пришёл.
BrowserNavigator createBrowserNavigator() => const _WebBrowserNavigator();

class _WebBrowserNavigator implements BrowserNavigator {
  const _WebBrowserNavigator();

  @override
  void assign(String url) => web.window.location.assign(url);

  @override
  void openInNewTab(String url) =>
      web.window.open(url, '_blank', 'noopener,noreferrer');

  @override
  String get origin => web.window.location.origin;
}
