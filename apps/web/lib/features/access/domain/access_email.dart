/// Правила адреса в списке доступа (ADR-0006, п. 1).
///
/// Регулярное выражение и предел длины **дословно совпадают** с серверными
/// (`apps/api/src/common/email.ts`): расхождение проверок вредно — клиент
/// либо не пустит верный адрес, либо отправит заведомо негодный и получит
/// 400 `invalid_email` там, где мог сказать сразу.
sealed class AccessEmail {
  /// Предельная длина: ограничение колонки `varchar(320)`.
  static const maxLength = 320;

  static final _pattern = RegExp(
    r'^[^\s@,;<>"]+@[^\s@,;<>".]+(\.[^\s@,;<>".]+)+$',
  );

  /// Приводит адрес к хранимому виду.
  ///
  /// Сравнение без учёта регистра: `Ivan@Yandex.ru` и `ivan@yandex.ru` —
  /// один адрес. Приведение показывается в поле сразу, чтобы это
  /// не было сюрпризом.
  static String normalize(String raw) => raw.trim().toLowerCase();

  /// Годится ли адрес. Проверяется уже нормализованное значение.
  static bool isValid(String value) =>
      value.isNotEmpty && value.length <= maxLength && _pattern.hasMatch(value);
}
