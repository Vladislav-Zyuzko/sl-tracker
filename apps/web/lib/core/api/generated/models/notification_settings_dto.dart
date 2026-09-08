// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_setting_dto.dart';

part 'notification_settings_dto.freezed.dart';
part 'notification_settings_dto.g.dart';

@Freezed()
abstract class NotificationSettingsDto with _$NotificationSettingsDto {
  const factory NotificationSettingsDto({
    /// Все типы уведомлений, включая те, которые пользователь не трогал: отсутствие записи в базе означает «включено», и клиенту не нужно об этом знать.
    required List<NotificationSettingDto> items,
  }) = _NotificationSettingsDto;

  factory NotificationSettingsDto.fromJson(Map<String, Object?> json) =>
      _$NotificationSettingsDtoFromJson(json);
}
