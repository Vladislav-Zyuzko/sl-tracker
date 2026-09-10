import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранилище пользовательских предпочтений.
///
/// Здесь живёт только то, что можно потерять без последствий: свёрнут ли
/// сайдбар, выбранная тема. Ничего, что относится к сессии или к данным
/// трекера, сюда не попадает — сессия целиком на стороне сервера (ADR-0001).
///
/// Интерфейс, а не прямой вызов `shared_preferences`, нужен по двум причинам:
/// хранилища может не быть вообще (тесты, браузер с запретом на данные сайта),
/// и выбор темы надо уметь проверять тестом, не поднимая платформенный канал.
abstract interface class SLLocalStore {
  /// Читает строку. `null` — значения нет или прочитать не удалось.
  Future<String?> readString(String key);

  /// Пишет строку. Ошибка записи проглатывается: см. [SLBrowserStore].
  Future<void> writeString(String key, String value);

  /// Читает флаг. `null` — значения нет или прочитать не удалось.
  Future<bool?> readBool(String key);

  /// Пишет флаг.
  Future<void> writeBool(String key, {required bool value});
}

/// Хранилище браузера поверх `shared_preferences` (на вебе — `localStorage`).
///
/// Ни чтение, ни запись не бросают наружу. Не сохранилось — значит, выбор
/// не переживёт перезагрузку; это худшее, что может случиться, и падать
/// из-за этого приложение не должно.
class SLBrowserStore implements SLLocalStore {
  /// @nodoc
  const SLBrowserStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) async {
    try {
      return await _preferences.getString(key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _preferences.setString(key, value);
    } on Object {
      // Осознанно молча: потеря настройки не стоит поломанного экрана.
    }
  }

  @override
  Future<bool?> readBool(String key) async {
    try {
      return await _preferences.getBool(key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeBool(String key, {required bool value}) async {
    try {
      await _preferences.setBool(key, value);
    } on Object {
      // См. writeString.
    }
  }
}

/// Хранилища нет: читаем пустоту, запись уходит в никуда.
class SLAbsentStore implements SLLocalStore {
  /// @nodoc
  const SLAbsentStore();

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> writeString(String key, String value) async {}

  @override
  Future<bool?> readBool(String key) async => null;

  @override
  Future<void> writeBool(String key, {required bool value}) async {}
}

/// Создаёт хранилище, если платформа его вообще предоставляет.
///
/// Конструктор [SharedPreferencesAsync] бросает, когда платформенной
/// реализации нет: так бывает в виджет-тестах и в браузере с запретом
/// на данные сайта. Ловим `Object`, а не `Exception`, потому что там
/// именно [StateError] — `on Exception` его пропустит.
SLLocalStore createLocalStore() {
  try {
    return SLBrowserStore(SharedPreferencesAsync());
  } on Object {
    return const SLAbsentStore();
  }
}

/// Хранилище предпочтений.
///
/// В `main` подменяется на уже созданный экземпляр, чтобы стартовое чтение
/// темы и последующие записи шли через один и тот же объект.
final localStoreProvider = Provider<SLLocalStore>((ref) => createLocalStore());
