// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_member_role_dto_role.dart';

part 'update_member_role_dto.freezed.dart';
part 'update_member_role_dto.g.dart';

@Freezed()
abstract class UpdateMemberRoleDto with _$UpdateMemberRoleDto {
  const factory UpdateMemberRoleDto({
    /// Новая роль. Понизить последнего администратора нельзя — 409 `last_project_admin` (permissions.md, п. 7).
    required UpdateMemberRoleDtoRole role,
  }) = _UpdateMemberRoleDto;

  factory UpdateMemberRoleDto.fromJson(Map<String, Object?> json) =>
      _$UpdateMemberRoleDtoFromJson(json);
}
