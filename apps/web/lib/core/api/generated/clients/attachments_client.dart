// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/attachment_dto.dart';
import '../models/attachment_list_dto.dart';

part 'attachments_client.g.dart';

@RestApi()
abstract class AttachmentsClient {
  factory AttachmentsClient(Dio dio, {String? baseUrl}) = _AttachmentsClient;

  /// Вложения задачи.
  ///
  /// Видны всем участникам проекта, включая читателя. Порядок — по времени добавления. У каждого вложения приходят подписанные ссылки на просмотр и на скачивание; они действуют 10 минут, поэтому кэшировать их надолго нельзя.
  ///
  /// [key] - Ключ задачи, регистронезависим.
  ///
  /// [cursor] - Курсор следующей порции из поля `nextCursor`.
  @GET('/api/issues/{key}/attachments')
  Future<AttachmentListDto> attachmentsControllerList({
    @Path('key') required String key,
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 50,
  });

  /// Приложить файл.
  ///
  /// Администратор и участник проекта; читатель — 403 (US-46). Один файл в поле `file`, **любой тип**, до 25 МБ (D-21). Несколько файлов загружаются несколькими запросами: так у каждого свой прогресс и своя ошибка, и один отклонённый файл не отменяет остальные.
  ///
  /// Тип определяется по содержимому файла, а не по заголовку и не по расширению; имя объекта в хранилище генерирует сервер, исходное имя сохраняется только для показа и скачивания. Добавление попадает в историю задачи.
  @MultiPart()
  @POST('/api/issues/{key}/attachments')
  Future<AttachmentDto> attachmentsControllerUpload({
    @Path('key') required String key,
    @Part(name: 'file') required MultipartFile file,
  });

  /// Удалить вложение.
  ///
  /// Администратор проекта — любое вложение, участник — **только своё**, читатель — никакое (US-46). Удаление попадает в историю задачи; файл убирается из хранилища.
  @DELETE('/api/issues/{key}/attachments/{attachmentId}')
  Future<void> attachmentsControllerRemove({
    @Path('key') required String key,
    @Path('attachmentId') required String attachmentId,
  });
}
