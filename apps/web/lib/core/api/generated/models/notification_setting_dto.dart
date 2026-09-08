// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_setting_dto_channel.dart';
import 'notification_setting_dto_type.dart';

part 'notification_setting_dto.freezed.dart';
part 'notification_setting_dto.g.dart';

@Freezed()
abstract class NotificationSettingDto with _$NotificationSettingDto {
  const factory NotificationSettingDto({
    required NotificationSettingDtoType type,
    required NotificationSettingDtoChannel channel,

    /// По умолчанию включены все типы (US-103)
    required bool enabled,
  }) = _NotificationSettingDto;

  factory NotificationSettingDto.fromJson(Map<String, Object?> json) =>
      _$NotificationSettingDtoFromJson(json);
}
