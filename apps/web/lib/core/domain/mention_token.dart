import 'package:flutter/foundation.dart';

/// Упомянутый человек: то, чем упоминание рисуется на экране.
///
/// Отдельный тип, а не `IssueUserDto`, потому что упоминания рендерит виджет
/// дизайн-системы, а он про контракт API знать не должен.
@immutable
class MentionRef {
  /// @nodoc
  const MentionRef({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  /// Идентификатор пользователя — он же то, что стоит в токене.
  final String id;

  /// **Актуальное** имя: человек мог сменить его в Яндекс ID уже после того,
  /// как комментарий написали (US-74).
  final String displayName;

  /// @nodoc
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionRef &&
          other.id == id &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, displayName, avatarUrl);
}

/// Токен упоминания в тексте: `@[Имя](user:<uuid>)`.
///
/// Источник правды — **идентификатор**, имя внутри токена запасное
/// (US-74, D-41). Отсюда два правила рендера:
///
/// 1. Имя берётся из поля `mentions` ответа, а не из текста: тогда смена
///    имени видна во всех старых комментариях сразу.
/// 2. Токен, которому в `mentions` ничего не соответствует, показывается
///    **обычным текстом** — это упоминание постороннего, сервер его молча
///    проигнорировал, и притворяться, что связь есть, нельзя.
sealed class MentionToken {
  /// Разметка токена.
  ///
  /// Имя не содержит `]` — так его вставляет подсказка, и так его разбирает
  /// сервер. Идентификатор — UUID, без строгой проверки версии: клиент
  /// проверяет форму, а существование — сервер.
  static final pattern = RegExp(
    r'@\[([^\]\n]*)\]\(user:([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
    r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\)',
  );

  /// Собирает токен для вставки в текст.
  ///
  /// Имя чистится от символов, которые сломали бы разбор: остальное — как
  /// его прислала подсказка.
  static String format({required String id, required String displayName}) {
    final safeName = displayName.replaceAll(RegExp(r'[\[\]\n]'), ' ').trim();

    return '@[$safeName](user:$id)';
  }

  /// Заменяет токены на «@Имя» — для мест, где разметки нет вовсе:
  /// доступное имя, черновик в свёрнутом поле, заголовок уведомления.
  ///
  /// [names] — актуальные имена по идентификаторам. Незнакомый токен
  /// остаётся как есть: он и должен читаться как обычный текст.
  static String toPlainText(
    String body, {
    Map<String, String> names = const {},
  }) => body.replaceAllMapped(pattern, (match) {
    final id = match.group(2)!;
    final actual = names[id];

    return actual == null ? match.group(0)! : '@$actual';
  });
}
