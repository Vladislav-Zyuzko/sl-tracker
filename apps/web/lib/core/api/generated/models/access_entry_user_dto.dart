// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_entry_user_dto.freezed.dart';
part 'access_entry_user_dto.g.dart';

@Freezed()
abstract class AccessEntryUserDto with _$AccessEntryUserDto {
  const factory AccessEntryUserDto({
    required String id,
    required String displayName,

    /// Аватар из Яндекс ID
    required String? avatarUrl,
  }) = _AccessEntryUserDto;

  factory AccessEntryUserDto.fromJson(Map<String, Object?> json) =>
      _$AccessEntryUserDtoFromJson(json);
}
