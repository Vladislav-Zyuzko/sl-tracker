// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_notification_setting_dto_channel.dart';
import 'update_notification_setting_dto_type.dart';

part 'update_notification_setting_dto.freezed.dart';
part 'update_notification_setting_dto.g.dart';

@Freezed()
abstract class UpdateNotificationSettingDto
    with _$UpdateNotificationSettingDto {
  const factory UpdateNotificationSettingDto({
    required UpdateNotificationSettingDtoType type,

    /// Выключенный тип не создаёт ни записи, ни счётчика (US-103)
    required bool enabled,

    /// Канал. В MVP единственный, но передавать его можно уже сейчас (D-18).
    @Default(UpdateNotificationSettingDtoChannel.inApp)
    UpdateNotificationSettingDtoChannel channel,
  }) = _UpdateNotificationSettingDto;

  factory UpdateNotificationSettingDto.fromJson(Map<String, Object?> json) =>
      _$UpdateNotificationSettingDtoFromJson(json);
}
