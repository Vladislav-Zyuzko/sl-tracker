import 'package:sl_tracker_web/core/platform/browser_navigator.dart';

/// Реализация для платформ, где браузера нет.
///
/// Осознанно падает вместо тихого бездействия: если вход через Яндекс ID
/// однажды позовут с мобильного клиента, это должно быть заметно сразу,
/// а не превратиться в кнопку, которая ничего не делает.
BrowserNavigator createBrowserNavigator() =>
    const _UnsupportedBrowserNavigator();

class _UnsupportedBrowserNavigator implements BrowserNavigator {
  const _UnsupportedBrowserNavigator();

  @override
  void openInNewTab(String url) => throw UnsupportedError(
    'Вкладок вне браузера нет: на мобильном клиенте карточка открывается '
    'обычным переходом.',
  );

  /// Вне браузера origin приложения неизвестен: адрес проекта собирается
  /// как путь. Падать здесь нельзя — это не действие, а чтение.
  @override
  String get origin => '';

  @override
  void assign(String url) => throw UnsupportedError(
    'Полный переход браузера доступен только в вебе. '
    'Для мобильного клиента вход строится на PKCE и app links (ADR-0002).',
  );
}
