// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'issued_token_dto.freezed.dart';
part 'issued_token_dto.g.dart';

@Freezed()
abstract class IssuedTokenDto with _$IssuedTokenDto {
  const factory IssuedTokenDto({
    required String id,
    required String name,
    required String prefix,

    /// Сам токен. **Показывается ровно один раз** — в этом ответе. Предъявляется заголовком `Authorization: Bearer <токен>` и даёт те же права, что у владельца.
    required String token,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _IssuedTokenDto;

  factory IssuedTokenDto.fromJson(Map<String, Object?> json) =>
      _$IssuedTokenDtoFromJson(json);
}
