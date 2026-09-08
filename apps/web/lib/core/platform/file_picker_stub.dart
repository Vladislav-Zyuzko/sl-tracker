import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Реализация для платформ, где `<input type="file">` недоступен.
///
/// Осознанно падает, а не возвращает `null`: тихий отказ выглядел бы
/// как «пользователь передумал», и загрузка обложки на мобильном клиенте
/// молча перестала бы работать вместо того, чтобы сразу потребовать
/// платформенный пикер.
FilePicker createFilePicker() => const _UnsupportedFilePicker();

class _UnsupportedFilePicker implements FilePicker {
  const _UnsupportedFilePicker();

  @override
  Future<PickedFile?> pickOne({required String accept}) =>
      throw UnsupportedError(
        'Выбор файла реализован только для веба. '
        'Мобильному клиенту нужен системный пикер изображений.',
      );
}
