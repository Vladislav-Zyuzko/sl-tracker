import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Реализация для веба через скрытый `<input type="file">`.
///
/// Внешний пакет ради этого не подключается: `file_selector` и `image_picker`
/// тянут в бандл плагинную обвязку всех платформ ради двадцати строк
/// интеропа, а размер бандла в вебе — первое, что чувствует пользователь.
FilePicker createFilePicker() => const _WebFilePicker();

class _WebFilePicker implements FilePicker {
  const _WebFilePicker();

  @override
  Future<PickedFile?> pickOne({required String accept}) {
    final completer = Completer<PickedFile?>();
    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = accept
      ..multiple = false;

    // Элемент вставляется в документ: часть браузеров игнорирует `click()`
    // на элементе вне дерева. Убирается сразу после выбора.
    input.style.display = 'none';
    web.document.body?.appendChild(input);

    void finish(PickedFile? file) {
      if (input.isConnected) input.remove();
      if (!completer.isCompleted) completer.complete(file);
    }

    input.addEventListener(
      'change',
      ((web.Event _) {
        unawaited(_read(input).then(finish, onError: completer.completeError));
      }).toJS,
    );

    // Без этого обещание не выполнилось бы никогда, если человек закрыл
    // системный диалог: события `change` в этом случае не происходит.
    input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);

    input.click();

    return completer.future;
  }

  Future<PickedFile?> _read(web.HTMLInputElement input) async {
    final files = input.files;
    if (files == null || files.length == 0) return null;

    final file = files.item(0);
    if (file == null) return null;

    final buffer = await file.arrayBuffer().toDart;

    return PickedFile(
      name: file.name,
      mimeType: file.type,
      bytes: buffer.toDart.asUint8List(),
    );
  }
}
