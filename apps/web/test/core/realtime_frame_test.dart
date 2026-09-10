import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';

void main() {
  group('разбор кадров живых обновлений', () {
    test('ready несёт темы, такт и предел', () {
      final frame = RealtimeFrame.decode(
        '{"type":"ready","topics":["user:me"],'
        '"heartbeatSeconds":30,"maxTopics":20}',
      ) as RealtimeReadyFrame;

      expect(frame.topics, ['user:me']);
      expect(frame.heartbeat, const Duration(seconds: 30));
      expect(frame.maxTopics, 20);
    });

    test('subscribed отдаёт канонический ярлык, а не отправленный', () {
      final frame = RealtimeFrame.decode(
        '{"type":"subscribed","id":"issue:dev-42",'
        '"topic":"issue:DEV-42"}',
      ) as RealtimeSubscribedFrame;

      expect(frame.id, 'issue:dev-42');
      expect(frame.topic, 'issue:DEV-42');
    });

    test('event разбирается вместе с полезной нагрузкой', () {
      final event = RealtimeFrame.decode(
        '{"type":"event","topic":"issue:DEV-42",'
        '"event":"issue.updated","at":"2026-09-09T10:15:30.412Z",'
        '"actorId":"user-1","data":{"key":"DEV-42",'
        '"changedFields":["status","title"]}}',
      ) as RealtimeEvent;

      expect(event.event, RealtimeEvents.issueUpdated);
      expect(event.changedFields, ['status', 'title']);
      expect(event.text('key'), 'DEV-42');
      expect(event.at?.toUtc().year, 2026);
      expect(event.isMine('user-1'), isTrue);
      expect(event.isMine('user-2'), isFalse);
      // Системное событие ничьё: сравнивать не с чем.
      expect(event.isMine(null), isFalse);
    });

    test('счётчик непрочитанных достаётся числом', () {
      final event = RealtimeFrame.decode(
        '{"type":"event","topic":"user:me",'
        '"event":"notification.created","at":"2026-09-09T10:15:30Z",'
        '"actorId":null,"data":{"id":"n1","type":"issue_mentioned",'
        '"unreadCount":3}}',
      ) as RealtimeEvent;

      expect(event.number('unreadCount'), 3);
      expect(event.actorId, isNull);
    });

    test('битый JSON и незнакомый тип не роняют клиент', () {
      expect(RealtimeFrame.decode('не json'), isA<RealtimeUnknownFrame>());
      expect(RealtimeFrame.decode('[]'), isA<RealtimeUnknownFrame>());
      expect(RealtimeFrame.decode('{"type":42}'), isA<RealtimeUnknownFrame>());
      expect(
        RealtimeFrame.decode('{"type":"whatever"}'),
        isA<RealtimeUnknownFrame>(),
      );
    });

    test('кадры без части полей не роняют разбор', () {
      final frame =
          RealtimeFrame.decode('{"type":"ready"}') as RealtimeReadyFrame;

      expect(frame.topics, isEmpty);
      expect(frame.heartbeat, const Duration(seconds: 30));

      final error = RealtimeFrame.decode(
        '{"type":"error","id":null}',
      ) as RealtimeErrorFrame;

      expect(error.code, 'unknown');
      expect(error.id, isNull);
    });
  });

  group('окончательные коды закрытия', () {
    test('4401 и 4403 останавливают переподключение, прочие — нет', () {
      expect(RealtimeCloseCodes.isFinal(4401), isTrue);
      expect(RealtimeCloseCodes.isFinal(4403), isTrue);
      expect(RealtimeCloseCodes.isFinal(4499), isFalse);
      expect(RealtimeCloseCodes.isFinal(1006), isFalse);
    });
  });

  group('адрес шлюза', () {
    test('схема страницы определяет схему сокета', () {
      expect(
        realtimeUrlOf('https://tracker.example.com'),
        'wss://tracker.example.com/api/ws',
      );
      expect(
        realtimeUrlOf('http://localhost:8081'),
        'ws://localhost:8081/api/ws',
      );
    });
  });

  group('ярлыки тем', () {
    test('собираются по правилам протокола', () {
      expect(RealtimeTopics.issue('DEV-42'), 'issue:DEV-42');
      expect(RealtimeTopics.project('sweet-limit'), 'project:sweet-limit');
      expect(RealtimeTopics.me, 'user:me');
    });
  });
}
