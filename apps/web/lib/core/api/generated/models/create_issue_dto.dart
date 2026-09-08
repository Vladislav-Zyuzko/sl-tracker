// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'create_issue_dto_priority.dart';
import 'create_issue_dto_story_points.dart';

part 'create_issue_dto.freezed.dart';
part 'create_issue_dto.g.dart';

@Freezed()
abstract class CreateIssueDto with _$CreateIssueDto {
  const factory CreateIssueDto({
    /// Единственное обязательное поле (US-40)
    required String title,

    /// 0–100 с шагом 10. По умолчанию 50. `null` недопустим (D-15).
    @Default(CreateIssueDtoPriority.value50) CreateIssueDtoPriority priority,

    /// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43).
    String? description,

    /// Статус из набора этой очереди. По умолчанию — первый статус очереди («Открыт»).
    String? statusId,

    /// Шкала Фибоначчи. `null` или отсутствие поля — «не оценено» (D-16).
    CreateIssueDtoStoryPoints? storyPoints,

    /// Автор задачи. По умолчанию — создатель. Только участник проекта (US-53).
    String? authorId,

    /// Исполнитель. `null` — «Не назначен». Только участник проекта (US-52).
    String? assigneeId,
  }) = _CreateIssueDto;

  factory CreateIssueDto.fromJson(Map<String, Object?> json) =>
      _$CreateIssueDtoFromJson(json);
}
