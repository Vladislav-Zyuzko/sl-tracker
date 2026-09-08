// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_status_dto_category.dart';

part 'issue_status_dto.freezed.dart';
part 'issue_status_dto.g.dart';

@Freezed()
abstract class IssueStatusDto with _$IssueStatusDto {
  const factory IssueStatusDto({
    /// Машинное имя статуса в очереди
    required String key,

    /// Название для интерфейса
    required String name,

    /// Категория статуса. Активной считается задача, у которой категория не `done`; в этом списке `done` не встречается.
    required IssueStatusDtoCategory category,
  }) = _IssueStatusDto;

  factory IssueStatusDto.fromJson(Map<String, Object?> json) =>
      _$IssueStatusDtoFromJson(json);
}
