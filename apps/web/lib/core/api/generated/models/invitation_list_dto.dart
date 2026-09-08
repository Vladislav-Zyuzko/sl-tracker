// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'invitation_dto.dart';

part 'invitation_list_dto.freezed.dart';
part 'invitation_list_dto.g.dart';

@Freezed()
abstract class InvitationListDto with _$InvitationListDto {
  const factory InvitationListDto({
    /// Сначала новые
    required List<InvitationDto> items,
    required String? nextCursor,

    /// Всего приглашений у проекта, включая истёкшие и отозванные
    required num total,
  }) = _InvitationListDto;

  factory InvitationListDto.fromJson(Map<String, Object?> json) =>
      _$InvitationListDtoFromJson(json);
}
