// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueDto _$QueueDtoFromJson(Map<String, dynamic> json) => _QueueDto(
  key: json['key'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  projectSlug: json['projectSlug'] as String,
  projectName: json['projectName'] as String,
  openIssueCount: json['openIssueCount'] as num,
  role: QueueDtoRole.fromJson(json['role'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$QueueDtoToJson(_QueueDto instance) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'description': instance.description,
  'projectSlug': instance.projectSlug,
  'projectName': instance.projectName,
  'openIssueCount': instance.openIssueCount,
  'role': _$QueueDtoRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$QueueDtoRoleEnumMap = {
  QueueDtoRole.admin: 'admin',
  QueueDtoRole.member: 'member',
  QueueDtoRole.reader: 'reader',
  QueueDtoRole.$unknown: r'$unknown',
};
