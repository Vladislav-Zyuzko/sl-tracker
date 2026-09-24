import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';

/// Персональные токены доступа (`SPEC-PAT-API.md`, §5).
///
/// Токен выпускается себе и даёт ровно права владельца. Секрет возвращается
/// **один раз** — в ответе на создание; в базе его нет, восстановить нельзя.
/// Поэтому репозиторий секрет только отдаёт наверх и нигде не сохраняет.
class TokensRepository {
  /// @nodoc
  const TokensRepository(this._client);

  final TokensClient _client;

  /// Список токенов, новые сверху.
  ///
  /// Что показывать, решает сервер: клиент не фильтрует у себя то, что мог
  /// не загрузить целиком. Пагинации в контракте нет (Q-D38).
  Future<TokenListDto> list({bool includeRevoked = false}) async {
    try {
      return await _client.tokensControllerList(includeRevoked: includeRevoked);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Выпускает токен и возвращает его секрет — единственный раз за всю жизнь
  /// токена.
  Future<IssuedTokenDto> create({
    required String name,
    required int expiresInDays,
  }) async {
    try {
      return await _client.tokensControllerCreate(
        body: CreateTokenDto(name: name, expiresInDays: expiresInDays),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Отзывает токен. Действует немедленно и необратимо.
  Future<void> revoke(String id) async {
    try {
      await _client.tokensControllerRevoke(id: id);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final tokensRepositoryProvider = Provider<TokensRepository>(
  (ref) => TokensRepository(ref.watch(apiClientProvider).tokens),
);
