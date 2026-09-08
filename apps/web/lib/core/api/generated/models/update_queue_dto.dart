// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_queue_dto.freezed.dart';
part 'update_queue_dto.g.dart';

@Freezed()
abstract class UpdateQueueDto with _$UpdateQueueDto {
  const factory UpdateQueueDto({
    String? name,

    /// Markdown. `null` или пустая строка очищают описание.
    String? description,
  }) = _UpdateQueueDto;

  factory UpdateQueueDto.fromJson(Map<String, Object?> json) =>
      _$UpdateQueueDtoFromJson(json);
}
