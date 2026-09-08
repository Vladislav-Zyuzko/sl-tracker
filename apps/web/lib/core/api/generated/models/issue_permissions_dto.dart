// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_permissions_dto.freezed.dart';
part 'issue_permissions_dto.g.dart';

@Freezed()
abstract class IssuePermissionsDto with _$IssuePermissionsDto {
  const factory IssuePermissionsDto({
    /// Менять поля, название, описание и ссылки. Участник может менять **любую** задачу проекта, а не только свою (D-11). У читателя — `false`.
    required bool canEdit,

    /// Удалить задачу. Только у администратора проекта (D-12).
    required bool canDelete,
  }) = _IssuePermissionsDto;

  factory IssuePermissionsDto.fromJson(Map<String, Object?> json) =>
      _$IssuePermissionsDtoFromJson(json);
}
