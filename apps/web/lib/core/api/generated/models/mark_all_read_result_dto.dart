// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mark_all_read_result_dto.freezed.dart';
part 'mark_all_read_result_dto.g.dart';

@Freezed()
abstract class MarkAllReadResultDto with _$MarkAllReadResultDto {
  const factory MarkAllReadResultDto({
    /// Сколько уведомлений стало прочитанными
    required num updated,
  }) = _MarkAllReadResultDto;

  factory MarkAllReadResultDto.fromJson(Map<String, Object?> json) =>
      _$MarkAllReadResultDtoFromJson(json);
}
