import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/platform/file_drop_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/platform/file_drop_web.dart'
    as impl;
import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Перетаскивание файлов из проводника в окно приложения (US-46).
///
/// Встроенного механизма во Flutter Web нет: `Draggable` и `DragTarget`
/// работают только внутри приложения и о файлах операционной системы ничего
/// не знают (`components.md`, 22). Внешний пакет ради этого не подключается —
/// у нас уже есть `package:web` и заведённый образец платформенного
/// интерфейса ([FilePicker]), а всё нужное — это четыре события документа.
///
/// Подписка **глобальная**, на документ, а не на область виджета: Flutter
/// рисует в холст, DOM-узла под правой колонкой задачи не существует, и
/// повесить `dragover` «на блок вложений» физически некуда. Экран задачи —
/// единственный, кто принимает файлы, поэтому одного слушателя достаточно;
/// пока он не подписан, браузер ведёт себя как обычно.
///
/// Без `preventDefault` браузер открыл бы брошенный файл вместо приложения
/// и выгрузил бы страницу — поэтому подписка отменяет поведение по умолчанию
/// на всё время своей жизни.
abstract interface class FileDropTarget {
  /// Подписывается на перетаскивание. Возвращает функцию отписки.
  ///
  /// [onHoverChanged] сообщает, находится ли перетаскиваемое над окном:
  /// по нему рисуется пунктирная рамка зоны сброса.
  /// [onFiles] получает уже прочитанные файлы.
  VoidCallback attach({
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<List<PickedFile>> onFiles,
  });
}

/// Платформенная реализация [FileDropTarget].
///
/// Подменяется в тестах: тестовому рендереру событий браузера взять негде.
final fileDropTargetProvider = Provider<FileDropTarget>(
  (ref) => impl.createFileDropTarget(),
);
