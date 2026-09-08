// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateIssueDto _$CreateIssueDtoFromJson(Map<String, dynamic> json) =>
    _CreateIssueDto(
      title: json['title'] as String,
      priority: json['priority'] == null
          ? CreateIssueDtoPriority.value50
          : CreateIssueDtoPriority.fromJson(json['priority'] as num),
      description: json['description'] as String?,
      statusId: json['statusId'] as String?,
      storyPoints: json['storyPoints'] == null
          ? null
          : CreateIssueDtoStoryPoints.fromJson(json['storyPoints'] as num),
      authorId: json['authorId'] as String?,
      assigneeId: json['assigneeId'] as String?,
    );

Map<String, dynamic> _$CreateIssueDtoToJson(_CreateIssueDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'priority': _$CreateIssueDtoPriorityEnumMap[instance.priority]!,
      'description': instance.description,
      'statusId': instance.statusId,
      'storyPoints': _$CreateIssueDtoStoryPointsEnumMap[instance.storyPoints],
      'authorId': instance.authorId,
      'assigneeId': instance.assigneeId,
    };

const _$CreateIssueDtoPriorityEnumMap = {
  CreateIssueDtoPriority.value0: 0,
  CreateIssueDtoPriority.value10: 10,
  CreateIssueDtoPriority.value20: 20,
  CreateIssueDtoPriority.value30: 30,
  CreateIssueDtoPriority.value40: 40,
  CreateIssueDtoPriority.value50: 50,
  CreateIssueDtoPriority.value60: 60,
  CreateIssueDtoPriority.value70: 70,
  CreateIssueDtoPriority.value80: 80,
  CreateIssueDtoPriority.value90: 90,
  CreateIssueDtoPriority.value100: 100,
  CreateIssueDtoPriority.$unknown: r'$unknown',
};

const _$CreateIssueDtoStoryPointsEnumMap = {
  CreateIssueDtoStoryPoints.value1: 1,
  CreateIssueDtoStoryPoints.value2: 2,
  CreateIssueDtoStoryPoints.value3: 3,
  CreateIssueDtoStoryPoints.value5: 5,
  CreateIssueDtoStoryPoints.value8: 8,
  CreateIssueDtoStoryPoints.value13: 13,
  CreateIssueDtoStoryPoints.$unknown: r'$unknown',
};
