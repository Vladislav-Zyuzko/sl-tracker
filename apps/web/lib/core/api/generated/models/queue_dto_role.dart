// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Роль запросившего в проекте, которому принадлежит очередь. Права на очередь наследуются от проекта: прав уровня очереди в MVP нет (permissions.md, п. 3).
@JsonEnum()
enum QueueDtoRole {
  @JsonValue('admin')
  admin('admin'),
  @JsonValue('member')
  member('member'),
  @JsonValue('reader')
  reader('reader'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const QueueDtoRole(this.json);

  factory QueueDtoRole.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<QueueDtoRole> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
