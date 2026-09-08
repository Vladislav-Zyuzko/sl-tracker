// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Откуда запись: `config` — из конфигурации инстанса, `manual` — добавлена владельцем вручную, `invitation` — появилась при приёме приглашения (ADR-0006).
@JsonEnum()
enum AccessEntryDtoSource {
  @JsonValue('config')
  config('config'),
  @JsonValue('manual')
  manual('manual'),
  @JsonValue('invitation')
  invitation('invitation'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AccessEntryDtoSource(this.json);

  factory AccessEntryDtoSource.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AccessEntryDtoSource> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
