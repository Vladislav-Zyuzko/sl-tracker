// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notification_setting_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateNotificationSettingDto _$UpdateNotificationSettingDtoFromJson(
  Map<String, dynamic> json,
) => _UpdateNotificationSettingDto(
  type: UpdateNotificationSettingDtoType.fromJson(json['type'] as String),
  enabled: json['enabled'] as bool,
  channel: json['channel'] == null
      ? UpdateNotificationSettingDtoChannel.inApp
      : UpdateNotificationSettingDtoChannel.fromJson(json['channel'] as String),
);

Map<String, dynamic> _$UpdateNotificationSettingDtoToJson(
  _UpdateNotificationSettingDto instance,
) => <String, dynamic>{
  'type': _$UpdateNotificationSettingDtoTypeEnumMap[instance.type]!,
  'enabled': instance.enabled,
  'channel': _$UpdateNotificationSettingDtoChannelEnumMap[instance.channel]!,
};

const _$UpdateNotificationSettingDtoTypeEnumMap = {
  UpdateNotificationSettingDtoType.issueAssigned: 'issue_assigned',
  UpdateNotificationSettingDtoType.issueAuthorAssigned: 'issue_author_assigned',
  UpdateNotificationSettingDtoType.issueStatusChanged: 'issue_status_changed',
  UpdateNotificationSettingDtoType.issueCommented: 'issue_commented',
  UpdateNotificationSettingDtoType.issueMentioned: 'issue_mentioned',
  UpdateNotificationSettingDtoType.projectMemberJoined: 'project_member_joined',
  UpdateNotificationSettingDtoType.$unknown: r'$unknown',
};

const _$UpdateNotificationSettingDtoChannelEnumMap = {
  UpdateNotificationSettingDtoChannel.inApp: 'in_app',
  UpdateNotificationSettingDtoChannel.$unknown: r'$unknown',
};
