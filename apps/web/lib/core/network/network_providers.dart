import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/sl_dio.dart';
import 'package:sl_tracker_web/core/network/unauthorized_notifier.dart';

/// HTTP-клиент приложения.
///
/// Один экземпляр на всё приложение. Репозитории берут его отсюда и больше
/// нигде `Dio` не создают: иначе адаптер с `withCredentials` окажется
/// не у всех запросов, и часть из них молча пойдёт без cookie.
final dioProvider = Provider<Dio>((ref) {
  final unauthorized = ref.watch(unauthorizedNotifierProvider);
  final dio = createDio(onUnauthorized: unauthorized.fire);

  ref.onDispose(dio.close);

  return dio;
});

/// Сгенерированный из `docs/api/openapi.json` клиент API.
///
/// Руками DTO и запросы не пишутся: контракт — единственный источник правды
/// (CLAUDE.md, п. 9). Перегенерация описана в `swagger_parser.yaml`.
final apiClientProvider = Provider<SlApiClient>(
  (ref) => SlApiClient(ref.watch(dioProvider)),
);
