// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum UpdateNotificationSettingDtoType {
  @JsonValue('issue_assigned')
  issueAssigned('issue_assigned'),
  @JsonValue('issue_author_assigned')
  issueAuthorAssigned('issue_author_assigned'),
  @JsonValue('issue_status_changed')
  issueStatusChanged('issue_status_changed'),
  @JsonValue('issue_commented')
  issueCommented('issue_commented'),
  @JsonValue('issue_mentioned')
  issueMentioned('issue_mentioned'),
  @JsonValue('project_member_joined')
  projectMemberJoined('project_member_joined'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const UpdateNotificationSettingDtoType(this.json);

  factory UpdateNotificationSettingDtoType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<UpdateNotificationSettingDtoType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
