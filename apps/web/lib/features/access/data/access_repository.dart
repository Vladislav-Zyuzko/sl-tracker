import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';

/// Список доступа к трекеру (ADR-0006).
///
/// Запись в списке даёт только вход в трекер и никаких прав внутри проектов.
class AccessRepository {
  /// @nodoc
  const AccessRepository(this._client);

  final AccessClient _client;

  /// Размер страницы.
  ///
  /// Курсорная пагинация: экран административный, но список может вырасти,
  /// и тянуть его целиком нельзя.
  static const pageSize = 50;

  /// Страница списка. [cursor] — значение `nextCursor` предыдущей страницы,
  /// [query] — поиск по подстроке в адресе и имени вошедшего.
  Future<AccessEntryListDto> list({String? cursor, String? query}) async {
    try {
      return await _client.accessControllerList(
        limit: pageSize,
        cursor: cursor,
        q: query == null || query.isEmpty ? null : query,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Добавляет адрес. Источник новой записи — `manual`.
  Future<AccessEntryDto> add(String email) async {
    try {
      return await _client.accessControllerAdd(
        body: CreateAccessEntryDto(email: email),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Выдаёт или снимает признак владельца трекера.
  Future<AccessEntryDto> setInstanceOwner(
    String id, {
    required bool value,
  }) async {
    try {
      return await _client.accessControllerUpdate(
        id: id,
        body: UpdateAccessEntryDto(isInstanceOwner: value),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Отзывает доступ. Возвращает число немедленно погашенных сессий (US-09).
  Future<int> revoke(String id) async {
    try {
      final result = await _client.accessControllerRemove(id: id);

      return result.revokedSessions.toInt();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final accessRepositoryProvider = Provider<AccessRepository>(
  (ref) => AccessRepository(ref.watch(apiClientProvider).access),
);
