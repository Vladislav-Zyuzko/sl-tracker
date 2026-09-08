// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'revoke_access_result_dto.freezed.dart';
part 'revoke_access_result_dto.g.dart';

@Freezed()
abstract class RevokeAccessResultDto with _$RevokeAccessResultDto {
  const factory RevokeAccessResultDto({
    /// Сколько активных сессий человека погашено немедленно (US-09).
    required num revokedSessions,
  }) = _RevokeAccessResultDto;

  factory RevokeAccessResultDto.fromJson(Map<String, Object?> json) =>
      _$RevokeAccessResultDtoFromJson(json);
}
