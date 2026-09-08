// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Вычисляется из срока и отметки об отзыве, отдельно не хранится. Истёкшие и отозванные остаются в списке, но повторно активировать их нельзя (US-22).
@JsonEnum()
enum InvitationDtoState {
  @JsonValue('active')
  active('active'),
  @JsonValue('expired')
  expired('expired'),
  @JsonValue('revoked')
  revoked('revoked'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const InvitationDtoState(this.json);

  factory InvitationDtoState.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<InvitationDtoState> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
