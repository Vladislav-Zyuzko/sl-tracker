// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateIssueDto _$UpdateIssueDtoFromJson(Map<String, dynamic> json) =>
    _UpdateIssueDto(
      title: json['title'] as String?,
      description: json['description'] as String?,
      statusId: json['statusId'] as String?,
      priority: json['priority'] == null
          ? null
          : UpdateIssueDtoPriority.fromJson(json['priority'] as num),
      storyPoints: json['storyPoints'] == null
          ? null
          : UpdateIssueDtoStoryPoints.fromJson(json['storyPoints'] as num),
      authorId: json['authorId'] as String?,
      assigneeId: json['assigneeId'] as String?,
    );

Map<String, dynamic> _$UpdateIssueDtoToJson(_UpdateIssueDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'statusId': instance.statusId,
      'priority': _$UpdateIssueDtoPriorityEnumMap[instance.priority],
      'storyPoints': _$UpdateIssueDtoStoryPointsEnumMap[instance.storyPoints],
      'authorId': instance.authorId,
      'assigneeId': instance.assigneeId,
    };

const _$UpdateIssueDtoPriorityEnumMap = {
  UpdateIssueDtoPriority.value0: 0,
  UpdateIssueDtoPriority.value10: 10,
  UpdateIssueDtoPriority.value20: 20,
  UpdateIssueDtoPriority.value30: 30,
  UpdateIssueDtoPriority.value40: 40,
  UpdateIssueDtoPriority.value50: 50,
  UpdateIssueDtoPriority.value60: 60,
  UpdateIssueDtoPriority.value70: 70,
  UpdateIssueDtoPriority.value80: 80,
  UpdateIssueDtoPriority.value90: 90,
  UpdateIssueDtoPriority.value100: 100,
  UpdateIssueDtoPriority.$unknown: r'$unknown',
};

const _$UpdateIssueDtoStoryPointsEnumMap = {
  UpdateIssueDtoStoryPoints.value1: 1,
  UpdateIssueDtoStoryPoints.value2: 2,
  UpdateIssueDtoStoryPoints.value3: 3,
  UpdateIssueDtoStoryPoints.value5: 5,
  UpdateIssueDtoStoryPoints.value8: 8,
  UpdateIssueDtoStoryPoints.value13: 13,
  UpdateIssueDtoStoryPoints.$unknown: r'$unknown',
};
