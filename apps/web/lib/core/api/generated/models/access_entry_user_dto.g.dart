// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_entry_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessEntryUserDto _$AccessEntryUserDtoFromJson(Map<String, dynamic> json) =>
    _AccessEntryUserDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$AccessEntryUserDtoToJson(_AccessEntryUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };
