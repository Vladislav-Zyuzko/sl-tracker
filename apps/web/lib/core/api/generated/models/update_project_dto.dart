// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_project_dto.freezed.dart';
part 'update_project_dto.g.dart';

@Freezed()
abstract class UpdateProjectDto with _$UpdateProjectDto {
  const factory UpdateProjectDto({
    /// Новое название. Переименование **не меняет** короткое имя в адресе: ранее отправленные ссылки продолжают работать (US-18).
    String? name,

    /// `null` или пустая строка убирают описание.
    String? description,
  }) = _UpdateProjectDto;

  factory UpdateProjectDto.fromJson(Map<String, Object?> json) =>
      _$UpdateProjectDtoFromJson(json);
}
