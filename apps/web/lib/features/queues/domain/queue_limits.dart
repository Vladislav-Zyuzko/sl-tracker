import 'package:sl_tracker_web/core/utils/sl_plural.dart';

/// Ограничения полей очереди и задачи. Значения — из контракта API, а не
/// из головы: поле, которое клиент считает допустимым, а сервер нет, — это
/// форма, которая молча не отправляется.
sealed class QueueLimits {
  /// Название очереди: обязательное, 1–100 символов.
  static const nameMaxLength = 100;

  /// Описание очереди: Markdown до 1000 символов.
  static const descriptionMaxLength = 1000;

  /// Тема задачи: обязательная, 1–255 символов.
  static const issueTitleMaxLength = 255;

  /// Описание задачи: Markdown до 100 000 символов.
  static const issueDescriptionMaxLength = 100000;

  /// С какого символа показывается остаток. Раньше он только мешает.
  static const counterFrom = 0.8;

  /// Показывать ли счётчик остатка для значения длиной [maxLength].
  static bool shouldCount(String value, int maxLength) =>
      value.length >= maxLength * counterFrom;

  /// «Осталось 7 символов».
  static String counterText(String value, int maxLength) =>
      'Осталось ${SLPlural.characters(maxLength - value.length)}';
}
