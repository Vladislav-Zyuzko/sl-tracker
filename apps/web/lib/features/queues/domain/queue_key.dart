/// Ключ очереди (`DEV`, ADR-0004, D-06).
///
/// Правила повторяют серверные: 2–10 латинских букв и цифр, первый символ —
/// буква, регистр приводится к верхнему. Проверка на клиенте нужна, чтобы
/// человек узнал об опечатке до отправки формы, а не из ответа 400.
///
/// **Занятость ключа знает только сервер.** Ключ уникален на весь трекер,
/// а не внутри проекта, и ключи удалённых очередей остаются занятыми
/// навсегда (D-25) — поэтому 409 возможен на ключ, которого сейчас ни у кого
/// нет, и предсказать его клиент не может.
sealed class QueueKey {
  /// Минимальная длина.
  static const minLength = 2;

  /// Максимальная длина.
  static const maxLength = 10;

  /// Допустимый вид ключа.
  static final pattern = RegExp(r'^[A-Z][A-Z0-9]{1,9}$');

  /// Приводит ввод к виду ключа: верхний регистр, лишние символы отброшены.
  ///
  /// Человек печатает `dev-1`, в поле появляется `DEV1`. Обрезка по длине
  /// здесь же: поле не должно принимать то, что заведомо не пройдёт.
  static String normalize(String input) {
    final buffer = StringBuffer();

    for (final char in input.toUpperCase().split('')) {
      if (buffer.length >= maxLength) break;

      final isLetter = char.compareTo('A') >= 0 && char.compareTo('Z') <= 0;
      final isDigit = char.compareTo('0') >= 0 && char.compareTo('9') <= 0;

      // Первым символом цифра быть не может — она просто не попадает в ключ.
      if (isLetter || (isDigit && buffer.isNotEmpty)) buffer.write(char);
    }

    return buffer.toString();
  }

  /// Годится ли ключ для отправки на сервер.
  static bool isValid(String key) => pattern.hasMatch(key);

  /// Текст ошибки для поля ввода. `null` — ошибки нет.
  ///
  /// Пустое поле ошибкой не считается: кнопка отправки и так выключена,
  /// а подчёркивать поле, которое человек ещё не заполнял, незачем.
  static String? validationError(String key) {
    if (key.isEmpty) return null;
    if (key.length < minLength) {
      return 'Ключ короче $minLength символов';
    }
    if (!isValid(key)) {
      return 'Ключ — латинские буквы и цифры, первый символ буква';
    }

    return null;
  }
}
