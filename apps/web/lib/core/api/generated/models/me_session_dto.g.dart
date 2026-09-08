// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeSessionDto _$MeSessionDtoFromJson(Map<String, dynamic> json) =>
    _MeSessionDto(
      kind: MeSessionDtoKind.fromJson(json['kind'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$MeSessionDtoToJson(_MeSessionDto instance) =>
    <String, dynamic>{
      'kind': _$MeSessionDtoKindEnumMap[instance.kind]!,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

const _$MeSessionDtoKindEnumMap = {
  MeSessionDtoKind.cookie: 'cookie',
  MeSessionDtoKind.bearer: 'bearer',
  MeSessionDtoKind.$unknown: r'$unknown',
};
