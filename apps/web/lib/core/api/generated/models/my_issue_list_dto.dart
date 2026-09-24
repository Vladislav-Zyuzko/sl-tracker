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

    /// Сколько активных задач подходит под запрос: счётчик у заголовка списка. Поиск `q` учитывается — при поиске без совпадений это `0`, а не число всех задач.
    required num total,
  }) = _MyIssueListDto;

  factory MyIssueListDto.fromJson(Map<String, Object?> json) =>
      _$MyIssueListDtoFromJson(json);
}
