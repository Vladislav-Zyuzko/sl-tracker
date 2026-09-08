// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'create_invitation_dto_expires_in_days.dart';
import 'create_invitation_dto_role.dart';

part 'create_invitation_dto.freezed.dart';
part 'create_invitation_dto.g.dart';

@Freezed()
abstract class CreateInvitationDto with _$CreateInvitationDto {
  const factory CreateInvitationDto({
    /// Роль для тех, кто вступит. Роли «администратор» в списке нет (D-05).
    required CreateInvitationDtoRole role,

    /// Срок жизни ссылки в днях. Бессрочных приглашений нет (US-20).
    @Default(CreateInvitationDtoExpiresInDays.value7)
    CreateInvitationDtoExpiresInDays expiresInDays,
  }) = _CreateInvitationDto;

  factory CreateInvitationDto.fromJson(Map<String, Object?> json) =>
      _$CreateInvitationDtoFromJson(json);
}
