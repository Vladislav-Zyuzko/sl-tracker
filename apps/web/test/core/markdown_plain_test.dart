import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/utils/markdown_plain.dart';

void main() {
  group('снятие разметки для превью', () {
    test('выделения показываются текстом, а не звёздочками (US-102)', () {
      expect(MarkdownPlain.of('**жирный** и _курсив_'), 'жирный и курсив');
      expect(MarkdownPlain.of('***оба сразу***'), 'оба сразу');
      expect(MarkdownPlain.of('~~зачёркнуто~~'), 'зачёркнуто');
      expect(MarkdownPlain.of('**_жирный курсив_**'), 'жирный курсив');
    });

    test('одиночная звёздочка остаётся звёздочкой', () {
      expect(MarkdownPlain.of('2 * 3 = 6'), '2 * 3 = 6');
    });

    test('ссылка превращается в свою подпись', () {
      expect(
        MarkdownPlain.of('см. [спеку](https://example.com/spec)'),
        'см. спеку',
      );
      expect(
        MarkdownPlain.of('![схема](https://example.com/a.png) готова'),
        'схема готова',
      );
    });

    test('код остаётся содержимым без обрамления', () {
      expect(MarkdownPlain.of('вызови `build()`'), 'вызови build()');
      expect(
        MarkdownPlain.of('```dart\nfinal a = 1;\n```'),
        'final a = 1;',
      );
    });

    test('заголовки, цитаты и списки теряют маркеры', () {
      expect(MarkdownPlain.of('## Заголовок'), 'Заголовок');
      expect(MarkdownPlain.of('> цитата'), 'цитата');
      expect(MarkdownPlain.of('- пункт\n- второй'), 'пункт второй');
      expect(MarkdownPlain.of('1. первый\n2. второй'), 'первый второй');
      expect(MarkdownPlain.of('- [ ] сделать'), 'сделать');
      expect(MarkdownPlain.of('текст\n\n---\n\nдальше'), 'текст дальше');
    });

    test('упоминание токеном превращается в имя', () {
      expect(
        MarkdownPlain.of(
          'привет, @[Анна Иванова]'
          '(user:0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0)!',
        ),
        'привет, @Анна Иванова!',
      );
    });

    test('перевод строки не разрывает однострочное превью', () {
      expect(MarkdownPlain.of('первая\nвторая\n\nтретья'),
          'первая вторая третья');
    });

    test('обрезка идёт по границе слова', () {
      final text = MarkdownPlain.of(
        'Очень длинное описание проблемы, которое не помещается в строку '
        'ленты уведомлений целиком',
        limit: 30,
      );

      expect(text.length, lessThanOrEqualTo(31));
      expect(text, endsWith('…'));
      expect(text, startsWith('Очень длинное описание'));
    });

    test('пустая строка остаётся пустой', () {
      expect(MarkdownPlain.of(''), '');
      expect(MarkdownPlain.of('   \n  '), '');
    });

    test('строка из 300 символов без пробелов не ломает обрезку', () {
      final long = 'а' * 300;
      final text = MarkdownPlain.of(long, limit: 100);

      expect(text.length, 101);
      expect(text, endsWith('…'));
    });
  });
}
