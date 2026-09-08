// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notification_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateNotificationSettingsDto _$UpdateNotificationSettingsDtoFromJson(
  Map<String, dynamic> json,
) => _UpdateNotificationSettingsDto(
  items: (json['items'] as List<dynamic>)
      .map(
        (e) => UpdateNotificationSettingDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$UpdateNotificationSettingsDtoToJson(
  _UpdateNotificationSettingsDto instance,
) => <String, dynamic>{'items': instance.items};
