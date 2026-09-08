// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_member_dto.dart';

part 'project_member_list_dto.freezed.dart';
part 'project_member_list_dto.g.dart';

@Freezed()
abstract class ProjectMemberListDto with _$ProjectMemberListDto {
  const factory ProjectMemberListDto({
    /// Сначала администраторы, дальше по имени (design/screens/project.md)
    required List<ProjectMemberDto> items,
    required String? nextCursor,

    /// Всего участников в проекте
    required num total,
  }) = _ProjectMemberListDto;

  factory ProjectMemberListDto.fromJson(Map<String, Object?> json) =>
      _$ProjectMemberListDtoFromJson(json);
}
