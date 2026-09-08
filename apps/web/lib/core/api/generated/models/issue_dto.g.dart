// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueDto _$IssueDtoFromJson(Map<String, dynamic> json) => _IssueDto(
  key: json['key'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: IssueStatusFullDto.fromJson(json['status'] as Map<String, dynamic>),
  priority: IssueDtoPriority.fromJson(json['priority'] as num),
  storyPoints: json['storyPoints'] == null
      ? null
      : IssueDtoStoryPoints.fromJson(json['storyPoints'] as num),
  author: IssueUserDto.fromJson(json['author'] as Map<String, dynamic>),
  assignee: json['assignee'] == null
      ? null
      : IssueUserDto.fromJson(json['assignee'] as Map<String, dynamic>),
  queue: IssueQueueRefDto.fromJson(json['queue'] as Map<String, dynamic>),
  project: IssueProjectRefDto.fromJson(json['project'] as Map<String, dynamic>),
  links: (json['links'] as List<dynamic>)
      .map((e) => IssueLinkDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  role: IssueDtoRole.fromJson(json['role'] as String),
  permissions: IssuePermissionsDto.fromJson(
    json['permissions'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$IssueDtoToJson(_IssueDto instance) => <String, dynamic>{
  'key': instance.key,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'priority': _$IssueDtoPriorityEnumMap[instance.priority]!,
  'storyPoints': _$IssueDtoStoryPointsEnumMap[instance.storyPoints],
  'author': instance.author,
  'assignee': instance.assignee,
  'queue': instance.queue,
  'project': instance.project,
  'links': instance.links,
  'role': _$IssueDtoRoleEnumMap[instance.role]!,
  'permissions': instance.permissions,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$IssueDtoPriorityEnumMap = {
  IssueDtoPriority.value0: 0,
  IssueDtoPriority.value10: 10,
  IssueDtoPriority.value20: 20,
  IssueDtoPriority.value30: 30,
  IssueDtoPriority.value40: 40,
  IssueDtoPriority.value50: 50,
  IssueDtoPriority.value60: 60,
  IssueDtoPriority.value70: 70,
  IssueDtoPriority.value80: 80,
  IssueDtoPriority.value90: 90,
  IssueDtoPriority.value100: 100,
  IssueDtoPriority.$unknown: r'$unknown',
};

const _$IssueDtoStoryPointsEnumMap = {
  IssueDtoStoryPoints.value1: 1,
  IssueDtoStoryPoints.value2: 2,
  IssueDtoStoryPoints.value3: 3,
  IssueDtoStoryPoints.value5: 5,
  IssueDtoStoryPoints.value8: 8,
  IssueDtoStoryPoints.value13: 13,
  IssueDtoStoryPoints.$unknown: r'$unknown',
};

const _$IssueDtoRoleEnumMap = {
  IssueDtoRole.admin: 'admin',
  IssueDtoRole.member: 'member',
  IssueDtoRole.reader: 'reader',
  IssueDtoRole.$unknown: r'$unknown',
};
