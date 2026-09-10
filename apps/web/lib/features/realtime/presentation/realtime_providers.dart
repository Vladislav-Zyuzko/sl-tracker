import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/network/unauthorized_notifier.dart';
import 'package:sl_tracker_web/core/realtime/realtime_client.dart';
import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/core/realtime/realtime_socket.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';

/// Клиент живых обновлений.
///
/// Один на всё приложение: несколько вкладок — обычное дело, несколько
/// сокетов в одной вкладке — нет. Сам по себе он ничего не открывает,
/// соединением управляет [realtimeStatusProvider].
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    socketFactory: ref.watch(realtimeSocketFactoryProvider),
    url: ref.watch(realtimeUrlProvider),
    // `4401` и `4403`: сессии больше нет. Приложение реагирует на это ровно
    // так же, как на 401 от любого запроса, — тем же сигналом, а не своим
    // отдельным путём.
    onSessionLost: ref.read(unauthorizedNotifierProvider).fire,
    // Рукопожатие не проходит подряд: в браузере отказ без сессии выглядит
    // как обрыв сети, и различить их можно только обычным запросом.
    onHandshakeSuspect: () =>
        unawaited(ref.read(sessionControllerProvider.notifier).load()),
  );

  ref.onDispose(client.dispose);

  return client;
});

/// Состояние соединения живых обновлений.
///
/// Оболочка приложения смотрит сюда ради полосы офлайна, а сам провайдер
/// держит соединение открытым, пока есть сессия.
final realtimeStatusProvider =
    NotifierProvider<RealtimeLinkController, RealtimeStatus>(
      RealtimeLinkController.new,
    );

/// Связывает жизнь соединения с жизнью сессии.
class RealtimeLinkController extends Notifier<RealtimeStatus> {
  @override
  RealtimeStatus build() {
    final client = ref.watch(realtimeClientProvider);
    final authenticated = ref.watch(
      sessionControllerProvider.select((session) => session.isAuthenticated),
    );

    void onStatusChanged() {
      if (ref.mounted) state = client.status.value;
    }

    client.status.addListener(onStatusChanged);
    ref.onDispose(() => client.status.removeListener(onStatusChanged));

    // Не синхронно: `start` меняет состояние клиента сразу, а писать
    // в `state` до конца `build` нельзя.
    scheduleMicrotask(() {
      if (!ref.mounted) return;

      if (authenticated) {
        client.start();
      } else {
        // Выход закрывает сокет немедленно, не дожидаясь, пока сервер
        // заметит погашенную сессию.
        client.stop();
      }
    });

    return client.status.value;
  }
}

/// Подписывает провайдер на тему живых обновлений на время его жизни.
///
/// Вызывается из `build` провайдера, который владеет данными экрана: тогда
/// подписка живёт ровно столько, сколько живёт экран, — ушли, и `unsubscribe`
/// уехал на сервер сам. Предел тем на соединение 20, и «протекшая» подписка
/// съедала бы его молча.
///
/// Подписка **прямая**, а не через `StreamProvider`: провайдер-обёртка над
/// потоком не доносит события до слушателя-провайдера — проверено тестом,
/// а не предположением. Лишний слой здесь всё равно ничего не давал.
///
/// В [onSignal] приходят не только события: [RealtimeResync] после
/// восстановления связи обязывает перечитать данные экрана,
/// [RealtimeTopicLost] — перечитать и показать то, что вернёт сервер
/// (для чужого проекта это 404).
void listenRealtimeTopic(
  Ref ref,
  String topic,
  void Function(RealtimeSignal signal) onSignal,
) {
  // Соединение должно быть поднято, даже если полосу офлайна никто
  // не показывает. Провайдер связи живёт до конца работы приложения,
  // поэтому достаточно его создать.
  ref.read(realtimeStatusProvider);

  final subscription = ref
      .read(realtimeClientProvider)
      .signals(topic)
      .listen(onSignal);

  ref.onDispose(subscription.cancel);
}
