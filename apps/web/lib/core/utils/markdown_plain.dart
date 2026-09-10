import 'package:sl_tracker_web/core/domain/mention_token.dart';

/// Снятие разметки Markdown для однострочных превью.
///
/// Это **не рендер**: `flutter_markdown_plus` здесь не нужен и был бы дорог —
/// в ленте уведомлений строка одна, высота фиксированная, и никакой разметки
/// в ней быть не может. Но и показывать `**жирный**` звёздочками нельзя
/// (US-102, `screens/notifications.md`): человек читает не исходник.
sealed class MarkdownPlain {
  /// Блок и инлайн-код: содержимое остаётся, обрамление уходит.
  static final _fence = RegExp(r'```[a-zA-Z0-9]*\n?');
  static final _inlineCode = RegExp('`+');

  /// Картинка: остаётся альтернативный текст, ссылка уходит.
  static final _image = RegExp(r'!\[([^\]\n]*)\]\([^)\n]*\)');

  /// Ссылка: остаётся подпись.
  static final _link = RegExp(r'\[([^\]\n]*)\]\([^)\n]*\)');

  /// Заголовок, цитата, маркер списка в начале строки.
  static final _blockMarker = RegExp(r'^\s{0,3}(?:#{1,6}\s+|>\s?|[-*+]\s+)');

  /// Нумерованный список: «1. » в начале строки.
  static final _orderedMarker = RegExp(r'^\s{0,3}\d{1,9}[.)]\s+');

  /// Чекбокс списка задач.
  static final _checkbox = RegExp(r'^\[[ xX]\]\s+');

  /// Подчёркивание, звёздочки и тильды выделения.
  ///
  /// Снимаются только парные обрамления вокруг непробельного текста: одиночная
  /// звёздочка в предложении — это звёздочка, а не сломанная разметка.
  static final _emphasis = RegExp(
    r'(\*\*\*|\*\*|\*|___|__|_|~~)(\S(?:.*?\S)?)\1',
  );

  /// Горизонтальная линия целой строкой.
  static final _rule = RegExp(r'^\s*(?:[-*_]\s*){3,}$');

  /// Любая последовательность пробелов и переводов строк.
  static final _whitespace = RegExp(r'\s+');

  /// Превращает Markdown в одну строку обычного текста.
  ///
  /// [limit] обрезает результат по границе слова и добавляет многоточие:
  /// сервер присылает около 100 символов, но разметка могла занимать часть
  /// из них, и после её снятия строка становится короче, а не длиннее.
  static String of(String source, {int? limit}) {
    var text = source.replaceAll(_fence, ' ');
    text = MentionToken.pattern.allMatches(text).isEmpty
        ? text
        : text.replaceAllMapped(
            MentionToken.pattern,
            (match) => '@${match.group(1) ?? ''}',
          );

    text = [
      for (final line in text.split('\n'))
        if (!_rule.hasMatch(line))
          line
              .replaceFirst(_blockMarker, '')
              .replaceFirst(_orderedMarker, '')
              .replaceFirst(_checkbox, ''),
    ].join(' ');

    text = text
        .replaceAllMapped(_image, (match) => match.group(1) ?? '')
        .replaceAllMapped(_link, (match) => match.group(1) ?? '')
        .replaceAll(_inlineCode, '');

    // Выделения снимаются в несколько проходов: `**_жирный курсив_**`
    // за один проход не разбирается, а вложенность в тексте встречается.
    for (var pass = 0; pass < _emphasisPasses; pass++) {
      final next = text.replaceAllMapped(
        _emphasis,
        (match) => match.group(2) ?? '',
      );
      if (next == text) break;

      text = next;
    }

    text = text.replaceAll(_whitespace, ' ').trim();

    return limit == null ? text : truncate(text, limit);
  }

  /// Обрезает строку по границе слова.
  static String truncate(String text, int limit) {
    if (text.length <= limit) return text;

    final cut = text.substring(0, limit);
    final lastSpace = cut.lastIndexOf(' ');

    return '${lastSpace > limit ~/ 2 ? cut.substring(0, lastSpace) : cut}…';
  }

  static const _emphasisPasses = 3;
}
