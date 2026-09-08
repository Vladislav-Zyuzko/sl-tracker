// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_author_dto.freezed.dart';
part 'invitation_author_dto.g.dart';

@Freezed()
abstract class InvitationAuthorDto with _$InvitationAuthorDto {
  const factory InvitationAuthorDto({
    required String id,
    required String? displayName,
  }) = _InvitationAuthorDto;

  factory InvitationAuthorDto.fromJson(Map<String, Object?> json) =>
      _$InvitationAuthorDtoFromJson(json);
}
