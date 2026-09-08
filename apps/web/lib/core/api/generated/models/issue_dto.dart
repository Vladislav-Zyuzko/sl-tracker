// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_dto_priority.dart';
import 'issue_dto_role.dart';
import 'issue_dto_story_points.dart';
import 'issue_link_dto.dart';
import 'issue_permissions_dto.dart';
import 'issue_project_ref_dto.dart';
import 'issue_queue_ref_dto.dart';
import 'issue_status_full_dto.dart';
import 'issue_user_dto.dart';

part 'issue_dto.freezed.dart';
part 'issue_dto.g.dart';

@Freezed()
abstract class IssueDto with _$IssueDto {
  const factory IssueDto({
    /// Публичный ключ задачи, он же адрес
    required String key,
    required String title,

    /// Описание в Markdown. Хранится как текст и рендерится клиентом. **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого — сырой HTML и скрипты не исполняются, ссылки со схемами кроме `http`, `https`, `mailto` не становятся кликабельными (D-22, US-43).
    required String? description,
    required IssueStatusFullDto status,

    /// Приоритет: 11 значений от 0 до 100 с шагом 10, больше — важнее. Пустым **не бывает никогда**: состояния «не задан» у поля нет, 0 — это «Низкий» (D-15).
    required IssueDtoPriority priority,

    /// Сложность по шкале Фибоначчи. `null` — «не оценено» (D-16).
    required IssueDtoStoryPoints? storyPoints,

    /// Автор задачи. Редактируется, пустым не бывает.
    required IssueUserDto author,

    /// Исполнитель. `null` — «Не назначен».
    required IssueUserDto? assignee,
    required IssueQueueRefDto queue,
    required IssueProjectRefDto project,

    /// Внешние ссылки задачи (US-47)
    required List<IssueLinkDto> links,

    /// Роль запросившего в проекте задачи
    required IssueDtoRole role,
    required IssuePermissionsDto permissions,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _IssueDto;

  factory IssueDto.fromJson(Map<String, Object?> json) =>
      _$IssueDtoFromJson(json);
}
