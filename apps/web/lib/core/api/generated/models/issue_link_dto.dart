// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_user_dto.dart';

part 'issue_link_dto.freezed.dart';
part 'issue_link_dto.g.dart';

@Freezed()
abstract class IssueLinkDto with _$IssueLinkDto {
  const factory IssueLinkDto({
    required String id,
    required String url,

    /// Подпись. Пусто — интерфейс показывает сам адрес (US-47).
    required String? title,
    required IssueUserDto createdBy,
    required DateTime createdAt,
  }) = _IssueLinkDto;

  factory IssueLinkDto.fromJson(Map<String, Object?> json) =>
      _$IssueLinkDtoFromJson(json);
}
