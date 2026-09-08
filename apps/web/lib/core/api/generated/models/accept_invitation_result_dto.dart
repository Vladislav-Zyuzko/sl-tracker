// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'accept_invitation_result_dto_role.dart';

part 'accept_invitation_result_dto.freezed.dart';
part 'accept_invitation_result_dto.g.dart';

@Freezed()
abstract class AcceptInvitationResultDto with _$AcceptInvitationResultDto {
  const factory AcceptInvitationResultDto({
    /// Куда переходить после вступления
    required String projectSlug,

    /// Роль пользователя в проекте после приёма
    required AcceptInvitationResultDtoRole role,

    /// Пользователь уже был участником; роль не изменилась
    required bool alreadyMember,
  }) = _AcceptInvitationResultDto;

  factory AcceptInvitationResultDto.fromJson(Map<String, Object?> json) =>
      _$AcceptInvitationResultDtoFromJson(json);
}
