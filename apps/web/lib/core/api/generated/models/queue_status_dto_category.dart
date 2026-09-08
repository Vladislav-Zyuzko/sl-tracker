// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Категория статуса. Задача считается незавершённой, пока категория не `done`. Опираться нужно на категорию, а не на `key` и не на порядок (ADR-0003).
@JsonEnum()
enum QueueStatusDtoCategory {
  @JsonValue('open')
  open('open'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('done')
  done('done'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const QueueStatusDtoCategory(this.json);

  factory QueueStatusDtoCategory.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<QueueStatusDtoCategory> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
