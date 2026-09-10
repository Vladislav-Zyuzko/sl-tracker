import 'package:sl_tracker_web/core/storage/local_store.dart';

/// Хранилище в памяти.
///
/// Переживает «перезапуск» приложения в тесте ровно так же, как localStorage
/// переживает F5: контейнер провайдеров создаётся заново, а объект хранилища
/// остаётся тот же.
class FakeLocalStore implements SLLocalStore {
  /// @nodoc
  FakeLocalStore({Map<String, Object>? initial})
    : values = {...?initial};

  /// Содержимое хранилища. Тест смотрит сюда, чтобы убедиться, что запись
  /// действительно была, а не только состояние поменялось.
  final Map<String, Object> values;

  /// Хранилище отвалилось: чтение отдаёт пустоту, запись ничего не делает.
  ///
  /// Так ведёт себя браузер с запретом на данные сайта.
  var broken = false;

  /// Сколько раз писали.
  var writes = 0;

  @override
  Future<String?> readString(String key) async =>
      broken ? null : values[key] as String?;

  @override
  Future<void> writeString(String key, String value) async {
    writes++;
    if (broken) return;
    values[key] = value;
  }

  @override
  Future<bool?> readBool(String key) async =>
      broken ? null : values[key] as bool?;

  @override
  Future<void> writeBool(String key, {required bool value}) async {
    writes++;
    if (broken) return;
    values[key] = value;
  }
}
