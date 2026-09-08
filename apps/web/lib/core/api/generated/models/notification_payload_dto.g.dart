// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_payload_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationPayloadDto _$NotificationPayloadDtoFromJson(
  Map<String, dynamic> json,
) => _NotificationPayloadDto(
  issueKey: json['issueKey'] as String?,
  issueTitle: json['issueTitle'] as String?,
  fromStatusName: json['fromStatusName'] as String?,
  toStatusName: json['toStatusName'] as String?,
  excerpt: json['excerpt'] as String?,
  source: json['source'] == null
      ? null
      : NotificationPayloadDtoSource.fromJson(json['source'] as String),
  projectSlug: json['projectSlug'] as String?,
  projectName: json['projectName'] as String?,
  memberName: json['memberName'] as String?,
);

Map<String, dynamic> _$NotificationPayloadDtoToJson(
  _NotificationPayloadDto instance,
) => <String, dynamic>{
  'issueKey': instance.issueKey,
  'issueTitle': instance.issueTitle,
  'fromStatusName': instance.fromStatusName,
  'toStatusName': instance.toStatusName,
  'excerpt': instance.excerpt,
  'source': _$NotificationPayloadDtoSourceEnumMap[instance.source],
  'projectSlug': instance.projectSlug,
  'projectName': instance.projectName,
  'memberName': instance.memberName,
};

const _$NotificationPayloadDtoSourceEnumMap = {
  NotificationPayloadDtoSource.comment: 'comment',
  NotificationPayloadDtoSource.description: 'description',
  NotificationPayloadDtoSource.$unknown: r'$unknown',
};
