// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'invitation_preview_dto_role.dart';

part 'invitation_preview_dto.freezed.dart';
part 'invitation_preview_dto.g.dart';

@Freezed()
abstract class InvitationPreviewDto with _$InvitationPreviewDto {
  const factory InvitationPreviewDto({
    required String projectName,
    required String projectSlug,

    /// Подписанная ссылка на обложку
    required String? coverUrl,

    /// Роль, которую человек получит. Если он уже участник — его текущая роль: приглашение её не меняет и не понижает (US-21).
    required InvitationPreviewDtoRole role,

    /// Пользователь уже состоит в проекте: экран подтверждения не показывается, клиент сразу открывает проект (US-21).
    required bool alreadyMember,
  }) = _InvitationPreviewDto;

  factory InvitationPreviewDto.fromJson(Map<String, Object?> json) =>
      _$InvitationPreviewDtoFromJson(json);
}
