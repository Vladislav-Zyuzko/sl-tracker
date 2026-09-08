import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Почему обложка не подходит.
enum ProjectCoverProblem {
  /// Не PNG, JPEG или WEBP.
  unsupportedType,

  /// Больше 5 МБ.
  tooLarge,
}

/// Ограничения обложки проекта (US-12).
///
/// Проверка на клиенте — вежливость, а не защита: сервер определяет тип
/// по содержимому файла, а не по расширению и не по заголовку, и откажет
/// независимо (`cover_unsupported_type`, `cover_too_large`). Смысл проверки
/// здесь — не гонять пять мегабайт по сети, чтобы узнать очевидное.
sealed class ProjectCover {
  /// Предел размера — тот же, что на сервере.
  static const maxBytes = 5 * 1024 * 1024;

  /// Что принимает сервер.
  static const allowedTypes = <String>['image/png', 'image/jpeg', 'image/webp'];

  /// Значение для атрибута `accept` системного диалога.
  static const acceptAttribute = 'image/png,image/jpeg,image/webp';

  /// Ограничения словами. Написаны рядом с кнопкой **до** выбора файла,
  /// а не в сообщении об ошибке после (`screens/project.md`).
  static const limitsHint = 'PNG, JPEG или WEBP, до 5 МБ';

  /// Что не так с файлом. `null` — файл годится.
  static ProjectCoverProblem? problemOf(PickedFile file) {
    if (file.size > maxBytes) return ProjectCoverProblem.tooLarge;

    // Пустой тип означает, что браузер его не распознал: пропускаем дальше
    // и оставляем решение серверу, который смотрит на содержимое.
    if (file.mimeType.isNotEmpty && !allowedTypes.contains(file.mimeType)) {
      return ProjectCoverProblem.unsupportedType;
    }

    return null;
  }

  /// Размер человеческими словами: «4,2 МБ».
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} КБ';

    final megabytes = bytes / (1024 * 1024);

    return '${megabytes.toStringAsFixed(1).replaceAll('.', ',')} МБ';
  }
}
