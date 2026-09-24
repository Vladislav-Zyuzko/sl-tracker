// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_token_dto.freezed.dart';
part 'create_token_dto.g.dart';

@Freezed()
abstract class CreateTokenDto with _$CreateTokenDto {
  const factory CreateTokenDto({
    /// Как владелец назвал токен — «dsh-mcp», «ноутбук». Нужно, чтобы через полгода было понятно, что отзывать.
    required String name,

    /// Срок жизни токена в днях. Поле можно не передавать — тогда 365. Бессрочных токенов не бывает: `null` отклоняется, как и значение вне диапазона.
    @Default(365) num expiresInDays,
  }) = _CreateTokenDto;

  factory CreateTokenDto.fromJson(Map<String, Object?> json) =>
      _$CreateTokenDtoFromJson(json);
}
