// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Роль текущего пользователя в этом проекте (permissions.md, 2.1).
@JsonEnum()
enum ProjectDtoRole {
  @JsonValue('admin')
  admin('admin'),
  @JsonValue('member')
  member('member'),
  @JsonValue('reader')
  reader('reader'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ProjectDtoRole(this.json);

  factory ProjectDtoRole.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ProjectDtoRole> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
