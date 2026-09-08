// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_status_dto.dart';

part 'my_issue_dto.freezed.dart';
part 'my_issue_dto.g.dart';

@Freezed()
abstract class MyIssueDto with _$MyIssueDto {
  const factory MyIssueDto({
    /// Публичный ключ задачи, он же адрес
    required String key,

    /// Тема задачи
    required String title,

    /// Приоритет 0–100 с шагом 10. Список отсортирован по нему по убыванию.
    required num priority,
    required IssueStatusDto status,
  }) = _MyIssueDto;

  factory MyIssueDto.fromJson(Map<String, Object?> json) =>
      _$MyIssueDtoFromJson(json);
}
