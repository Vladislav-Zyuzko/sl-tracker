import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/features/access/presentation/access_denied_screen.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

void main() {
  group('экран «доступ закрыт»', () {
    testWidgets('адрес берётся обменом тикета, а не из адресной строки', (
      tester,
    ) async {
      final repository = FakeAuthRepository(email: 'ivan@yandex.ru');

      await pumpWithProviders(
        tester,
        const AccessDeniedScreen(ticket: 'one-time-ticket'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pump();

      expect(find.text('Доступ к трекеру закрыт'), findsOneWidget);
      expect(find.text('ivan@yandex.ru'), findsOneWidget);
      expect(repository.ticketCalls, 1);
    });

    testWidgets('протухший тикет — штатная ситуация, а не ошибка', (
      tester,
    ) async {
      // Так выглядит перезагрузка страницы: тикет живёт 60 секунд
      // и обменивается ровно один раз, повторный обмен — 404.
      final repository = FakeAuthRepository();

      await pumpWithProviders(
        tester,
        const AccessDeniedScreen(ticket: 'used-ticket'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pump();

      expect(find.text('Доступ к трекеру закрыт'), findsOneWidget);
      expect(
        find.text('Этот аккаунт не входит в число тех, кому открыт доступ.'),
        findsOneWidget,
      );
      // Ни ошибки, ни пустого места вместо адреса.
      expect(find.textContaining('Не удалось'), findsNothing);
      expect(find.text('Вы вошли как'), findsNothing);
    });

    testWidgets('без тикета к серверу не ходим вовсе', (tester) async {
      final repository = FakeAuthRepository(email: 'ivan@yandex.ru');

      await pumpWithProviders(
        tester,
        const AccessDeniedScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pump();

      expect(repository.ticketCalls, 0);
      expect(find.text('Доступ к трекеру закрыт'), findsOneWidget);
    });

    testWidgets('перерисовка экрана второй раз тикет не тратит', (
      tester,
    ) async {
      final repository = FakeAuthRepository(email: 'ivan@yandex.ru');

      await pumpWithProviders(
        tester,
        const AccessDeniedScreen(ticket: 'one-time-ticket'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pump();
      // Смена размера окна — самый дешёвый способ вызвать перестроение.
      tester.view.physicalSize = const Size(900, 700);
      await tester.pump();

      expect(repository.ticketCalls, 1);
    });

    testWidgets('на экране нет ничего, кроме способов уйти', (tester) async {
      await pumpWithProviders(
        tester,
        const AccessDeniedScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      await tester.pump();

      expect(find.text('Выйти'), findsOneWidget);
      expect(find.text('Войти другим аккаунтом'), findsOneWidget);
      // Ни имени инстанса, ни контактов, ни подсказки, есть ли адрес
      // в списке доступа.
      expect(find.textContaining('администратор'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });
  });
}
