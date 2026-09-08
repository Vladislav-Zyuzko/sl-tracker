// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_history_group_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueHistoryGroupDto _$IssueHistoryGroupDtoFromJson(
  Map<String, dynamic> json,
) => _IssueHistoryGroupDto(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  actor: json['actor'] == null
      ? null
      : IssueUserDto.fromJson(json['actor'] as Map<String, dynamic>),
  changes: (json['changes'] as List<dynamic>)
      .map((e) => IssueHistoryChangeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IssueHistoryGroupDtoToJson(
  _IssueHistoryGroupDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'actor': instance.actor,
  'changes': instance.changes,
};
