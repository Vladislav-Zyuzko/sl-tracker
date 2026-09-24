import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/tokens/data/tokens_repository.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_providers.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_screen.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/token_row.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_record_state_badge.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';

import '../../helpers/fake_tokens_repository.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран токенов с подставным репозиторием.
Future<ProviderContainer> pumpTokens(
  WidgetTester tester, {
  required FakeTokensRepository repository,
  Size windowSize = const Size(1280, 800),
}) async {
  final container = await pumpWithProviders(
    tester,
    // В приложении экран живёт внутри оболочки с её `Scaffold`;
    // в тесте эту роль играет обычный `Scaffold`.
    const Scaffold(body: TokensScreen()),
    overrides: [tokensRepositoryProvider.overrideWithValue(repository)],
    windowSize: windowSize,
  );

  await tester.pump();
  await tester.pump();

  return container;
}

void main() {
  group('экран токенов', () {
    testWidgets('счётчик считает действующие, а не строки', (tester) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(
          tokens: [
            fakeToken(id: '1', name: 'dsh-mcp'),
            fakeToken(id: '2', name: 'ноутбук'),
            // Истёкший в выдаче остаётся, но в лимит не входит — именно
            // поэтому `total` из ответа для счётчика не годится.
            fakeToken(
              id: '3',
              name: 'старый скрипт',
              expiresAt: DateTime(2026, 2, 1),
            ),
          ],
        ),
      );

      expect(find.text('Активных: 2 из 20'), findsOneWidget);
      expect(find.byType(TokenRow), findsNWidgets(3));
    });

    testWidgets('отозванные по умолчанию скрыты, переключатель их показывает', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        tokens: [
          fakeToken(id: '1', name: 'dsh-mcp'),
          fakeToken(
            id: '2',
            name: 'ci-runner',
            revokedAt: DateTime(2026, 3, 3, 14, 32),
          ),
        ],
      );

      final container = await pumpTokens(tester, repository: repository);

      expect(repository.listCalls, [false]);
      expect(find.text('ci-runner'), findsNothing);

      await tester.tap(find.byType(SLSwitch));
      await tester.pump();
      await tester.pump();

      expect(container.read(tokensIncludeRevokedProvider), isTrue);
      // Фильтрует сервер, а не клиент: уходит второй запрос.
      expect(repository.listCalls, [false, true]);
      expect(find.text('ci-runner'), findsOneWidget);
      // У отозванного кнопки нет — вместо неё плашка.
      expect(find.byType(SLRecordStateBadge), findsOneWidget);
      expect(find.text('Отозван'), findsOneWidget);
    });

    testWidgets('лимит объявлен баннером, кнопка остаётся активной', (
      tester,
    ) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(
          tokens: [
            for (var index = 0; index < 20; index++)
              fakeToken(id: 'token-$index', name: 'агент $index'),
          ],
        ),
      );

      expect(find.text('Достигнут лимит токенов (20)'), findsOneWidget);
      expect(find.text('Активных: 20 из 20'), findsOneWidget);
      // Кнопку в шапке не отключаем и не прячем: объяснение уже есть
      // в баннере, а отключённая кнопка молчит.
      final create = tester.widget<SLButton>(
        find.widgetWithText(SLButton, 'Создать токен'),
      );
      expect(create.onPressed, isNotNull);
    });

    testWidgets('пусто: тулбар и заголовки колонок скрыты', (tester) async {
      await pumpTokens(tester, repository: FakeTokensRepository());

      expect(find.text('Токенов пока нет'), findsOneWidget);
      expect(find.text('Активных: 0 из 20'), findsNothing);
      expect(find.text('ИСПОЛЬЗОВАН'), findsNothing);
      expect(find.textContaining('не чаще раза в сутки'), findsNothing);
    });

    testWidgets('все токены отозваны: это пусто после фильтра, а не пустота', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        tokens: [fakeToken(id: '1', revokedAt: DateTime(2026, 3, 3, 14, 32))],
      );

      await pumpTokens(tester, repository: repository);

      expect(find.text('Действующих токенов нет'), findsOneWidget);
      // Тулбар остаётся: включить историю — это и есть выход отсюда.
      expect(find.byType(SLSwitch), findsOneWidget);

      await tester.tap(find.text('Показать отозванные').last);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TokenRow), findsOneWidget);
    });

    testWidgets('ошибка загрузки: состояние ошибки с кнопкой «Повторить»', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        listFailure: const ApiFailure(kind: ApiFailureKind.network),
      );

      await pumpTokens(tester, repository: repository);

      expect(find.text('Не удалось загрузить токены'), findsOneWidget);
      expect(find.text('ИСПОЛЬЗОВАН'), findsNothing);

      repository
        ..listFailure = null
        ..tokens = [fakeToken()];

      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TokenRow), findsOneWidget);
    });

    testWidgets('403 не предлагает повтор: повтор не поможет', (tester) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(
          listFailure: const ApiFailure(
            kind: ApiFailureKind.forbidden,
            code: 'pat_cannot_manage_tokens',
          ),
        ),
      );

      expect(
        find.text('Управление токенами доступно только из веб-интерфейса'),
        findsOneWidget,
      );
      expect(find.text('Повторить'), findsNothing);
      expect(find.text('На главную'), findsOneWidget);
    });

    testWidgets('отзыв: строка уходит только после ответа сервера', (
      tester,
    ) async {
      final repository = FakeTokensRepository(
        tokens: [
          fakeToken(id: '1', name: 'dsh-mcp'),
          fakeToken(id: '2', name: 'ноутбук'),
        ],
      );

      await pumpTokens(tester, repository: repository);

      await tester.tap(find.text('Отозвать').first);
      await tester.pumpAndSettle();

      expect(find.text('Отозвать токен «dsh-mcp»?'), findsOneWidget);
      expect(find.textContaining('потеряют доступ немедленно'), findsOneWidget);
      // Пока подтверждение не нажато, строка на месте.
      expect(repository.revokedIds, isEmpty);

      await tester.tap(find.text('Отозвать токен'));
      await tester.pumpAndSettle();

      expect(repository.revokedIds, ['1']);
      expect(find.text('dsh-mcp'), findsNothing);
      expect(find.text('Активных: 1 из 20'), findsOneWidget);
    });

    testWidgets('у истёкшего токена текст подтверждения другой', (
      tester,
    ) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(
          tokens: [fakeToken(id: '1', expiresAt: DateTime(2026, 2, 1))],
        ),
      );

      await tester.tap(find.text('Отозвать'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('токен уже истёк и не работает'),
        findsOneWidget,
      );
      expect(find.textContaining('потеряют доступ немедленно'), findsNothing);
    });

    testWidgets('на sm список — карточки фиксированной высоты 100', (
      tester,
    ) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(tokens: [fakeToken()]),
        windowSize: const Size(400, 800),
      );

      final list = tester.widget<ListView>(find.byType(ListView));

      expect(list.itemExtent, TokenRow.compactHeight);
      // Заголовки колонок на телефоне скрыты.
      expect(find.text('ПРЕФИКС'), findsNothing);
    });

    testWidgets('на lg список виртуализирован с шагом 44', (tester) async {
      await pumpTokens(
        tester,
        repository: FakeTokensRepository(tokens: [fakeToken()]),
      );

      final list = tester.widget<ListView>(find.byType(ListView));

      expect(list.itemExtent, TokenRow.height);
      expect(find.text('ИСПОЛЬЗОВАН'), findsOneWidget);
      expect(
        find.textContaining('обновляется не чаще раза в сутки'),
        findsOneWidget,
      );
    });
  });
}
