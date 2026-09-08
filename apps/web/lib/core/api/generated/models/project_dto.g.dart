// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectDto _$ProjectDtoFromJson(Map<String, dynamic> json) => _ProjectDto(
  id: json['id'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  role: ProjectDtoRole.fromJson(json['role'] as String),
  memberCount: json['memberCount'] as num,
  members: (json['members'] as List<dynamic>)
      .map((e) => ProjectMemberPreviewDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ProjectDtoToJson(_ProjectDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'role': _$ProjectDtoRoleEnumMap[instance.role]!,
      'memberCount': instance.memberCount,
      'members': instance.members,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProjectDtoRoleEnumMap = {
  ProjectDtoRole.admin: 'admin',
  ProjectDtoRole.member: 'member',
  ProjectDtoRole.reader: 'reader',
  ProjectDtoRole.$unknown: r'$unknown',
};
