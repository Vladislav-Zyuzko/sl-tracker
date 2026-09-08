// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Срок жизни ссылки в днях. Бессрочных приглашений нет (US-20).
@JsonEnum()
enum CreateInvitationDtoExpiresInDays {
  @JsonValue(1)
  value1(1),
  @JsonValue(7)
  value7(7),
  @JsonValue(30)
  value30(30),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CreateInvitationDtoExpiresInDays(this.json);

  factory CreateInvitationDtoExpiresInDays.fromJson(num json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final num? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CreateInvitationDtoExpiresInDays> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
