// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_access_entry_dto.freezed.dart';
part 'update_access_entry_dto.g.dart';

@Freezed()
abstract class UpdateAccessEntryDto with _$UpdateAccessEntryDto {
  const factory UpdateAccessEntryDto({
    /// Признак владельца трекера. Снять его с последнего владельца нельзя — 409 `last_instance_owner`.
    required bool isInstanceOwner,
  }) = _UpdateAccessEntryDto;

  factory UpdateAccessEntryDto.fromJson(Map<String, Object?> json) =>
      _$UpdateAccessEntryDtoFromJson(json);
}
