// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'unread_count_dto.freezed.dart';
part 'unread_count_dto.g.dart';

@Freezed()
abstract class UnreadCountDto with _$UnreadCountDto {
  const factory UnreadCountDto({
    /// Точное число непрочитанных. Обрезку до «99+» делает интерфейс, а не сервер: иначе он не сможет показать точное значение до 99 (US-103).
    required num unreadCount,
  }) = _UnreadCountDto;

  factory UnreadCountDto.fromJson(Map<String, Object?> json) =>
      _$UnreadCountDtoFromJson(json);
}
