// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_dto.dart';

part 'project_list_dto.freezed.dart';
part 'project_list_dto.g.dart';

@Freezed()
abstract class ProjectListDto with _$ProjectListDto {
  const factory ProjectListDto({
    /// Проекты пользователя, по названию
    required List<ProjectDto> items,

    /// Курсор следующей страницы. `null` — проектов больше нет.
    required String? nextCursor,

    /// Всего проектов у пользователя
    required num total,
  }) = _ProjectListDto;

  factory ProjectListDto.fromJson(Map<String, Object?> json) =>
      _$ProjectListDtoFromJson(json);
}
