// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_status_full_dto_category.dart';

part 'issue_status_full_dto.freezed.dart';
part 'issue_status_full_dto.g.dart';

@Freezed()
abstract class IssueStatusFullDto with _$IssueStatusFullDto {
  const factory IssueStatusFullDto({
    required String id,
    required String key,
    required String name,
    required IssueStatusFullDtoCategory category,
    required num position,
  }) = _IssueStatusFullDto;

  factory IssueStatusFullDto.fromJson(Map<String, Object?> json) =>
      _$IssueStatusFullDtoFromJson(json);
}
