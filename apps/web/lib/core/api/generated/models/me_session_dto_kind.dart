// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Чем предъявлена сессия. На права не влияет — это транспорт (ADR-0002).
@JsonEnum()
enum MeSessionDtoKind {
  @JsonValue('cookie')
  cookie('cookie'),
  @JsonValue('bearer')
  bearer('bearer'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MeSessionDtoKind(this.json);

  factory MeSessionDtoKind.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<MeSessionDtoKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
