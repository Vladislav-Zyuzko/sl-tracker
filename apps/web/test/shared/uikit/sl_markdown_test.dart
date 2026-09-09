import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown_syntax.dart';

import '../../helpers/pump_widget.dart';

/// Собирает весь текст, который виджет реально показал на экране.
///
/// Проверять надо именно это: «HTML не исполняется» означает, что теги
/// видно как текст, а не что их нет в исходной строке.
String renderedText(WidgetTester tester) => [
  // Абзацы рендерятся `SelectableText`: в вебе текст обязан выделяться,
  // и рендерер это учитывает. Собираем оба вида.
  for (final widget in tester.widgetList<Text>(find.byType(Text)))
    widget.data ?? widget.textSpan?.toPlainText() ?? '',
  for (final widget in tester.widgetList<SelectableText>(
    find.byType(SelectableText),
  ))
    widget.data ?? widget.textSpan?.toPlainText() ?? '',
].join('\n');

void main() {
  group('безопасность рендера (D-22)', () {
    test('разрешены только http, https и mailto', () {
      expect(SLMarkdownSyntax.isSafeLink('https://example.com'), isTrue);
      expect(SLMarkdownSyntax.isSafeLink('http://example.com'), isTrue);
      expect(SLMarkdownSyntax.isSafeLink('mailto:anna@example.com'), isTrue);

      expect(SLMarkdownSyntax.isSafeLink('javascript:alert(1)'), isFalse);
      expect(SLMarkdownSyntax.isSafeLink('data:text/html,<b>'), isFalse);
      expect(SLMarkdownSyntax.isSafeLink('file:///etc/passwd'), isFalse);
      // Без схемы адрес не открывается: `//evil.example` — это внешний
      // адрес, маскирующийся под путь.
      expect(SLMarkdownSyntax.isSafeLink('//evil.example'), isFalse);
      expect(SLMarkdownSyntax.isSafeLink(''), isFalse);
      expect(SLMarkdownSyntax.isSafeLink(null), isFalse);
    });

    test('картинки — только http и https', () {
      expect(SLMarkdownSyntax.isSafeImage('https://cdn.example/a.png'), isTrue);
      expect(SLMarkdownSyntax.isSafeImage('data:image/png;base64,AA'), isFalse);
      expect(SLMarkdownSyntax.isSafeImage('mailto:anna@example.com'), isFalse);
    });

    test('в наборе синтаксисов нет разбора HTML', () {
      // Именно отсутствие `InlineHtmlSyntax` делает `<b>` текстом.
      expect(
        SLMarkdownSyntax.inlineSyntaxes
            .map((syntax) => syntax.runtimeType.toString())
            .join(','),
        isNot(contains('InlineHtml')),
      );
    });

    testWidgets('сырой HTML показывается как текст, а не как разметка', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 600,
          child: SLMarkdown(
            data: 'До <b>жирный</b> и <script>alert(1)</script> после',
          ),
        ),
      );

      final rendered = renderedText(tester);
      expect(rendered, contains('<b>'));
      expect(rendered, contains('<script>'));
    });

    testWidgets('ссылка с опасной схемой не становится кликабельной', (
      tester,
    ) async {
      final opened = <String>[];

      await pumpInTheme(
        tester,
        SizedBox(
          width: 600,
          child: SLMarkdown(
            data: '[нажми меня](javascript:alert(1))',
            onOpenLink: opened.add,
          ),
        ),
      );

      // Текст остался, а кликабельной ссылки нет: у настоящей ссылки
      // тултип с адресом, у текста — нет.
      expect(renderedText(tester), contains('нажми меня'));
      expect(find.byTooltip('javascript:alert(1)'), findsNothing);
      expect(opened, isEmpty);
    });

    testWidgets('обычная ссылка открывается', (tester) async {
      final opened = <String>[];

      await pumpInTheme(
        tester,
        SizedBox(
          width: 600,
          child: SLMarkdown(
            data: '[спека](https://example.com/spec)',
            onOpenLink: opened.add,
          ),
        ),
      );

      await tester.tap(find.byTooltip('https://example.com/spec'));
      await tester.pump();

      expect(opened, ['https://example.com/spec']);
    });
  });

  group('упоминания', () {
    testWidgets('имя берётся из mentions, а не из текста токена', (
      tester,
    ) async {
      const id = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';

      await pumpInTheme(
        tester,
        const SizedBox(
          width: 600,
          child: SLMarkdown(
            // В тексте старое имя — человек с тех пор переименовался.
            data: 'Привет, @[Аня Старое Имя](user:$id)!',
            mentions: [MentionRef(id: id, displayName: 'Анна Иванова')],
          ),
        ),
      );

      final rendered = renderedText(tester);
      expect(rendered, contains('@Анна Иванова'));
      expect(rendered, isNot(contains('Аня Старое Имя')));
    });

    testWidgets('нераспознанный токен остаётся обычным текстом', (
      tester,
    ) async {
      const id = '11111111-2222-3333-4444-555555555555';

      await pumpInTheme(
        tester,
        const SizedBox(
          width: 600,
          child: SLMarkdown(
            data: 'Привет, @[Посторонний](user:$id)!',
          ),
        ),
      );

      // Ни подсветки, ни «@Имя»: связи нет, уведомления не было.
      expect(renderedText(tester), contains('@[Посторонний](user:$id)'));
    });

    testWidgets('ключ задачи в тексте остаётся текстом (D-38)', (tester) async {
      final opened = <String>[];

      await pumpInTheme(
        tester,
        SizedBox(
          width: 600,
          child: SLMarkdown(
            data: 'Смотри DEV-42, там то же самое',
            onOpenLink: opened.add,
          ),
        ),
      );

      expect(renderedText(tester), contains('DEV-42'));
      expect(opened, isEmpty);
    });
  });

  group('токен упоминания', () {
    test('собирается и разбирается', () {
      const id = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';
      final token = MentionToken.format(id: id, displayName: 'Анна Иванова');

      expect(token, '@[Анна Иванова](user:$id)');

      final match = MentionToken.pattern.firstMatch(token);
      expect(match?.group(1), 'Анна Иванова');
      expect(match?.group(2), id);
    });

    test('скобки в имени не ломают разбор', () {
      final token = MentionToken.format(
        id: '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0',
        displayName: 'Анна [Иванова]',
      );

      expect(MentionToken.pattern.hasMatch(token), isTrue);
    });

    test('в простой текст подставляются актуальные имена', () {
      const id = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0';

      expect(
        MentionToken.toPlainText(
          'Привет, @[Старое](user:$id)!',
          names: {id: 'Анна Иванова'},
        ),
        'Привет, @Анна Иванова!',
      );
    });

    test('незнакомый токен в простом тексте остаётся как есть', () {
      const body = 'Привет, @[Кто-то](user:11111111-2222-3333-4444-555555555555)!';

      expect(MentionToken.toPlainText(body), body);
    });
  });
}
