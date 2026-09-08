// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_suggestion_dto.freezed.dart';
part 'mention_suggestion_dto.g.dart';

@Freezed()
abstract class MentionSuggestionDto with _$MentionSuggestionDto {
  const factory MentionSuggestionDto({
    /// Подставляется в токен `@[Имя](user:<uuid>)`
    required String id,
    required String displayName,

    /// Показывается второй строкой **только при совпадении имён** (US-74). Адрес виден лишь по участникам того же проекта — там он и так есть на вкладке «Участники».
    required String email,
    required String? avatarUrl,
  }) = _MentionSuggestionDto;

  factory MentionSuggestionDto.fromJson(Map<String, Object?> json) =>
      _$MentionSuggestionDtoFromJson(json);
}
