// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationSettingsDto _$NotificationSettingsDtoFromJson(
  Map<String, dynamic> json,
) => _NotificationSettingsDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => NotificationSettingDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NotificationSettingsDtoToJson(
  _NotificationSettingsDto instance,
) => <String, dynamic>{'items': instance.items};
