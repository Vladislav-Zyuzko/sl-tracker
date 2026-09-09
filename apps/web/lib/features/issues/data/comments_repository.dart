import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';

/// Комментарии задачи (US-70 … US-74).
class CommentsRepository {
  /// @nodoc
  const CommentsRepository(this._client);

  final CommentsClient _client;

  /// Порция ленты. 50 — умолчание контракта, жёсткий максимум 100.
  static const pageSize = 50;

  /// Порция комментариев.
  ///
  /// Пагинация идёт **назад по времени**: запрос без курсора отдаёт
  /// последние комментарии задачи, а `nextCursor` ведёт к более ранним —
  /// это кнопка «Показать более ранние» над лентой. Внутри страницы порядок
  /// хронологический, сначала старые (US-70).
  Future<CommentListDto> list(String issueKey, {String? cursor}) async {
    try {
      return await _client.commentsControllerList(
        key: issueKey,
        cursor: cursor,
        limit: pageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Пишет комментарий (US-71).
  ///
  /// Упоминание вставляется токеном `@[Имя](user:<uuid>)`; идентификатор
  /// берётся из подсказки, а не придумывается клиентом. Токен с посторонним
  /// сервер игнорирует молча — ошибки не будет, текст останется текстом.
  Future<CommentDto> create(String issueKey, String body) async {
    try {
      return await _client.commentsControllerCreate(
        key: issueKey,
        body: CreateCommentDto(body: body),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Правит свой комментарий (US-72). Чужой не правит даже администратор.
  Future<CommentDto> update(
    String issueKey,
    String commentId,
    String body,
  ) async {
    try {
      return await _client.commentsControllerUpdate(
        key: issueKey,
        commentId: commentId,
        body: UpdateCommentDto(body: body),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет комментарий (US-73). Удаление физическое: плашки «удалён»
  /// в ленте не остаётся.
  Future<void> remove(String issueKey, String commentId) async {
    try {
      await _client.commentsControllerRemove(
        key: issueKey,
        commentId: commentId,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => CommentsRepository(ref.watch(apiClientProvider).comments),
);
