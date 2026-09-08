// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_health_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DependencyHealthDto _$DependencyHealthDtoFromJson(Map<String, dynamic> json) =>
    _DependencyHealthDto(
      status: DependencyHealthDtoStatus.fromJson(json['status'] as String),
      latencyMs: json['latencyMs'] as num,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DependencyHealthDtoToJson(
  _DependencyHealthDto instance,
) => <String, dynamic>{
  'status': _$DependencyHealthDtoStatusEnumMap[instance.status]!,
  'latencyMs': instance.latencyMs,
  'error': instance.error,
};

const _$DependencyHealthDtoStatusEnumMap = {
  DependencyHealthDtoStatus.up: 'up',
  DependencyHealthDtoStatus.down: 'down',
  DependencyHealthDtoStatus.$unknown: r'$unknown',
};
