// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'dependency_health_dto_status.dart';

part 'dependency_health_dto.freezed.dart';
part 'dependency_health_dto.g.dart';

@Freezed()
abstract class DependencyHealthDto with _$DependencyHealthDto {
  const factory DependencyHealthDto({
    /// Доступна ли зависимость
    required DependencyHealthDtoStatus status,

    /// Время ответа зависимости, мс
    required num latencyMs,

    /// Причина недоступности в общих словах. Внутренние детали и стектрейсы наружу не выходят — они в логах сервера.
    String? error,
  }) = _DependencyHealthDto;

  factory DependencyHealthDto.fromJson(Map<String, Object?> json) =>
      _$DependencyHealthDtoFromJson(json);
}
