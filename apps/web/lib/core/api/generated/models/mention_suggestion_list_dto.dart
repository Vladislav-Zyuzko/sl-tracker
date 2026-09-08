// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'mention_suggestion_dto.dart';

part 'mention_suggestion_list_dto.freezed.dart';
part 'mention_suggestion_list_dto.g.dart';

@Freezed()
abstract class MentionSuggestionListDto with _$MentionSuggestionListDto {
  const factory MentionSuggestionListDto({
    /// По имени по возрастанию; не более 10 совпадений
    required List<MentionSuggestionDto> items,
  }) = _MentionSuggestionListDto;

  factory MentionSuggestionListDto.fromJson(Map<String, Object?> json) =>
      _$MentionSuggestionListDtoFromJson(json);
}
