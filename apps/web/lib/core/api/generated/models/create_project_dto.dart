// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_project_dto.freezed.dart';
part 'create_project_dto.g.dart';

@Freezed()
abstract class CreateProjectDto with _$CreateProjectDto {
  const factory CreateProjectDto({
    /// Название проекта. Короткое имя в адресе выдаётся сервером автоматически по названию и отдельно не передаётся (US-11, US-18).
    required String name,

    /// Markdown, до 5000 символов. Пустая строка равнозначна отсутствию описания.
    String? description,
  }) = _CreateProjectDto;

  factory CreateProjectDto.fromJson(Map<String, Object?> json) =>
      _$CreateProjectDtoFromJson(json);
}
