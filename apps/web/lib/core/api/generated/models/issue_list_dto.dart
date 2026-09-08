// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_list_dto_role.dart';
import 'issue_row_dto.dart';

part 'issue_list_dto.freezed.dart';
part 'issue_list_dto.g.dart';

@Freezed()
abstract class IssueListDto with _$IssueListDto {
  const factory IssueListDto({
    required List<IssueRowDto> items,

    /// Курсор следующей порции. `null` — задачи кончились.
    required String? nextCursor,

    /// Сколько задач подходит под текущие фильтры — счётчик «Показано N».
    required num total,

    /// Роль запросившего в проекте очереди: по ней прячется кнопка «Создать задачу».
    IssueListDtoRole? role,
  }) = _IssueListDto;

  factory IssueListDto.fromJson(Map<String, Object?> json) =>
      _$IssueListDtoFromJson(json);
}
