import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/tokens/data/tokens_repository.dart';

/// Токен для тестов.
///
/// По умолчанию — действующий и ни разу не использованный: `lastSeenAt`
/// равен `createdAt`, ровно как это отдаёт сервер.
TokenDto fakeToken({
  String id = 'token-1',
  String name = 'dsh-mcp',
  String prefix = '3f9a1c22',
  DateTime? createdAt,
  DateTime? lastSeenAt,
  DateTime? expiresAt,
  DateTime? revokedAt,
}) {
  final created = createdAt ?? DateTime(2026, 2, 12, 10, 30);

  return TokenDto(
    id: id,
    name: name,
    prefix: prefix,
    purpose: TokenDtoPurpose.pat,
    createdAt: created,
    lastSeenAt: lastSeenAt ?? created,
    expiresAt: expiresAt ?? created.add(const Duration(days: 365)),
    revokedAt: revokedAt,
  );
}

/// Подставной репозиторий токенов доступа.
///
/// Реализация через `implements`: настоящий репозиторий — тонкая обёртка
/// над сгенерированным клиентом.
class FakeTokensRepository implements TokensRepository {
  /// @nodoc
  FakeTokensRepository({
    List<TokenDto>? tokens,
    this.listFailure,
    this.createFailure,
    this.revokeFailure,
    this.issued,
  }) : tokens = tokens ?? [];

  /// Все токены человека, включая отозванные.
  List<TokenDto> tokens;

  /// Чем упадёт загрузка списка.
  ApiFailure? listFailure;

  /// Чем упадёт выпуск.
  ApiFailure? createFailure;

  /// Чем упадёт отзыв.
  ApiFailure? revokeFailure;

  /// Что вернёт выпуск токена. `null` — ответ собирается на лету.
  IssuedTokenDto? issued;

  /// С какими значениями `includeRevoked` приходили запросы списка.
  final listCalls = <bool>[];

  /// Идентификаторы отозванных токенов.
  final revokedIds = <String>[];

  /// Когда «сервер» отметил отзыв.
  DateTime revokedAt = DateTime(2026, 3, 3, 14, 32);

  @override
  Future<TokenListDto> list({bool includeRevoked = false}) async {
    listCalls.add(includeRevoked);
    final failure = listFailure;
    if (failure != null) throw failure;

    final items = includeRevoked
        ? tokens
        : tokens.where((token) => token.revokedAt == null).toList();

    return TokenListDto(items: items, total: items.length);
  }

  @override
  Future<IssuedTokenDto> create({
    required String name,
    required int expiresInDays,
  }) async {
    final failure = createFailure;
    if (failure != null) throw failure;

    final created = DateTime(2026, 9, 24, 14, 32);
    final result =
        issued ??
        IssuedTokenDto(
          id: 'token-${tokens.length + 1}',
          name: name,
          prefix: 'aa17f900',
          token: 'aa17f900-4e7b-4c2a-9d31-QmFzZTY0VmVyaWZpZXI',
          createdAt: created,
          expiresAt: created.add(Duration(days: expiresInDays)),
        );

    tokens = [
      fakeToken(
        id: result.id,
        name: result.name,
        prefix: result.prefix,
        createdAt: result.createdAt,
        expiresAt: result.expiresAt,
      ),
      ...tokens,
    ];

    return result;
  }

  @override
  Future<void> revoke(String id) async {
    final failure = revokeFailure;
    if (failure != null) throw failure;

    revokedIds.add(id);
    tokens = [
      for (final token in tokens)
        if (token.id == id) token.copyWith(revokedAt: revokedAt) else token,
    ];
  }
}
