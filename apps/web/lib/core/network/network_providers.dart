import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/network/sl_dio.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';

/// HTTP-клиент приложения.
///
/// Один экземпляр на всё приложение. Репозитории берут его отсюда и больше
/// нигде `Dio` не создают: иначе адаптер с `withCredentials` окажется
/// не у всех запросов, и часть из них молча пойдёт без cookie.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    onUnauthorized: () => ref.read(sessionControllerProvider.notifier).expire(),
  );

  ref.onDispose(dio.close);

  return dio;
});
