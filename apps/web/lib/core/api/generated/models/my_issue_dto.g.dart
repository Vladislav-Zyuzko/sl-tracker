// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MyIssueDto _$MyIssueDtoFromJson(Map<String, dynamic> json) => _MyIssueDto(
  key: json['key'] as String,
  title: json['title'] as String,
  priority: json['priority'] as num,
  status: IssueStatusDto.fromJson(json['status'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MyIssueDtoToJson(_MyIssueDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'priority': instance.priority,
      'status': instance.status,
    };
