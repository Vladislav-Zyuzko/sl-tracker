// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'comment_permissions_dto.dart';
import 'issue_user_dto.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

@Freezed()
abstract class CommentDto with _$CommentDto {
  const factory CommentDto({
    required String id,

    /// Текст в Markdown, как есть. Упоминания записаны токеном `@[Имя](user:<uuid>)`; актуальные имена и аватары упомянутых — в поле `mentions`, а токен, которому там ничего не соответствует, показывается **обычным текстом** (US-74).
    ///
    /// **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого (D-22).
    required String body,

    /// Автор: имя и аватар приезжают сразу
    required IssueUserDto author,

    /// Упомянутые в тексте участники проекта — **актуальные** имена и аватары: человек сменил имя в Яндекс ID, и оно поменялось во всех старых комментариях (US-74). Упоминание того, кто не состоит в проекте, сюда не попадает никогда (D-41).
    required List<IssueUserDto> mentions,

    /// Когда комментарий правили. Не `null` — в ленте помечается «изменён» (US-72).
    required DateTime? editedAt,
    required DateTime createdAt,
    required CommentPermissionsDto permissions,
  }) = _CommentDto;

  factory CommentDto.fromJson(Map<String, Object?> json) =>
      _$CommentDtoFromJson(json);
}
