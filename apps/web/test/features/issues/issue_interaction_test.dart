import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comment_item.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/mention_field.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/pump_widget.dart';
import 'issue_screen_test.dart';

/// Поле упоминаний в тех же условиях, что и на экране: небольшой ширины
/// и прижатое к верху, чтобы подсказка под ним помещалась в окно.
Widget _mentionHarness(TextEditingController controller) => Material(
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 400,
      child: SLMentionField(
        controller: controller,
        issueKey: 'DEV-42',
        maxLines: 4,
      ),
    ),
  ),
);

/// Досматривает кэш подсказки до конца.
///
/// Провайдер держит ответ 30 секунд, чтобы перебор букв не собирал 429.
/// Тест обязан дождаться этого таймера, иначе уходит с висящим таймером.
Future<void> drainMentionCache(WidgetTester tester) =>
    tester.pump(IssueMembersController.cacheFor + const Duration(seconds: 1));

void main() {
  group('производительность ленты', () {
    testWidgets('триста комментариев не строятся все сразу', (tester) async {
      final world = IssueWorld(
        comments: [
          for (var i = 0; i < 300; i++)
            fakeComment(id: 'c$i', body: 'Комментарий номер $i'),
        ],
      );

      await pumpIssue(tester, world);

      final built = tester.widgetList<CommentItem>(find.byType(CommentItem));

      // Виртуализация: на экран помещается несколько десятков, а не 300.
      // Порог выбран с большим запасом — тест ловит именно отказ
      // от виртуализации, а не колебания раскладки.
      expect(built.length, lessThan(60));
      expect(built, isNotEmpty);
    });
  });

  group('клавиатура', () {
    testWidgets('`y` копирует ключ задачи', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpIssue(tester, IssueWorld());

      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.pumpAndSettle();

      expect(copied, ['DEV-42']);
    });

    testWidgets('`e` открывает редактор описания', (tester) async {
      await pumpIssue(
        tester,
        IssueWorld(issue: fakeIssue(description: 'Текст описания')),
      );

      expect(find.text('Написать'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();

      // Редактор — это вкладки «Написать / Просмотр» и подсказка о хоткее.
      expect(find.text('Написать'), findsOneWidget);
      expect(find.text('Просмотр'), findsOneWidget);
      expect(find.text('Ctrl+Enter — сохранить'), findsOneWidget);
    });

    testWidgets('буква в тексте остаётся буквой, а не хоткеем', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpIssue(tester, IssueWorld());

      // `m` разворачивает поле комментария и ставит в него фокус.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();
      expect(find.text('Ctrl+Enter — отправить'), findsOneWidget);

      // Теперь `y` — это буква «y» в комментарии, а не «скопировать ключ»,
      // и `e` не открывает редактор описания поверх набранного текста.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();

      expect(copied, isEmpty);
      expect(find.text('Ctrl+Enter — сохранить'), findsNothing);
    });
  });

  group('якорь на комментарий', () {
    testWidgets('комментарий из адреса подсвечивается', (tester) async {
      final world = IssueWorld(
        comments: [
          fakeComment(id: 'c1', body: 'Первый'),
          fakeComment(id: 'c2', body: 'Нужный'),
        ],
      );

      await pumpIssue(tester, world, anchorCommentId: 'c2');

      final highlighted = tester
          .widgetList<CommentItem>(find.byType(CommentItem))
          .where((item) => item.highlighted)
          .toList();

      expect(highlighted, hasLength(1));
      expect(highlighted.single.comment.id, 'c2');

      // Подсветка гаснет сама через 1200 мс — таймер надо дождаться,
      // иначе тест уходит с висящим таймером.
      await tester.pump(CommentItem.highlightDuration);
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<CommentItem>(find.byType(CommentItem))
            .where((item) => item.highlighted),
        isEmpty,
      );
    });

    testWidgets('переход к удалённому комментарию объясняется тостом', (
      tester,
    ) async {
      final world = IssueWorld(
        comments: [fakeComment(id: 'c1', body: 'Единственный')],
      );

      final container = await pumpIssue(
        tester,
        world,
        anchorCommentId: 'уже-удалён',
      );

      final toasts = container.read(toastControllerProvider);
      expect(toasts, hasLength(1));
      expect(toasts.single.message, 'Комментарий удалён');
      expect(toasts.single.variant, SLToastVariant.info);
    });
  });

  group('подсказка упоминаний', () {
    testWidgets('`@` открывает подсказку и вставляет токен', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final world = IssueWorld();
      world.mentions.items = [fakeSuggestion(displayName: 'Анна Иванова')];

      await pumpWithProviders(
        tester,
        _mentionHarness(controller),
        overrides: world.overrides,
      );

      await tester.enterText(find.byType(TextField), 'Посмотри, @ан');
      // Подсказка ждёт паузы: маршрут ограничен по частоте, и слать запрос
      // на каждую букву нельзя.
      await tester.pump(SLMentionField.debounce);
      await tester.pumpAndSettle();

      expect(find.text('Анна Иванова'), findsOneWidget);
      // Запрос ушёл на сервер, а не отфильтровался на клиенте.
      expect(world.mentions.queries, contains('ан'));

      await tester.tap(find.text('Анна Иванова'));
      await tester.pumpAndSettle();

      expect(controller.text, contains('@[Анна Иванова](user:'));
      expect(MentionToken.pattern.hasMatch(controller.text), isTrue);

      await drainMentionCache(tester);
    });

    testWidgets('Esc закрывает подсказку, а `@` остаётся символом', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final world = IssueWorld();
      world.mentions.items = [fakeSuggestion(displayName: 'Анна Иванова')];

      await pumpWithProviders(
        tester,
        _mentionHarness(controller),
        overrides: world.overrides,
      );

      await tester.enterText(find.byType(TextField), 'почта @ан');
      await tester.pump(SLMentionField.debounce);
      await tester.pumpAndSettle();
      expect(find.text('Анна Иванова'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Анна Иванова'), findsNothing);
      expect(controller.text, 'почта @ан');

      await drainMentionCache(tester);
    });

    testWidgets('«собака» внутри слова подсказку не открывает', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final world = IssueWorld();
      world.mentions.items = [fakeSuggestion(displayName: 'Анна Иванова')];

      await pumpWithProviders(
        tester,
        _mentionHarness(controller),
        overrides: world.overrides,
      );

      await tester.enterText(find.byType(TextField), 'anna@example');
      await tester.pump(SLMentionField.debounce);
      await tester.pumpAndSettle();

      expect(find.text('Анна Иванова'), findsNothing);
      expect(world.mentions.queries, isEmpty);
    });
  });
}
