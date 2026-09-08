// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_user_dto.dart';
import 'notification_dto_channel.dart';
import 'notification_dto_type.dart';
import 'notification_payload_dto.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

@Freezed()
abstract class NotificationDto with _$NotificationDto {
  const factory NotificationDto({
    required String id,

    /// Тип события. От него зависит текст строки и то, какие поля заполнены в `payload` (design/screens/notifications.md).
    required NotificationDtoType type,

    /// Канал доставки. В MVP всегда `in_app` (D-18).
    required NotificationDtoChannel channel,

    /// Кто инициировал событие. `null` — системное событие: в ленте вместо аватара иконка, а не случайный пользователь.
    required IssueUserDto? actor,

    /// Ключ задачи **сейчас**. `null` означает, что задачи больше нет или она в проекте, из которого пользователя исключили: переход по такому уведомлению показывает «Задача не найдена» (US-103). Текст строки берётся из `payload.issueKey`.
    required String? issueKey,

    /// Короткое имя проекта — адрес перехода для `project_member_joined` (US-23)
    required String? projectSlug,

    /// Комментарий, к которому нужно прокрутить задачу (`/issues/DEV-42?comment=<id>`). `null` у удалённого комментария — тогда открывается сама задача, и клиент показывает «Комментарий удалён» (US-102).
    required String? commentId,
    required NotificationPayloadDto payload,

    /// `null` — непрочитанное: точка слева и жирное имя инициатора
    required DateTime? readAt,
    required DateTime createdAt,
  }) = _NotificationDto;

  factory NotificationDto.fromJson(Map<String, Object?> json) =>
      _$NotificationDtoFromJson(json);
}
