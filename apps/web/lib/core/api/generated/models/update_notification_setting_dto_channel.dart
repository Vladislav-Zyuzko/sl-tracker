// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Канал. В MVP единственный, но передавать его можно уже сейчас (D-18).
@JsonEnum()
enum UpdateNotificationSettingDtoChannel {
  @JsonValue('in_app')
  inApp('in_app'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const UpdateNotificationSettingDtoChannel(this.json);

  factory UpdateNotificationSettingDtoChannel.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<UpdateNotificationSettingDtoChannel> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
