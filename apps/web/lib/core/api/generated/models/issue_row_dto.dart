// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_row_status_dto.dart';
import 'issue_user_dto.dart';

part 'issue_row_dto.freezed.dart';
part 'issue_row_dto.g.dart';

@Freezed()
abstract class IssueRowDto with _$IssueRowDto {
  const factory IssueRowDto({
    required String key,
    required String title,
    required IssueRowStatusDto status,
    required num priority,

    /// `null` — «не оценено»
    required num? storyPoints,

    /// `null` — «Не назначен»
    required IssueUserDto? assignee,
  }) = _IssueRowDto;

  factory IssueRowDto.fromJson(Map<String, Object?> json) =>
      _$IssueRowDtoFromJson(json);
}
