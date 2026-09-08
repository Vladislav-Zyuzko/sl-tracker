// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_member_dto_role.dart';

part 'project_member_dto.freezed.dart';
part 'project_member_dto.g.dart';

@Freezed()
abstract class ProjectMemberDto with _$ProjectMemberDto {
  const factory ProjectMemberDto({
    /// Идентификатор пользователя
    required String userId,
    required String displayName,
    required String email,
    required String? avatarUrl,
    required ProjectMemberDtoRole role,

    /// Когда вступил в проект
    required DateTime joinedAt,

    /// Это текущий пользователь: в списке помечается «(вы)»
    required bool isSelf,
  }) = _ProjectMemberDto;

  factory ProjectMemberDto.fromJson(Map<String, Object?> json) =>
      _$ProjectMemberDtoFromJson(json);
}
