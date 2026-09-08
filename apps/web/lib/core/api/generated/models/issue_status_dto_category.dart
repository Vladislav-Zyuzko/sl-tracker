// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Категория статуса. Активной считается задача, у которой категория не `done`; в этом списке `done` не встречается.
@JsonEnum()
enum IssueStatusDtoCategory {
  @JsonValue('open')
  open('open'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('done')
  done('done'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const IssueStatusDtoCategory(this.json);

  factory IssueStatusDtoCategory.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<IssueStatusDtoCategory> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
