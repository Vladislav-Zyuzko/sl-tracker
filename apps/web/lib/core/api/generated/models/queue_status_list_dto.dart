// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'queue_status_dto.dart';

part 'queue_status_list_dto.freezed.dart';
part 'queue_status_list_dto.g.dart';

@Freezed()
abstract class QueueStatusListDto with _$QueueStatusListDto {
  const factory QueueStatusListDto({
    /// В фиксированном порядке отображения
    required List<QueueStatusDto> items,
  }) = _QueueStatusListDto;

  factory QueueStatusListDto.fromJson(Map<String, Object?> json) =>
      _$QueueStatusListDtoFromJson(json);
}
