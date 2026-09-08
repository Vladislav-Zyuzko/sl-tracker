// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum PriorityMax {
  @JsonValue(0)
  value0(0),
  @JsonValue(10)
  value10(10),
  @JsonValue(20)
  value20(20),
  @JsonValue(30)
  value30(30),
  @JsonValue(40)
  value40(40),
  @JsonValue(50)
  value50(50),
  @JsonValue(60)
  value60(60),
  @JsonValue(70)
  value70(70),
  @JsonValue(80)
  value80(80),
  @JsonValue(90)
  value90(90),
  @JsonValue(100)
  value100(100),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const PriorityMax(this.json);

  factory PriorityMax.fromJson(num json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final num? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<PriorityMax> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
