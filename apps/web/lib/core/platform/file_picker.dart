import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/platform/file_picker_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/platform/file_picker_web.dart'
    as impl;

/// Файл, выбранный человеком в системном диалоге.
@immutable
class PickedFile {
  /// @nodoc
  const PickedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  /// Имя файла как его видел пользователь. Нужно только для сообщений:
  /// имя объекта в хранилище генерирует сервер.
  final String name;

  /// Тип, о котором сообщил браузер. Ему нельзя доверять — сервер определяет
  /// тип по содержимому, — но для быстрой проверки до загрузки годится.
  final String mimeType;

  /// Содержимое.
  final Uint8List bytes;

  /// Размер в байтах.
  int get size => bytes.length;
}

/// Выбор файла на диске.
///
/// Спрятан за интерфейсом по той же причине, что и [BrowserNavigator]:
/// `<input type="file">` — это веб, а доменный код и репозитории про веб
/// знать не должны. На мобильном клиенте здесь будет системный пикер.
abstract interface class FilePicker {
  /// Открывает системный диалог и ждёт выбора одного файла.
  ///
  /// [accept] — список MIME-типов через запятую (`image/png,image/jpeg`).
  /// Возвращает `null`, если человек закрыл диалог, ничего не выбрав.
  ///
  /// Фильтр в диалоге — удобство, а не проверка: пользователь может выбрать
  /// «все файлы», поэтому вызывающий обязан проверить тип и размер сам.
  Future<PickedFile?> pickOne({required String accept});
}

/// Платформенная реализация [FilePicker].
///
/// Подменяется в тестах: тестовому рендереру системный диалог не открыть.
final filePickerProvider = Provider<FilePicker>(
  (ref) => impl.createFilePicker(),
);
