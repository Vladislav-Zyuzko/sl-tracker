import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/storage/local_store.dart';

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
    // В отличие от темы, восстанавливается уже после первого кадра: панель
    // схлопывается без перекраски всего экрана, и лишний кадр тут не виден.
    unawaited(_restore());

    return false;
  }

  /// Свернуть или развернуть сайдбар.
  ///
  /// Состояние меняется сразу, запись в хранилище — следом: пользователь
  /// не должен ждать диска ради анимации панели.
  Future<void> toggle() async {
    state = !state;
    await ref.read(localStoreProvider).writeBool(storageKey, value: state);
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).readBool(storageKey);
    // Между запросом и ответом хранилища провайдер мог уйти: присваивание
    // состояния после этого бросает.
    if (stored != null && ref.mounted) state = stored;
  }
}
