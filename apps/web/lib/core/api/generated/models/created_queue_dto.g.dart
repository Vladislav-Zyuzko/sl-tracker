// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_queue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreatedQueueDto _$CreatedQueueDtoFromJson(Map<String, dynamic> json) =>
    _CreatedQueueDto(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      projectSlug: json['projectSlug'] as String,
      projectName: json['projectName'] as String,
      openIssueCount: json['openIssueCount'] as num,
      role: CreatedQueueDtoRole.fromJson(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      statuses: (json['statuses'] as List<dynamic>)
          .map((e) => QueueStatusDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreatedQueueDtoToJson(_CreatedQueueDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
      'projectSlug': instance.projectSlug,
      'projectName': instance.projectName,
      'openIssueCount': instance.openIssueCount,
      'role': _$CreatedQueueDtoRoleEnumMap[instance.role]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'statuses': instance.statuses,
    };

const _$CreatedQueueDtoRoleEnumMap = {
  CreatedQueueDtoRole.admin: 'admin',
  CreatedQueueDtoRole.member: 'member',
  CreatedQueueDtoRole.reader: 'reader',
  CreatedQueueDtoRole.$unknown: r'$unknown',
};
