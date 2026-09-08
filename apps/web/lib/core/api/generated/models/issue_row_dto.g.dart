// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_row_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueRowDto _$IssueRowDtoFromJson(Map<String, dynamic> json) => _IssueRowDto(
  key: json['key'] as String,
  title: json['title'] as String,
  status: IssueRowStatusDto.fromJson(json['status'] as Map<String, dynamic>),
  priority: json['priority'] as num,
  storyPoints: json['storyPoints'] as num?,
  assignee: json['assignee'] == null
      ? null
      : IssueUserDto.fromJson(json['assignee'] as Map<String, dynamic>),
);

Map<String, dynamic> _$IssueRowDtoToJson(_IssueRowDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'status': instance.status,
      'priority': instance.priority,
      'storyPoints': instance.storyPoints,
      'assignee': instance.assignee,
    };
