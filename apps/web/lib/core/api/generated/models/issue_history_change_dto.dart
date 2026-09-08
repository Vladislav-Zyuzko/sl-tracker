// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_history_change_dto_kind.dart';

part 'issue_history_change_dto.freezed.dart';
part 'issue_history_change_dto.g.dart';

@Freezed()
abstract class IssueHistoryChangeDto with _$IssueHistoryChangeDto {
  const factory IssueHistoryChangeDto({
    required String id,

    /// Что изменилось. `issue_created` — создание задачи; эта запись всегда самая ранняя и показывает **реального создателя**, даже если поле «Автор» потом меняли (D-13). У `description_changed` значений нет: фиксируется только факт изменения, старый текст не хранится (US-91).
    required IssueHistoryChangeDtoKind kind,

    /// Читаемое старое значение на момент изменения — имя человека, название статуса, число. `null` означает «пусто»: «не назначен» у исполнителя, «не оценено» у сложности (US-91).
    required String? oldValue,

    /// Читаемое новое значение
    required String? newValue,

    /// Идентификатор прежнего объекта (пользователя или статуса) — для аватара и ссылки
    required String? oldRefId,
    required String? newRefId,
  }) = _IssueHistoryChangeDto;

  factory IssueHistoryChangeDto.fromJson(Map<String, Object?> json) =>
      _$IssueHistoryChangeDtoFromJson(json);
}
