// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeResponseDto _$MeResponseDtoFromJson(Map<String, dynamic> json) =>
    _MeResponseDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isInstanceOwner: json['isInstanceOwner'] as bool,
      canManageAccessList: json['canManageAccessList'] as bool,
      session: MeSessionDto.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MeResponseDtoToJson(_MeResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'isInstanceOwner': instance.isInstanceOwner,
      'canManageAccessList': instance.canManageAccessList,
      'session': instance.session,
    };
