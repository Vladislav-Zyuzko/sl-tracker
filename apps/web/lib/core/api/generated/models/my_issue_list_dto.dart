// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'my_issue_dto.dart';

part 'my_issue_list_dto.freezed.dart';
part 'my_issue_list_dto.g.dart';

@Freezed()
abstract class MyIssueListDto with _$MyIssueListDto {
  const factory MyIssueListDto({
    /// Приоритет по убыванию, при равенстве — сначала недавно изменённые
    required List<MyIssueDto> items,
    required String? nextCursor,

    /// Всего активных задач у пользователя, **без учёта поиска**: счётчик у заголовка
    required num total,
  }) = _MyIssueListDto;

  factory MyIssueListDto.fromJson(Map<String, Object?> json) =>
      _$MyIssueListDtoFromJson(json);
}
