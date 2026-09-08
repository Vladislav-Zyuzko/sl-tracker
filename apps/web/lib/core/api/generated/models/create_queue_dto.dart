// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_queue_dto.freezed.dart';
part 'create_queue_dto.g.dart';

@Freezed()
abstract class CreateQueueDto with _$CreateQueueDto {
  const factory CreateQueueDto({
    /// Ключ очереди: 2–10 латинских букв и цифр, первый символ — буква. Приводится к верхнему регистру. Уникален **на весь трекер**, а не внутри проекта, и не меняется после создания (ADR-0004).
    required String key,
    required String name,

    /// Markdown. Исполняемое содержимое недопустимо (D-22).
    String? description,
  }) = _CreateQueueDto;

  factory CreateQueueDto.fromJson(Map<String, Object?> json) =>
      _$CreateQueueDtoFromJson(json);
}
