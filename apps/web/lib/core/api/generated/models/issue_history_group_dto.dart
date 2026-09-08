// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_history_change_dto.dart';
import 'issue_user_dto.dart';

part 'issue_history_group_dto.freezed.dart';
part 'issue_history_group_dto.g.dart';

@Freezed()
abstract class IssueHistoryGroupDto with _$IssueHistoryGroupDto {
  const factory IssueHistoryGroupDto({
    /// Идентификатор группы изменений
    required String id,
    required DateTime createdAt,

    /// `null` — изменение системное, а не человеческое (например, очистка исполнителя при исключении участника из проекта). Интерфейс показывает его как «Система», а не приписывает случайному пользователю (US-91).
    required IssueUserDto? actor,
    required List<IssueHistoryChangeDto> changes,
  }) = _IssueHistoryGroupDto;

  factory IssueHistoryGroupDto.fromJson(Map<String, Object?> json) =>
      _$IssueHistoryGroupDtoFromJson(json);
}
