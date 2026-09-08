// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_member_preview_dto_role.dart';

part 'project_member_preview_dto.freezed.dart';
part 'project_member_preview_dto.g.dart';

@Freezed()
abstract class ProjectMemberPreviewDto with _$ProjectMemberPreviewDto {
  const factory ProjectMemberPreviewDto({
    required String id,
    required String displayName,
    required String? avatarUrl,
    required ProjectMemberPreviewDtoRole role,
  }) = _ProjectMemberPreviewDto;

  factory ProjectMemberPreviewDto.fromJson(Map<String, Object?> json) =>
      _$ProjectMemberPreviewDtoFromJson(json);
}
