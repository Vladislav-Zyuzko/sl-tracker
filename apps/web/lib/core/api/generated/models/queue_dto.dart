// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'queue_dto_role.dart';

part 'queue_dto.freezed.dart';
part 'queue_dto.g.dart';

@Freezed()
abstract class QueueDto with _$QueueDto {
  const factory QueueDto({
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
    required QueueDtoRole role,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _QueueDto;

  factory QueueDto.fromJson(Map<String, Object?> json) =>
      _$QueueDtoFromJson(json);
}
