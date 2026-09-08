// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_project_ref_dto.freezed.dart';
part 'issue_project_ref_dto.g.dart';

@Freezed()
abstract class IssueProjectRefDto with _$IssueProjectRefDto {
  const factory IssueProjectRefDto({
    required String slug,
    required String name,
  }) = _IssueProjectRefDto;

  factory IssueProjectRefDto.fromJson(Map<String, Object?> json) =>
      _$IssueProjectRefDtoFromJson(json);
}
