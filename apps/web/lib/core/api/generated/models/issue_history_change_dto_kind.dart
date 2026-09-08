// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Что изменилось. `issue_created` — создание задачи; эта запись всегда самая ранняя и показывает **реального создателя**, даже если поле «Автор» потом меняли (D-13). У `description_changed` значений нет: фиксируется только факт изменения, старый текст не хранится (US-91).
@JsonEnum()
enum IssueHistoryChangeDtoKind {
  @JsonValue('issue_created')
  issueCreated('issue_created'),
  @JsonValue('title_changed')
  titleChanged('title_changed'),
  @JsonValue('description_changed')
  descriptionChanged('description_changed'),
  @JsonValue('status_changed')
  statusChanged('status_changed'),
  @JsonValue('priority_changed')
  priorityChanged('priority_changed'),
  @JsonValue('story_points_changed')
  storyPointsChanged('story_points_changed'),
  @JsonValue('author_changed')
  authorChanged('author_changed'),
  @JsonValue('assignee_changed')
  assigneeChanged('assignee_changed'),
  @JsonValue('attachment_added')
  attachmentAdded('attachment_added'),
  @JsonValue('attachment_removed')
  attachmentRemoved('attachment_removed'),
  @JsonValue('link_added')
  linkAdded('link_added'),
  @JsonValue('link_removed')
  linkRemoved('link_removed'),
  @JsonValue('comment_deleted')
  commentDeleted('comment_deleted'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const IssueHistoryChangeDtoKind(this.json);

  factory IssueHistoryChangeDtoKind.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<IssueHistoryChangeDtoKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
