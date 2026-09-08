// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    _NotificationDto(
      id: json['id'] as String,
      type: NotificationDtoType.fromJson(json['type'] as String),
      channel: NotificationDtoChannel.fromJson(json['channel'] as String),
      actor: json['actor'] == null
          ? null
          : IssueUserDto.fromJson(json['actor'] as Map<String, dynamic>),
      issueKey: json['issueKey'] as String?,
      projectSlug: json['projectSlug'] as String?,
      commentId: json['commentId'] as String?,
      payload: NotificationPayloadDto.fromJson(
        json['payload'] as Map<String, dynamic>,
      ),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$NotificationDtoToJson(_NotificationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationDtoTypeEnumMap[instance.type]!,
      'channel': _$NotificationDtoChannelEnumMap[instance.channel]!,
      'actor': instance.actor,
      'issueKey': instance.issueKey,
      'projectSlug': instance.projectSlug,
      'commentId': instance.commentId,
      'payload': instance.payload,
      'readAt': instance.readAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$NotificationDtoTypeEnumMap = {
  NotificationDtoType.issueAssigned: 'issue_assigned',
  NotificationDtoType.issueAuthorAssigned: 'issue_author_assigned',
  NotificationDtoType.issueStatusChanged: 'issue_status_changed',
  NotificationDtoType.issueCommented: 'issue_commented',
  NotificationDtoType.issueMentioned: 'issue_mentioned',
  NotificationDtoType.projectMemberJoined: 'project_member_joined',
  NotificationDtoType.$unknown: r'$unknown',
};

const _$NotificationDtoChannelEnumMap = {
  NotificationDtoChannel.inApp: 'in_app',
  NotificationDtoChannel.$unknown: r'$unknown',
};
