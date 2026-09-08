// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_issue_dto_priority.dart';
import 'update_issue_dto_story_points.dart';

part 'update_issue_dto.freezed.dart';
part 'update_issue_dto.g.dart';

@Freezed()
abstract class UpdateIssueDto with _$UpdateIssueDto {
  const factory UpdateIssueDto({
    String? title,

    /// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43). `null` или пустая строка очищают описание.
    String? description,

    /// Новый статус. Переход разрешён из любого статуса очереди в любой другой, включая возврат назад и закрытие из любого состояния (D-10). Статус чужой очереди отклоняется.
    String? statusId,
    UpdateIssueDtoPriority? priority,

    /// `null` снимает оценку и возвращает «не оценено» (US-51).
    UpdateIssueDtoStoryPoints? storyPoints,

    /// Новый автор — любой участник проекта. Очистить поле нельзя. Смена автора логируется отдельной записью истории; создатель задачи при этом не меняется (D-13).
    String? authorId,

    /// `null` снимает исполнителя и возвращает «Не назначен».
    String? assigneeId,
  }) = _UpdateIssueDto;

  factory UpdateIssueDto.fromJson(Map<String, Object?> json) =>
      _$UpdateIssueDtoFromJson(json);
}
