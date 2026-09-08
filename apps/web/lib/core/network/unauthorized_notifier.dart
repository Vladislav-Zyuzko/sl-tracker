import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сигнал «сервер ответил 401».
///
/// Существует как отдельная сущность, чтобы разорвать круг зависимостей:
/// HTTP-клиенту нужно кого-то оповестить о потере сессии, а состоянию сессии
/// нужен HTTP-клиент, чтобы сходить за `GET /api/me`. Оба зависят от этого
/// объекта, и ни один — друг от друга.
class UnauthorizedNotifier extends ChangeNotifier {
  /// Сообщает подписчикам, что сессии больше нет.
  void fire() => notifyListeners();
}

/// Провайдер сигнала. Ни от чего не зависит — это важно, см. [UnauthorizedNotifier].
final unauthorizedNotifierProvider = Provider<UnauthorizedNotifier>((ref) {
  final notifier = UnauthorizedNotifier();
  ref.onDispose(notifier.dispose);

  return notifier;
});
