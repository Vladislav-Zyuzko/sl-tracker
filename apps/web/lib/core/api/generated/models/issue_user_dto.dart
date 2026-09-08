// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_user_dto.freezed.dart';
part 'issue_user_dto.g.dart';

@Freezed()
abstract class IssueUserDto with _$IssueUserDto {
  const factory IssueUserDto({
    required String id,
    required String displayName,
    required String? avatarUrl,
  }) = _IssueUserDto;

  factory IssueUserDto.fromJson(Map<String, Object?> json) =>
      _$IssueUserDtoFromJson(json);
}
