// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Шкала Фибоначчи. `null` или отсутствие поля — «не оценено» (D-16).
@JsonEnum()
enum CreateIssueDtoStoryPoints {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3),
  @JsonValue(5)
  value5(5),
  @JsonValue(8)
  value8(8),
  @JsonValue(13)
  value13(13),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CreateIssueDtoStoryPoints(this.json);

  factory CreateIssueDtoStoryPoints.fromJson(num json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final num? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CreateIssueDtoStoryPoints> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
