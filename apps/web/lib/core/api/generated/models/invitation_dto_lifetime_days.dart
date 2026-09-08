// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Срок жизни ссылки в днях — тот, что выбрал администратор при создании. Отдаётся полем, а не выводится клиентом из разницы дат: строка списка показывает «Участник · 7 дней · до 19 фев» (design/screens/project.md), и вычитание дат у истёкшего приглашения дало бы не то, что выбирали.
@JsonEnum()
enum InvitationDtoLifetimeDays {
  @JsonValue(1)
  value1(1),
  @JsonValue(7)
  value7(7),
  @JsonValue(30)
  value30(30),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const InvitationDtoLifetimeDays(this.json);

  factory InvitationDtoLifetimeDays.fromJson(num json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final num? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<InvitationDtoLifetimeDays> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
