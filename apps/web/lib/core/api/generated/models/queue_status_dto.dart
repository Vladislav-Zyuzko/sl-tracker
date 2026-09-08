// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'queue_status_dto_category.dart';

part 'queue_status_dto.freezed.dart';
part 'queue_status_dto.g.dart';

@Freezed()
abstract class QueueStatusDto with _$QueueStatusDto {
  const factory QueueStatusDto({
    /// Идентификатор статуса: его кладут в задачу
    required String id,

    /// Машинное имя статуса внутри очереди
    required String key,

    /// Название для интерфейса
    required String name,

    /// Категория статуса. Задача считается незавершённой, пока категория не `done`. Опираться нужно на категорию, а не на `key` и не на порядок (ADR-0003).
    required QueueStatusDtoCategory category,

    /// Порядок отображения, начиная с 1
    required num position,
  }) = _QueueStatusDto;

  factory QueueStatusDto.fromJson(Map<String, Object?> json) =>
      _$QueueStatusDtoFromJson(json);
}
