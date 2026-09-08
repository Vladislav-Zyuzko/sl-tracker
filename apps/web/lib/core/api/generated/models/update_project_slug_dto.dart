// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_project_slug_dto.freezed.dart';
part 'update_project_slug_dto.g.dart';

@Freezed()
abstract class UpdateProjectSlugDto with _$UpdateProjectSlugDto {
  const factory UpdateProjectSlugDto({
    /// Новое короткое имя: строчные латинские буквы, цифры и одиночные дефисы внутри. Прежнее имя остаётся занятым навсегда и продолжает открывать этот проект (US-18).
    required String slug,
  }) = _UpdateProjectSlugDto;

  factory UpdateProjectSlugDto.fromJson(Map<String, Object?> json) =>
      _$UpdateProjectSlugDtoFromJson(json);
}
