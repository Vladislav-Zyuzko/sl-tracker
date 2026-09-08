// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthResponseDto _$HealthResponseDtoFromJson(Map<String, dynamic> json) =>
    _HealthResponseDto(
      status: HealthResponseDtoStatus.fromJson(json['status'] as String),
      uptimeSeconds: json['uptimeSeconds'] as num,
      postgres: DependencyHealthDto.fromJson(
        json['postgres'] as Map<String, dynamic>,
      ),
      redis: DependencyHealthDto.fromJson(
        json['redis'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$HealthResponseDtoToJson(_HealthResponseDto instance) =>
    <String, dynamic>{
      'status': _$HealthResponseDtoStatusEnumMap[instance.status]!,
      'uptimeSeconds': instance.uptimeSeconds,
      'postgres': instance.postgres,
      'redis': instance.redis,
    };

const _$HealthResponseDtoStatusEnumMap = {
  HealthResponseDtoStatus.ok: 'ok',
  HealthResponseDtoStatus.degraded: 'degraded',
  HealthResponseDtoStatus.$unknown: r'$unknown',
};
