// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_setting_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationSettingDto _$NotificationSettingDtoFromJson(
  Map<String, dynamic> json,
) => _NotificationSettingDto(
  type: NotificationSettingDtoType.fromJson(json['type'] as String),
  channel: NotificationSettingDtoChannel.fromJson(json['channel'] as String),
  enabled: json['enabled'] as bool,
);

Map<String, dynamic> _$NotificationSettingDtoToJson(
  _NotificationSettingDto instance,
) => <String, dynamic>{
  'type': _$NotificationSettingDtoTypeEnumMap[instance.type]!,
  'channel': _$NotificationSettingDtoChannelEnumMap[instance.channel]!,
  'enabled': instance.enabled,
};

const _$NotificationSettingDtoTypeEnumMap = {
  NotificationSettingDtoType.issueAssigned: 'issue_assigned',
  NotificationSettingDtoType.issueAuthorAssigned: 'issue_author_assigned',
  NotificationSettingDtoType.issueStatusChanged: 'issue_status_changed',
  NotificationSettingDtoType.issueCommented: 'issue_commented',
  NotificationSettingDtoType.issueMentioned: 'issue_mentioned',
  NotificationSettingDtoType.projectMemberJoined: 'project_member_joined',
  NotificationSettingDtoType.$unknown: r'$unknown',
};

const _$NotificationSettingDtoChannelEnumMap = {
  NotificationSettingDtoChannel.inApp: 'in_app',
  NotificationSettingDtoChannel.$unknown: r'$unknown',
};
