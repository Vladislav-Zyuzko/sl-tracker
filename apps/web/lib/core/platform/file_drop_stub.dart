import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/platform/file_drop.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Реализация для платформ без DOM.
///
/// Молча ничего не делает, и это правильно: перетаскивание файлов из ОС —
/// приём десктопного браузера, на телефоне его не существует. Падать здесь
/// нельзя — экран задачи обязан работать и без него.
FileDropTarget createFileDropTarget() => const _UnsupportedFileDropTarget();

class _UnsupportedFileDropTarget implements FileDropTarget {
  const _UnsupportedFileDropTarget();

  @override
  VoidCallback attach({
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<List<PickedFile>> onFiles,
  }) => () {};
}
