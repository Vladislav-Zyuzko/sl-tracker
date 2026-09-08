// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_payload_dto_source.dart';

part 'notification_payload_dto.freezed.dart';
part 'notification_payload_dto.g.dart';

@Freezed()
abstract class NotificationPayloadDto with _$NotificationPayloadDto {
  const factory NotificationPayloadDto({
    /// Ключ задачи на момент события
    String? issueKey,
    String? issueTitle,

    /// Статус до перехода. Только `issue_status_changed`.
    String? fromStatusName,

    /// Статус после перехода. Только `issue_status_changed`.
    String? toStatusName,

    /// Начало текста, ~100 символов: комментарий (`issue_commented`) либо текст с упоминанием (`issue_mentioned`). Упоминания развёрнуты в `@Имя`, **разметка Markdown не снята** — её убирает клиент при отрисовке превью (US-102).
    String? excerpt,

    /// Где находится упоминание. `description` — в описании задачи: прокручивать надо к описанию, а не к комментарию (US-104). Только `issue_mentioned`.
    NotificationPayloadDtoSource? source,

    /// Только `project_member_joined`
    String? projectSlug,

    /// Только `project_member_joined`
    String? projectName,

    /// Имя вступившего. Только `project_member_joined`.
    String? memberName,
  }) = _NotificationPayloadDto;

  factory NotificationPayloadDto.fromJson(Map<String, Object?> json) =>
      _$NotificationPayloadDtoFromJson(json);
}
