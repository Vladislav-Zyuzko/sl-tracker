// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectMemberDto _$ProjectMemberDtoFromJson(Map<String, dynamic> json) =>
    _ProjectMemberDto(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: ProjectMemberDtoRole.fromJson(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isSelf: json['isSelf'] as bool,
    );

Map<String, dynamic> _$ProjectMemberDtoToJson(_ProjectMemberDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'role': _$ProjectMemberDtoRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'isSelf': instance.isSelf,
    };

const _$ProjectMemberDtoRoleEnumMap = {
  ProjectMemberDtoRole.admin: 'admin',
  ProjectMemberDtoRole.member: 'member',
  ProjectMemberDtoRole.reader: 'reader',
  ProjectMemberDtoRole.$unknown: r'$unknown',
};
