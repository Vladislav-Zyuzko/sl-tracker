// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'queue_dto.dart';

part 'queue_list_dto.freezed.dart';
part 'queue_list_dto.g.dart';

@Freezed()
abstract class QueueListDto with _$QueueListDto {
  const factory QueueListDto({
    /// По названию по возрастанию (US-31)
    required List<QueueDto> items,

    /// Очередей у проекта единицы, поэтому список отдаётся целиком, без курсора
    num? total,
  }) = _QueueListDto;

  factory QueueListDto.fromJson(Map<String, Object?> json) =>
      _$QueueListDtoFromJson(json);
}
