// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_history_change_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueHistoryChangeDto _$IssueHistoryChangeDtoFromJson(
  Map<String, dynamic> json,
) => _IssueHistoryChangeDto(
  id: json['id'] as String,
  kind: IssueHistoryChangeDtoKind.fromJson(json['kind'] as String),
  oldValue: json['oldValue'] as String?,
  newValue: json['newValue'] as String?,
  oldRefId: json['oldRefId'] as String?,
  newRefId: json['newRefId'] as String?,
);

Map<String, dynamic> _$IssueHistoryChangeDtoToJson(
  _IssueHistoryChangeDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': _$IssueHistoryChangeDtoKindEnumMap[instance.kind]!,
  'oldValue': instance.oldValue,
  'newValue': instance.newValue,
  'oldRefId': instance.oldRefId,
  'newRefId': instance.newRefId,
};

const _$IssueHistoryChangeDtoKindEnumMap = {
  IssueHistoryChangeDtoKind.issueCreated: 'issue_created',
  IssueHistoryChangeDtoKind.titleChanged: 'title_changed',
  IssueHistoryChangeDtoKind.descriptionChanged: 'description_changed',
  IssueHistoryChangeDtoKind.statusChanged: 'status_changed',
  IssueHistoryChangeDtoKind.priorityChanged: 'priority_changed',
  IssueHistoryChangeDtoKind.storyPointsChanged: 'story_points_changed',
  IssueHistoryChangeDtoKind.authorChanged: 'author_changed',
  IssueHistoryChangeDtoKind.assigneeChanged: 'assignee_changed',
  IssueHistoryChangeDtoKind.attachmentAdded: 'attachment_added',
  IssueHistoryChangeDtoKind.attachmentRemoved: 'attachment_removed',
  IssueHistoryChangeDtoKind.linkAdded: 'link_added',
  IssueHistoryChangeDtoKind.linkRemoved: 'link_removed',
  IssueHistoryChangeDtoKind.commentDeleted: 'comment_deleted',
  IssueHistoryChangeDtoKind.$unknown: r'$unknown',
};
