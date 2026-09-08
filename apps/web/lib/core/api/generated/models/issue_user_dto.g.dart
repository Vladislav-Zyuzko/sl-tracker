// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueUserDto _$IssueUserDtoFromJson(Map<String, dynamic> json) =>
    _IssueUserDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$IssueUserDtoToJson(_IssueUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };
