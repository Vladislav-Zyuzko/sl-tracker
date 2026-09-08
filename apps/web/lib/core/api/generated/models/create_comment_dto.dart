// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_comment_dto.freezed.dart';
part 'create_comment_dto.g.dart';

@Freezed()
abstract class CreateCommentDto with _$CreateCommentDto {
  const factory CreateCommentDto({
    /// Markdown. Пустой текст и текст из одних пробелов отклоняются (US-71). Упоминание вставляется токеном `@[Имя](user:<uuid>)`, идентификатор берётся из подсказки `GET /api/issues/{key}/mention-suggestions`. Токен с посторонним пользователем **молча игнорируется**: связи и уведомления не будет, текст останется текстом (D-41).
    required String body,
  }) = _CreateCommentDto;

  factory CreateCommentDto.fromJson(Map<String, Object?> json) =>
      _$CreateCommentDtoFromJson(json);
}
