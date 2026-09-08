// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_notification_setting_dto.dart';

part 'update_notification_settings_dto.freezed.dart';
part 'update_notification_settings_dto.g.dart';

@Freezed()
abstract class UpdateNotificationSettingsDto
    with _$UpdateNotificationSettingsDto {
  const factory UpdateNotificationSettingsDto({
    /// Меняются только перечисленные типы; остальные остаются как были.
    required List<UpdateNotificationSettingDto> items,
  }) = _UpdateNotificationSettingsDto;

  factory UpdateNotificationSettingsDto.fromJson(Map<String, Object?> json) =>
      _$UpdateNotificationSettingsDtoFromJson(json);
}
