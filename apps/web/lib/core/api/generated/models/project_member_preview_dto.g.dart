// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_preview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectMemberPreviewDto _$ProjectMemberPreviewDtoFromJson(
  Map<String, dynamic> json,
) => _ProjectMemberPreviewDto(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  role: ProjectMemberPreviewDtoRole.fromJson(json['role'] as String),
);

Map<String, dynamic> _$ProjectMemberPreviewDtoToJson(
  _ProjectMemberPreviewDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'role': _$ProjectMemberPreviewDtoRoleEnumMap[instance.role]!,
};

const _$ProjectMemberPreviewDtoRoleEnumMap = {
  ProjectMemberPreviewDtoRole.admin: 'admin',
  ProjectMemberPreviewDtoRole.member: 'member',
  ProjectMemberPreviewDtoRole.reader: 'reader',
  ProjectMemberPreviewDtoRole.$unknown: r'$unknown',
};
