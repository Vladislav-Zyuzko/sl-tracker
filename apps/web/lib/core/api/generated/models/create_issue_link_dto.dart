// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_issue_link_dto.freezed.dart';
part 'create_issue_link_dto.g.dart';

@Freezed()
abstract class CreateIssueLinkDto with _$CreateIssueLinkDto {
  const factory CreateIssueLinkDto({
    /// Только схемы `http` и `https` (US-47)
    required String url,

    /// Подпись. Пусто — интерфейс показывает сам адрес.
    String? title,
  }) = _CreateIssueLinkDto;

  factory CreateIssueLinkDto.fromJson(Map<String, Object?> json) =>
      _$CreateIssueLinkDtoFromJson(json);
}
