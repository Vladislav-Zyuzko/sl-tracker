import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/tokens/data/tokens_repository.dart';
import 'package:sl_tracker_web/features/tokens/presentation/token_secret_guard.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_screen.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/token_row.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_secret_field.dart';

import '../../helpers/fake_tokens_repository.dart';
import '../../helpers/pump_widget.dart';

/// Секрет, который «сервер» показывает единственный раз.
const secret = 'aa17f900-4e7b-4c2a-9d31-QmFzZTY0VmVyaWZpZXI';

/// Поднимает экран и открывает окно создания.
Future<ProviderContainer> pumpCreate(
  WidgetTester tester, {
  required FakeTokensRepository repository,
}) async {
  final container = await pumpWithProviders(
    tester,
    const Scaffold(body: TokensScreen()),
    overrides: [tokensRepositoryProvider.overrideWithValue(repository)],
  );

  await tester.pump();
  await tester.pump();
  await tester.tap(find.text('Создать токен').first);
  await tester.pumpAndSettle();

  return container;
}

/// Перехватывает обращения к буферу обмена.
///
/// Платформенного канала в тесте нет, поэтому без подмены `Clipboard`
/// падает — а нам важно проверить оба исхода: и успех, и отказ.
List<String> captureClipboard(WidgetTester tester, {required bool succeed}) {
  final copied = <String>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method != 'Clipboard.setData') return null;
      if (!succeed) throw PlatformException(code: 'not-allowed');

      copied.add((call.arguments as Map)['text'] as String);

      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  return copied;
}

void main() {
  group('создание токена', () {
    testWidgets('пустое название — не ошибка, а отключённая кнопка', (
      tester,
    ) async {
      await pumpCreate(tester, repository: FakeTokensRepository());

      final submit = tester.widget<SLButton>(
        find.widgetWithText(SLButton, 'Создать токен').last,
      );
      expect(submit.onPressed, isNull);
      // Пустая форма ничем не подсвечена: это исходное состояние.
      expect(find.text('Название не может быть пустым'), findsNothing);

      // Срок по умолчанию — 365 дней, и он назван датой, а не только числом.
      expect(find.text('365 дней'), findsOneWidget);
      expect(find.textContaining('Токен перестанет работать'), findsOneWidget);
      // Произвольного срока и «бессрочно» в интерфейсе нет.
      expect(find.textContaining('Бессрочно'), findsNothing);
    });

    testWidgets('секрет показан один раз, окно не закрылось', (tester) async {
      final repository = FakeTokensRepository();
      await pumpCreate(tester, repository: repository);

      await tester.enterText(find.byType(TextField), '  dsh-mcp  ');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      // Название обрезано по краям перед отправкой.
      expect(repository.tokens.first.name, 'dsh-mcp');
      expect(find.text('Токен «dsh-mcp» создан'), findsOneWidget);
      expect(find.byType(SLSecretField), findsOneWidget);
      expect(find.text(secret), findsOneWidget);
      // Ровно тот вид, в котором токен предъявляется API.
      expect(find.text('Authorization: Bearer <токен>'), findsOneWidget);
      // «Показать ещё раз» не существует: показывать нечего.
      expect(find.textContaining('ещё раз'), findsNothing);
      // Новая строка уже сверху списка — с тем же префиксом.
      expect(find.byType(TokenRow), findsOneWidget);
    });

    testWidgets('закрытие без копирования требует подтверждения', (
      tester,
    ) async {
      final container = await pumpCreate(
        tester,
        repository: FakeTokensRepository(),
      );

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      // Пока секрет на экране, уход с экрана перехватывается роутером.
      expect(container.read(tokenSecretGuardProvider), isTrue);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(find.text('Закрыть? Токен больше не показать'), findsOneWidget);

      await tester.tap(find.text('Вернуться'));
      await tester.pumpAndSettle();

      // Вернулись к секрету: он всё ещё на экране.
      expect(find.text(secret), findsOneWidget);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Всё равно закрыть'));
      await tester.pumpAndSettle();

      expect(find.byType(SLSecretField), findsNothing);
      expect(container.read(tokenSecretGuardProvider), isFalse);
    });

    testWidgets('после копирования «Готово» закрывает сразу', (tester) async {
      final copied = captureClipboard(tester, succeed: true);
      final container = await pumpCreate(
        tester,
        repository: FakeTokensRepository(),
      );

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SLButton, 'Скопировать'));
      await tester.pump();

      expect(copied, [secret]);
      expect(find.text('Скопировано'), findsOneWidget);
      // Копирование снимает перехват: спрашивать «вы скопировали?» после
      // нажатия «Скопировать» — недоверие к собственному интерфейсу.
      expect(container.read(tokenSecretGuardProvider), isFalse);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(find.byType(SLSecretField), findsNothing);
      expect(find.text('Закрыть? Токен больше не показать'), findsNothing);
    });

    testWidgets('отказ буфера обмена показывает ручной путь', (tester) async {
      captureClipboard(tester, succeed: false);
      await pumpCreate(tester, repository: FakeTokensRepository());

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SLButton, 'Скопировать'));
      await tester.pump();

      expect(find.text('Не удалось скопировать'), findsOneWidget);
      expect(
        find.textContaining('Выделите значение и скопируйте вручную'),
        findsOneWidget,
      );
      // Значение выделяемо — это и есть запасной путь.
      expect(find.byType(SelectableText), findsWidgets);
      expect(find.text('Скопировано'), findsNothing);
    });

    testWidgets('409: лимит объявлен в модалке, введённое цело', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        createFailure: const ApiFailure(
          kind: ApiFailureKind.conflict,
          code: 'token_limit_reached',
        ),
      );

      await pumpCreate(tester, repository: repository);

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      expect(find.text('Достигнут лимит токенов (20)'), findsOneWidget);
      // Название осталось в поле, поле осталось редактируемым.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'dsh-mcp',
      );
      expect(find.byType(SLSecretField), findsNothing);
    });

    testWidgets('429: просят подождать, а не «что-то пошло не так»', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        createFailure: const ApiFailure(
          kind: ApiFailureKind.unknown,
          statusCode: 429,
          code: 'rate_limited',
        ),
      );

      await pumpCreate(tester, repository: repository);

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      expect(find.text('Слишком много попыток'), findsOneWidget);
    });

    testWidgets('Esc на шаге с секретом идёт через подтверждение', (
      tester,
    ) async {
      await pumpCreate(tester, repository: FakeTokensRepository());

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();
      await tester.tap(find.widgetWithText(SLButton, 'Создать токен').last);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Окно с секретом на месте, поверх него — вопрос.
      expect(find.text('Закрыть? Токен больше не показать'), findsOneWidget);
      expect(find.text(secret), findsOneWidget);

      await tester.tap(find.text('Вернуться'));
      await tester.pumpAndSettle();

      expect(find.byType(SLSecretField), findsOneWidget);
    });

    testWidgets('совпадение имён — подсказка, а не запрет', (tester) async {
      await pumpCreate(
        tester,
        repository: FakeTokensRepository(
          tokens: [fakeToken(id: '1', name: 'dsh-mcp')],
        ),
      );

      await tester.enterText(find.byType(TextField), 'dsh-mcp');
      await tester.pump();

      expect(
        find.textContaining('в списке их будет не отличить'),
        findsOneWidget,
      );
      final submit = tester.widget<SLButton>(
        find.widgetWithText(SLButton, 'Создать токен').last,
      );
      expect(submit.onPressed, isNotNull);
    });
  });
}
