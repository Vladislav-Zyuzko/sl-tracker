// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_history_group_dto.dart';

part 'issue_history_list_dto.freezed.dart';
part 'issue_history_list_dto.g.dart';

@Freezed()
abstract class IssueHistoryListDto with _$IssueHistoryListDto {
  const factory IssueHistoryListDto({
    /// Сначала новые (US-90). Страница считается по группам, а не по отдельным записям: одно действие никогда не разрывается границей страницы.
    required List<IssueHistoryGroupDto> items,
    required String? nextCursor,

    /// Всего действий по задаче. Минимум одно есть всегда — «Задача создана».
    required num total,
  }) = _IssueHistoryListDto;

  factory IssueHistoryListDto.fromJson(Map<String, Object?> json) =>
      _$IssueHistoryListDtoFromJson(json);
}
