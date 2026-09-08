// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessEntryDto _$AccessEntryDtoFromJson(Map<String, dynamic> json) =>
    _AccessEntryDto(
      id: json['id'] as String,
      email: json['email'] as String,
      source: AccessEntryDtoSource.fromJson(json['source'] as String),
      isInstanceOwner: json['isInstanceOwner'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      firstLoginAt: json['firstLoginAt'] == null
          ? null
          : DateTime.parse(json['firstLoginAt'] as String),
      user: json['user'] == null
          ? null
          : AccessEntryUserDto.fromJson(json['user'] as Map<String, dynamic>),
      addedBy: json['addedBy'] == null
          ? null
          : AccessEntryUserDto.fromJson(
              json['addedBy'] as Map<String, dynamic>,
            ),
      isSelf: json['isSelf'] as bool,
    );

Map<String, dynamic> _$AccessEntryDtoToJson(_AccessEntryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'source': _$AccessEntryDtoSourceEnumMap[instance.source]!,
      'isInstanceOwner': instance.isInstanceOwner,
      'createdAt': instance.createdAt.toIso8601String(),
      'firstLoginAt': instance.firstLoginAt?.toIso8601String(),
      'user': instance.user,
      'addedBy': instance.addedBy,
      'isSelf': instance.isSelf,
    };

const _$AccessEntryDtoSourceEnumMap = {
  AccessEntryDtoSource.config: 'config',
  AccessEntryDtoSource.manual: 'manual',
  AccessEntryDtoSource.invitation: 'invitation',
  AccessEntryDtoSource.$unknown: r'$unknown',
};
