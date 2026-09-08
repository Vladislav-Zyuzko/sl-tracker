import 'package:sl_tracker_web/core/utils/sl_plural.dart';

/// Ограничения полей проекта. Значения — из контракта API, а не из головы:
/// поле, которое клиент считает допустимым, а сервер нет, — это форма,
/// которая молча не отправляется.
sealed class ProjectLimits {
  /// Название: обязательное, 1–100 символов.
  static const nameMaxLength = 100;

  /// С какого символа показывается остаток. Раньше он только мешает:
  /// человек и так видит, что места хватает.
  static const nameCounterFrom = 80;

  /// Описание: Markdown до 5000 символов.
  static const descriptionMaxLength = 5000;

  /// Сколько символов осталось. Отрицательным не бывает: ввод обрезается
  /// самим полем.
  static int nameRemaining(String value) => nameMaxLength - value.length;

  /// Показывать ли счётчик остатка.
  static bool shouldCountName(String value) => value.length >= nameCounterFrom;

  /// «Осталось 7 символов».
  static String nameCounterText(String value) =>
      'Осталось ${SLPlural.characters(nameRemaining(value))}';
}
