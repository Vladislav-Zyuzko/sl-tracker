// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'created_queue_dto_role.dart';
import 'queue_status_dto.dart';

part 'created_queue_dto.freezed.dart';
part 'created_queue_dto.g.dart';

@Freezed()
abstract class CreatedQueueDto with _$CreatedQueueDto {
  const factory CreatedQueueDto({
    /// Ключ очереди. Уникален на весь трекер, неизменяем
    required String key,
    required String name,

    /// Markdown, до 1000 символов
    required String? description,

    /// Короткое имя проекта в адресе
    required String projectSlug,

    /// Название проекта для хлебных крошек
    required String projectName,

    /// Незавершённые задачи: те, чей статус не в категории `done` (US-31)
    required num openIssueCount,

    /// Роль запросившего в проекте, которому принадлежит очередь. Права на очередь наследуются от проекта: прав уровня очереди в MVP нет (permissions.md, п. 3).
    required CreatedQueueDtoRole role,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Пять статусов по умолчанию, созданных вместе с очередью (US-60)
    required List<QueueStatusDto> statuses,
  }) = _CreatedQueueDto;

  factory CreatedQueueDto.fromJson(Map<String, Object?> json) =>
      _$CreatedQueueDtoFromJson(json);
}
