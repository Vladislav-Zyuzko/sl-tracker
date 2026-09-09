import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Вложения задачи (US-46, US-48).
class AttachmentsRepository {
  /// @nodoc
  const AttachmentsRepository(this._client);

  final AttachmentsClient _client;

  /// Порция списка.
  static const pageSize = 50;

  /// Предел размера файла — 25 МБ (D-21).
  ///
  /// Проверяется на клиенте до отправки: гонять 40 МБ по сети ради 413
  /// невежливо, а человек узнаёт об отказе мгновенно.
  static const maxFileSizeBytes = 26214400;

  /// Список вложений.
  ///
  /// Ссылки в ответе подписанные и живут 10 минут, поэтому список
  /// перезапрашивается, а ссылки **не кэшируются** дольше сессии экрана.
  Future<AttachmentListDto> list(String issueKey, {String? cursor}) async {
    try {
      return await _client.attachmentsControllerList(
        key: issueKey,
        cursor: cursor,
        limit: pageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Загружает файл.
  ///
  /// Один файл за запрос — так у каждого своя ошибка, и один отклонённый
  /// не отменяет остальные (US-46).
  ///
  /// Процента загрузки здесь нет и взяться ему неоткуда: сгенерированный
  /// клиент не пробрасывает `onSendProgress` из `dio`, а обходить генератор
  /// ради полоски — плохой размен. Плитка показывает неопределённый прогресс,
  /// а точный процент вернётся, когда в контракте появится `@SendProgress`.
  Future<AttachmentDto> upload(String issueKey, PickedFile file) async {
    try {
      return await _client.attachmentsControllerUpload(
        key: issueKey,
        file: MultipartFile.fromBytes(
          file.bytes,
          filename: file.name,
          // Тип, о котором сказал браузер, — подсказка: сервер определяет
          // его по содержимому файла.
          contentType: file.mimeType.isEmpty
              ? null
              : DioMediaType.parse(file.mimeType),
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет вложение: администратор — любое, участник — только своё.
  Future<void> remove(String issueKey, String attachmentId) async {
    try {
      await _client.attachmentsControllerRemove(
        key: issueKey,
        attachmentId: attachmentId,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final attachmentsRepositoryProvider = Provider<AttachmentsRepository>(
  (ref) => AttachmentsRepository(ref.watch(apiClientProvider).attachments),
);

/// Подсказка упоминаний (US-74).
class MentionsRepository {
  /// @nodoc
  const MentionsRepository(this._client);

  final MentionsClient _client;

  /// Сколько строк показывает подсказка.
  static const limit = 10;

  /// Участники проекта, подходящие под строку после `@`.
  ///
  /// Ищет **только среди участников проекта задачи** — так устроен сервер
  /// (D-41, ADR-0006, п. 6). Дополнять выдачу своим поиском по трекеру
  /// нельзя: это ровно та защита состава трекера от перебора, ради которой
  /// маршрут и сделан отдельным.
  Future<List<MentionSuggestionDto>> suggest(
    String issueKey, {
    required String query,
  }) async {
    try {
      final result = await _client.mentionSuggestionsControllerSuggest(
        key: issueKey,
        query: query,
        limit: limit,
      );

      return result.items;
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final mentionsRepositoryProvider = Provider<MentionsRepository>(
  (ref) => MentionsRepository(ref.watch(apiClientProvider).mentions),
);
