// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Где находится упоминание. `description` — в описании задачи: прокручивать надо к описанию, а не к комментарию (US-104). Только `issue_mentioned`.
@JsonEnum()
enum NotificationPayloadDtoSource {
  @JsonValue('comment')
  comment('comment'),
  @JsonValue('description')
  description('description'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const NotificationPayloadDtoSource(this.json);

  factory NotificationPayloadDtoSource.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<NotificationPayloadDtoSource> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
