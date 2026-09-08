// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_row_status_dto_category.dart';

part 'issue_row_status_dto.freezed.dart';
part 'issue_row_status_dto.g.dart';

@Freezed()
abstract class IssueRowStatusDto with _$IssueRowStatusDto {
  const factory IssueRowStatusDto({
    required String id,
    required String key,
    required String name,
    required IssueRowStatusDtoCategory category,
  }) = _IssueRowStatusDto;

  factory IssueRowStatusDto.fromJson(Map<String, Object?> json) =>
      _$IssueRowStatusDtoFromJson(json);
}
