import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/realtime/realtime_client.dart';
import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';

import '../helpers/fake_realtime.dart';

/// Собирает клиент на подставном транспорте.
({
  RealtimeClient client,
  FakeRealtimeSocketFactory factory,
  List<String> lostSessions,
  List<int> sessionChecks,
})
buildClient({int handshakeFailures = 0}) {
  final factory = FakeRealtimeSocketFactory(
    handshakeFailures: handshakeFailures,
  );
  final lost = <String>[];
  final checks = <int>[];

  final client = RealtimeClient(
    socketFactory: factory,
    url: 'ws://localhost/api/ws',
    onSessionLost: () => lost.add('lost'),
    onHandshakeSuspect: () => checks.add(1),
  );

  addTearDown(client.dispose);

  return (
    client: client,
    factory: factory,
    lostSessions: lost,
    sessionChecks: checks,
  );
}

void main() {
  group('клиент живых обновлений', () {
    test('подписка уходит после ready и снимается после отмены', () async {
      final setup = buildClient();
      final signals = <RealtimeSignal>[];

      setup.client.start();
      await Future<void>.delayed(Duration.zero);

      final subscription = setup.client
          .signals(RealtimeTopics.issue('DEV-42'))
          .listen(signals.add);
      addTearDown(subscription.cancel);

      final socket = setup.factory.last;
      socket.emitReady();
      await Future<void>.delayed(Duration.zero);

      expect(socket.commands('subscribe').single['topic'], 'issue:DEV-42');

      socket.emitSubscribed(id: 'issue:DEV-42', topic: 'issue:DEV-42');
      await Future<void>.delayed(Duration.zero);

      // Первая подписка не требует перечитывания: экран только что загрузил
      // данные сам.
      expect(signals, isEmpty);

      await subscription.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(
        setup.factory.last.commands('unsubscribe').single['topic'],
        'issue:DEV-42',
      );
    });

    test('на `user:me` подписывает сервер, команду клиент не шлёт', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);

      final subscription = setup.client
          .signals(RealtimeTopics.me)
          .listen((_) {});
      addTearDown(subscription.cancel);

      final socket = setup.factory.last;
      socket.emitReady();
      await Future<void>.delayed(Duration.zero);

      expect(socket.commands('subscribe'), isEmpty);
    });

    test(
      'события сопоставляются по каноническому ярлыку, а не по своему',
      () async {
        final setup = buildClient();
        final events = <RealtimeEvent>[];

        setup.client.start();
        await Future<void>.delayed(Duration.zero);

        // Подписываемся строчными буквами и старым именем проекта — сервер
        // ответит каноническими ярлыками, и сравнивать надо с ними.
        final issue = setup.client.signals('issue:dev-42').listen((signal) {
          if (signal is RealtimeEvent) events.add(signal);
        });
        final project = setup.client.signals('project:old-name').listen((
          signal,
        ) {
          if (signal is RealtimeEvent) events.add(signal);
        });
        addTearDown(issue.cancel);
        addTearDown(project.cancel);

        final socket = setup.factory.last;
        socket.emitReady();
        await Future<void>.delayed(Duration.zero);

        socket
          ..emitSubscribed(id: 'issue:dev-42', topic: 'issue:DEV-42')
          ..emitSubscribed(id: 'project:old-name', topic: 'project:new-name');
        await Future<void>.delayed(Duration.zero);

        socket
          ..emitEvent(
            topic: 'issue:DEV-42',
            event: RealtimeEvents.commentCreated,
            data: {'id': 'c1', 'issueKey': 'DEV-42'},
          )
          ..emitEvent(
            topic: 'project:new-name',
            event: RealtimeEvents.memberJoined,
            data: {'userId': 'u1', 'role': 'member'},
          );
        await Future<void>.delayed(Duration.zero);

        expect(events.map((event) => event.event), [
          RealtimeEvents.commentCreated,
          RealtimeEvents.memberJoined,
        ]);
      },
    );

    test(
      'после переподключения подписки восстановлены и просят перечитать',
      () async {
        final setup = buildClient();
        final signals = <RealtimeSignal>[];

        setup.client.start();
        await Future<void>.delayed(Duration.zero);

        final subscription = setup.client
            .signals(RealtimeTopics.issue('DEV-42'))
            .listen(signals.add);
        addTearDown(subscription.cancel);

        final first = setup.factory.last;
        first
          ..emitReady()
          ..emitSubscribed(id: 'issue:DEV-42', topic: 'issue:DEV-42');
        await Future<void>.delayed(Duration.zero);

        // Обрыв сети: сокет закрылся кодом 1006.
        first.emitClose(1006);
        await Future<void>.delayed(Duration.zero);

        expect(setup.client.status.value, RealtimeStatus.offline);

        // Ждём задержку переподключения (1 с плюс случайная добавка).
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        expect(setup.factory.attempts, 2);

        final second = setup.factory.last;
        second
          ..emitReady()
          ..emitSubscribed(id: 'issue:DEV-42', topic: 'issue:DEV-42');
        await Future<void>.delayed(Duration.zero);

        expect(setup.client.status.value, RealtimeStatus.online);
        // За время обрыва события потеряны: экран обязан перечитать данные.
        expect(signals.single, isA<RealtimeResync>());
      },
    );

    test('4401 останавливает цикл и сообщает о потере сессии', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);
      setup.factory.last.emitReady();
      await Future<void>.delayed(Duration.zero);

      setup.factory.last.emitClose(4401);
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(setup.client.status.value, RealtimeStatus.stopped);
      expect(setup.lostSessions, hasLength(1));
      // Ни одной новой попытки: сервер не молотим.
      expect(setup.factory.attempts, 1);
    });

    test('4403 тоже окончателен', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);
      setup.factory.last.emitReady();
      await Future<void>.delayed(Duration.zero);

      setup.factory.last.emitClose(4403);
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(setup.client.status.value, RealtimeStatus.stopped);
      expect(setup.factory.attempts, 1);
    });

    test('4499 — обычный обрыв: переподключаемся', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);
      setup.factory.last.emitReady();
      await Future<void>.delayed(Duration.zero);

      setup.factory.last.emitClose(4499);
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(setup.factory.attempts, 2);
      expect(setup.lostSessions, isEmpty);
    });

    test('после трёх неудачных рукопожатий проверяем сессию', () async {
      final setup = buildClient(handshakeFailures: 3);

      setup.client.start();
      // 1-я попытка сразу, дальше — с задержкой 1 и 2 секунды плюс добавка.
      await Future<void>.delayed(const Duration(milliseconds: 5200));

      expect(setup.sessionChecks, hasLength(1));
      expect(setup.factory.attempts, greaterThanOrEqualTo(3));
    });

    test(
      'отказ в теме просит перечитать её, соединение остаётся живым',
      () async {
        final setup = buildClient();
        final signals = <RealtimeSignal>[];

        setup.client.start();
        await Future<void>.delayed(Duration.zero);

        final subscription = setup.client
            .signals(RealtimeTopics.issue('DEV-42'))
            .listen(signals.add);
        addTearDown(subscription.cancel);

        final socket = setup.factory.last;
        socket.emitReady();
        await Future<void>.delayed(Duration.zero);

        socket.emit({
          'type': 'error',
          'id': 'issue:DEV-42',
          'code': 'topic_forbidden',
          'message': 'Тема недоступна',
        });
        await Future<void>.delayed(Duration.zero);

        expect(signals.single, isA<RealtimeTopicLost>());
        expect(setup.client.status.value, RealtimeStatus.online);
      },
    );

    test(
      'снятие подписки сервером без ярлыка темы просит перечитать все',
      () async {
        final setup = buildClient();
        final issueSignals = <RealtimeSignal>[];
        final meSignals = <RealtimeSignal>[];

        setup.client.start();
        await Future<void>.delayed(Duration.zero);

        final issue = setup.client
            .signals(RealtimeTopics.issue('DEV-42'))
            .listen(issueSignals.add);
        final me = setup.client
            .signals(RealtimeTopics.me)
            .listen(meSignals.add);
        addTearDown(issue.cancel);
        addTearDown(me.cancel);

        final socket = setup.factory.last;
        socket.emitReady();
        await Future<void>.delayed(Duration.zero);
        socket.emitSubscribed(id: 'issue:DEV-42', topic: 'issue:DEV-42');
        await Future<void>.delayed(Duration.zero);

        socket.emit({
          'type': 'error',
          'id': null,
          'code': 'topic_forbidden',
          'message': 'Тема недоступна',
        });
        await Future<void>.delayed(Duration.zero);

        expect(issueSignals.single, isA<RealtimeTopicLost>());
        // Свою тему отобрать нельзя — её не трогаем.
        expect(meSignals, isEmpty);
      },
    );

    test('выход закрывает сокет и не переподключается', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);
      setup.factory.last.emitReady();
      await Future<void>.delayed(Duration.zero);

      setup.client.stop();
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(setup.factory.last.closedByClient, isTrue);
      expect(setup.client.status.value, RealtimeStatus.idle);
      expect(setup.factory.attempts, 1);
    });

    test('молчащий сервер обнаруживается прикладным ping', () async {
      final setup = buildClient();

      setup.client.start();
      await Future<void>.delayed(Duration.zero);

      final socket = setup.factory.last;
      // Такт в одну секунду: ждать штатные 30 в тесте бессмысленно.
      socket.emitReady(heartbeatSeconds: 1);
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(socket.commands('ping'), hasLength(1));

      // Ответа нет: клиент считает соединение мёртвым и переподключается.
      // Ждать приходится по-настоящему: полтакта на ответ плюс задержка
      // переподключения со случайной добавкой.
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect(setup.factory.attempts, 2);
    });
  });
}
