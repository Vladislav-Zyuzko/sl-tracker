// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'me_session_dto_kind.dart';

part 'me_session_dto.freezed.dart';
part 'me_session_dto.g.dart';

@Freezed()
abstract class MeSessionDto with _$MeSessionDto {
  const factory MeSessionDto({
    /// Чем предъявлена сессия. На права не влияет — это транспорт (ADR-0002).
    required MeSessionDtoKind kind,

    /// Когда сессия истекает
    required DateTime expiresAt,
  }) = _MeSessionDto;

  factory MeSessionDto.fromJson(Map<String, Object?> json) =>
      _$MeSessionDtoFromJson(json);
}
