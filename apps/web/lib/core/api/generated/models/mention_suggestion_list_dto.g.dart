// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mention_suggestion_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MentionSuggestionListDto _$MentionSuggestionListDtoFromJson(
  Map<String, dynamic> json,
) => _MentionSuggestionListDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => MentionSuggestionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MentionSuggestionListDtoToJson(
  _MentionSuggestionListDto instance,
) => <String, dynamic>{'items': instance.items};
