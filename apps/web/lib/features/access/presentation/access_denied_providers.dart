import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';

/// Адрес, под которым человек вошёл, по одноразовому тикету.
///
/// Тикет живёт 60 секунд и обменивается **ровно один раз**: повторный
/// обмен — 404. Поэтому провайдер намеренно не `autoDispose` — результат
/// обмена переживает перестроение экрана, и второй попытки не будет.
///
/// `null` в результате — это не сбой, а штатная ситуация: перезагрузка
/// страницы, возврат по истории, минута раздумий. Экран тогда показывает
/// текст без адреса.
final accessDeniedEmailProvider = FutureProvider.family<String?, String>(
  (ref, ticket) => ref.watch(authRepositoryProvider).accessDeniedEmail(ticket),
  // Автоповтора нет: тикет одноразовый, вторая попытка всё равно вернёт 404,
  // а экран обязан работать и без адреса.
  retry: (_, _) => null,
);
