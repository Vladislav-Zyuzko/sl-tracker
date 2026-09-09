import 'package:markdown/markdown.dart' as md;

import 'package:sl_tracker_web/core/domain/mention_token.dart';

/// Набор синтаксисов Markdown, разрешённых в трекере.
///
/// Собран вручную, а не взят как `ExtensionSet.gitHubFlavored`, и это
/// **защита, а не оформление** (D-22, `screens/issue.md`). Сервер разметку
/// не санитизирует: `IssueDto.description` и `CommentDto.body` приходят как
/// есть, и решение о том, что считать разметкой, целиком на клиенте.
///
/// Отличие от готового набора ровно одно и оно принципиальное: здесь **нет**
/// `InlineHtmlSyntax`. С ним `<b>текст</b>` стал бы узлом разметки; без него
/// он остаётся обычным текстом и показывается как написан. Сырой HTML
/// в трекере не разметка, а текст — и точка.
///
/// `HtmlBlockSyntax` включён в стандартный набор блоков самого пакета
/// `markdown` и отключить его нельзя, не потеряв абзацы и списки заодно.
/// Опасности в нём нет: он отдаёт содержимое узлом `md.Text`, а
/// `flutter_markdown_plus` рисует такой узел обычным `TextSpan` — исполнить
/// его во Flutter нечем, HTML-движка здесь не существует.
sealed class SLMarkdownSyntax {
  /// Тег элемента упоминания в дереве разбора.
  static const mentionTag = 'sl-mention';

  /// Атрибут с идентификатором упомянутого.
  static const mentionIdAttribute = 'sl-user-id';

  /// Атрибут с именем из самого токена — запасной вариант, если человека
  /// нет в списке `mentions`.
  static const mentionNameAttribute = 'sl-name';

  /// Разрешённые схемы ссылок (US-43).
  ///
  /// Всё остальное — `javascript:`, `data:`, `file:`, самодельные схемы —
  /// кликабельным не становится и остаётся текстом.
  static const safeSchemes = {'http', 'https', 'mailto'};

  /// Разрешено ли открывать этот адрес.
  ///
  /// Относительный адрес без схемы разрешённым не считается: в описании
  /// задачи ему взяться неоткуда, а `//evil.example` — это внешний адрес,
  /// маскирующийся под путь.
  static bool isSafeLink(String? href) {
    if (href == null || href.isEmpty) return false;

    final uri = Uri.tryParse(href.trim());
    if (uri == null || !uri.hasScheme) return false;

    return safeSchemes.contains(uri.scheme.toLowerCase());
  }

  /// Можно ли показывать картинку с этого адреса.
  ///
  /// `mailto:` из [safeSchemes] сюда не годится, а подписанные ссылки
  /// вложений — обычный `https`.
  static bool isSafeImage(String? src) {
    if (src == null || src.isEmpty) return false;

    final uri = Uri.tryParse(src.trim());
    if (uri == null || !uri.hasScheme) return false;

    final scheme = uri.scheme.toLowerCase();

    return scheme == 'http' || scheme == 'https';
  }

  /// Блочные синтаксисы: код в тройных кавычках, таблицы и списки-чекбоксы.
  static final blockSyntaxes = <md.BlockSyntax>[
    const md.FencedCodeBlockSyntax(),
    const md.TableSyntax(),
    const md.UnorderedListWithCheckboxSyntax(),
    const md.OrderedListWithCheckboxSyntax(),
  ];

  /// Строчные синтаксисы. Упоминание идёт первым: иначе `@[Имя](user:…)`
  /// разобралось бы обычной ссылкой со схемой `user:`, которую мы всё равно
  /// не пускаем.
  static final inlineSyntaxes = <md.InlineSyntax>[
    SLMentionSyntax(),
    md.StrikethroughSyntax(),
    md.AutolinkExtensionSyntax(),
  ];

  /// Набор для `flutter_markdown_plus`.
  ///
  /// Пересобирается каждый раз новым объектом? Нет — синтаксисы без
  /// состояния между разборами, и один общий набор экономит аллокации
  /// на каждом комментарии ленты.
  static final extensionSet = md.ExtensionSet(blockSyntaxes, inlineSyntaxes);
}

/// Разбирает `@[Имя](user:<uuid>)` в отдельный узел дерева.
///
/// Без него токен распался бы на символ `@` и ссылку со схемой `user:` —
/// то есть на что-то, что рендерер обязан не делать кликабельным, и смысл
/// упоминания потерялся бы.
class SLMentionSyntax extends md.InlineSyntax {
  /// @nodoc
  SLMentionSyntax() : super(MentionToken.pattern.pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.empty(SLMarkdownSyntax.mentionTag)
        ..attributes[SLMarkdownSyntax.mentionNameAttribute] = match[1] ?? ''
        ..attributes[SLMarkdownSyntax.mentionIdAttribute] = match[2] ?? '',
    );

    return true;
  }
}
