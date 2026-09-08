// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment_dto.dart';

part 'attachment_list_dto.freezed.dart';
part 'attachment_list_dto.g.dart';

@Freezed()
abstract class AttachmentListDto with _$AttachmentListDto {
  const factory AttachmentListDto({
    /// Сначала старые, в порядке добавления
    required List<AttachmentDto> items,
    required String? nextCursor,

    /// Всего вложений у задачи
    required num total,

    /// Может ли запросивший приложить файл. `false` у читателя (US-46, D-29).
    required bool canUpload,
  }) = _AttachmentListDto;

  factory AttachmentListDto.fromJson(Map<String, Object?> json) =>
      _$AttachmentListDtoFromJson(json);
}
