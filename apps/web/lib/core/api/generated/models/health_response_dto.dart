// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'dependency_health_dto.dart';
import 'health_response_dto_status.dart';

part 'health_response_dto.freezed.dart';
part 'health_response_dto.g.dart';

@Freezed()
abstract class HealthResponseDto with _$HealthResponseDto {
  const factory HealthResponseDto({
    /// `ok` — все зависимости доступны; `degraded` — хотя бы одна нет (HTTP 503)
    required HealthResponseDtoStatus status,

    /// Время работы процесса, секунды
    required num uptimeSeconds,

    /// PostgreSQL
    required DependencyHealthDto postgres,

    /// Redis
    required DependencyHealthDto redis,
  }) = _HealthResponseDto;

  factory HealthResponseDto.fromJson(Map<String, Object?> json) =>
      _$HealthResponseDtoFromJson(json);
}
