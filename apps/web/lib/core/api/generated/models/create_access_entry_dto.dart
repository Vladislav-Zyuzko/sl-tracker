// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_access_entry_dto.freezed.dart';
part 'create_access_entry_dto.g.dart';

@Freezed()
abstract class CreateAccessEntryDto with _$CreateAccessEntryDto {
  const factory CreateAccessEntryDto({
    /// Адрес аккаунта Яндекса. Регистр не важен: адрес приводится к нижнему регистру. Формат проверяется сервером, некорректный — 400 с кодом `invalid_email`.
    required String email,
  }) = _CreateAccessEntryDto;

  factory CreateAccessEntryDto.fromJson(Map<String, Object?> json) =>
      _$CreateAccessEntryDtoFromJson(json);
}
