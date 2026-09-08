// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_queue_ref_dto.freezed.dart';
part 'issue_queue_ref_dto.g.dart';

@Freezed()
abstract class IssueQueueRefDto with _$IssueQueueRefDto {
  const factory IssueQueueRefDto({required String key, required String name}) =
      _IssueQueueRefDto;

  factory IssueQueueRefDto.fromJson(Map<String, Object?> json) =>
      _$IssueQueueRefDtoFromJson(json);
}
