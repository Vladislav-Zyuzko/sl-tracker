// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'issue_user_dto.dart';

part 'attachment_dto.freezed.dart';
part 'attachment_dto.g.dart';

@Freezed()
abstract class AttachmentDto with _$AttachmentDto {
  const factory AttachmentDto({
    required String id,

    /// Имя файла как его назвал загрузивший
    required String fileName,

    /// Тип, определённый **по содержимому файла**, а не по заголовку запроса и не по расширению. Неопознанное содержимое — `application/octet-stream`.
    required String contentType,

    /// Размер в байтах, максимум 26 214 400 (25 МБ)
    required num sizeBytes,

    /// Показывать превью в задаче. Верно для image/png, image/jpeg, image/webp, image/gif (US-46).
    required bool isImage,

    /// Подписанная ссылка на содержимое, живёт 10 минут. Бакет не публичный: та же ссылка без подписи ничего не отдаёт, и посторонний файл не получит (US-46, D-21). Ссылка выдаётся заново при каждом запросе списка — сохранять её надолго нельзя.
    required String url,

    /// Та же подписанная ссылка, но с `Content-Disposition: attachment`: браузер скачивает файл под исходным именем, хотя в хранилище он лежит под именем, сгенерированным сервером.
    required String downloadUrl,

    /// Кто приложил
    required IssueUserDto uploadedBy,
    required DateTime createdAt,

    /// Может ли запросивший удалить это вложение: администратор проекта — любое, участник — только своё, читатель — никакое (US-46).
    required bool canDelete,
  }) = _AttachmentDto;

  factory AttachmentDto.fromJson(Map<String, Object?> json) =>
      _$AttachmentDtoFromJson(json);
}
