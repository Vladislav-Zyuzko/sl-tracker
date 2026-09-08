// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mention_suggestion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MentionSuggestionDto _$MentionSuggestionDtoFromJson(
  Map<String, dynamic> json,
) => _MentionSuggestionDto(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$MentionSuggestionDtoToJson(
  _MentionSuggestionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'email': instance.email,
  'avatarUrl': instance.avatarUrl,
};
