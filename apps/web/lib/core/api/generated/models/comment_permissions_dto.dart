// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_permissions_dto.freezed.dart';
part 'comment_permissions_dto.g.dart';

@Freezed()
abstract class CommentPermissionsDto with _$CommentPermissionsDto {
  const factory CommentPermissionsDto({
    /// Править может **только автор**, независимо от роли: администратор чужой комментарий не редактирует (US-72).
    required bool canEdit,

    /// Свой комментарий удаляет автор, чужой — только администратор проекта (US-73).
    required bool canDelete,
  }) = _CommentPermissionsDto;

  factory CommentPermissionsDto.fromJson(Map<String, Object?> json) =>
      _$CommentPermissionsDtoFromJson(json);
}
