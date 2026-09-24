// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_dto.dart';

part 'token_list_dto.freezed.dart';
part 'token_list_dto.g.dart';

@Freezed()
abstract class TokenListDto with _$TokenListDto {
  const factory TokenListDto({
    /// Сначала новые
    required List<TokenDto> items,

    /// Сколько токенов в ответе
    required num total,
  }) = _TokenListDto;

  factory TokenListDto.fromJson(Map<String, Object?> json) =>
      _$TokenListDtoFromJson(json);
}
