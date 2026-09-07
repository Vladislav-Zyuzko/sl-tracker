import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Свёрнут ли сайдбар по выбору пользователя.
///
/// Состояние переживает перезагрузку страницы (US-80), поэтому хранится
/// в локальном хранилище браузера. Это чистое удобство: если хранилище
/// недоступно, сайдбар просто открыт по умолчанию, и ничего не ломается.
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedController, bool>(
      SidebarCollapsedController.new,
    );

/// Контроллер состояния сайдбара.
class SidebarCollapsedController extends Notifier<bool> {
  /// Ключ в локальном хранилище.
  static const storageKey = 'sl.sidebar.collapsed';

  @override
  bool build() {
    unawaited(_restore());

    return false;
  }

  /// Свернуть или развернуть сайдбар.
  ///
  /// Состояние меняется сразу, запись в хранилище — следом: пользователь
  /// не должен ждать диска ради анимации панели.
  Future<void> toggle() async {
    state = !state;
    await _write(state);
  }

  Future<void> _restore() async {
    final storage = _storage();
    if (storage == null) return;

    try {
      final stored = await storage.getBool(storageKey);
      if (stored != null) state = stored;
    } on Object {
      // Значение не прочиталось — остаёмся со значением по умолчанию.
    }
  }

  Future<void> _write(bool value) async {
    final storage = _storage();
    if (storage == null) return;

    try {
      await storage.setBool(storageKey, value);
    } on Object {
      // Не сохранилось — значит, выбор не переживёт перезагрузку. Это худшее,
      // что может случиться, и падать из-за этого нельзя.
    }
  }

  /// Хранилище, если оно вообще доступно.
  ///
  /// Конструктор [SharedPreferencesAsync] бросает, когда платформенной
  /// реализации нет: так бывает в виджет-тестах и в браузере с запретом
  /// на данные сайта. Ловим `Object`, а не `Exception`, потому что там
  /// именно [StateError] — `on Exception` его пропустит.
  SharedPreferencesAsync? _storage() {
    try {
      return SharedPreferencesAsync();
    } on Object {
      return null;
    }
  }
}
