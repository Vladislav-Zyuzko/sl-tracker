// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Роль, которую человек получит. Если он уже участник — его текущая роль: приглашение её не меняет и не понижает (US-21).
@JsonEnum()
enum InvitationPreviewDtoRole {
  @JsonValue('admin')
  admin('admin'),
  @JsonValue('member')
  member('member'),
  @JsonValue('reader')
  reader('reader'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const InvitationPreviewDtoRole(this.json);

  factory InvitationPreviewDtoRole.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<InvitationPreviewDtoRole> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
