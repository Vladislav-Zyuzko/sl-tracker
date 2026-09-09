import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/platform/file_drop.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Реализация для веба на событиях документа.
FileDropTarget createFileDropTarget() => const _WebFileDropTarget();

class _WebFileDropTarget implements FileDropTarget {
  const _WebFileDropTarget();

  @override
  VoidCallback attach({
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<List<PickedFile>> onFiles,
  }) {
    // Счётчик, а не флаг: `dragenter` и `dragleave` приходят на каждый узел
    // под курсором, и по одному `dragleave` рамка мигала бы на каждой границе
    // внутри окна.
    var depth = 0;

    void setHover(bool value) => onHoverChanged(value);

    final onDragEnter = ((web.Event event) {
      if (!_carriesFiles(event)) return;

      event.preventDefault();
      depth++;
      if (depth == 1) setHover(true);
    }).toJS;

    // Без `preventDefault` на `dragover` события `drop` не будет вовсе:
    // браузер считает, что зона сброса не принимает файл.
    final onDragOver = ((web.Event event) {
      if (!_carriesFiles(event)) return;

      event.preventDefault();
    }).toJS;

    final onDragLeave = ((web.Event event) {
      if (depth == 0) return;

      depth--;
      if (depth == 0) setHover(false);
    }).toJS;

    final onDrop = ((web.Event event) {
      if (!_carriesFiles(event)) return;

      // Без этого браузер откроет файл вместо приложения и выгрузит страницу
      // вместе с несохранённым комментарием.
      event.preventDefault();
      depth = 0;
      setHover(false);

      unawaited(
        _read(event as web.DragEvent).then((files) {
          if (files.isNotEmpty) onFiles(files);
        }),
      );
    }).toJS;

    web.document
      ..addEventListener('dragenter', onDragEnter)
      ..addEventListener('dragover', onDragOver)
      ..addEventListener('dragleave', onDragLeave)
      ..addEventListener('drop', onDrop);

    return () {
      web.document
        ..removeEventListener('dragenter', onDragEnter)
        ..removeEventListener('dragover', onDragOver)
        ..removeEventListener('dragleave', onDragLeave)
        ..removeEventListener('drop', onDrop);
    };
  }

  /// Тянут ли файлы, а не выделенный текст со страницы.
  ///
  /// Текст, перетаскиваемый внутри поля ввода, тоже поднимает `dragover`,
  /// и перехватывать его нельзя: это сломало бы обычное редактирование.
  static bool _carriesFiles(web.Event event) {
    // `is` для interop-типов бесполезен — он всегда истинен и настоящий тип
    // не проверяет; спрашиваем сам рантайм браузера.
    if (!event.isA<web.DragEvent>()) return false;

    final types = (event as web.DragEvent).dataTransfer?.types;
    if (types == null) return false;

    for (var i = 0; i < types.length; i++) {
      if (types.toDart[i].toDart == 'Files') return true;
    }

    return false;
  }

  static Future<List<PickedFile>> _read(web.DragEvent event) async {
    final files = event.dataTransfer?.files;
    if (files == null) return const [];

    final result = <PickedFile>[];
    for (var i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null) continue;

      final buffer = await file.arrayBuffer().toDart;
      result.add(
        PickedFile(
          name: file.name,
          mimeType: file.type,
          bytes: buffer.toDart.asUint8List(),
        ),
      );
    }

    return result;
  }
}
