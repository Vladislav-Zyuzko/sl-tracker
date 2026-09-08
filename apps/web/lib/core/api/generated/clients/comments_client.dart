// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment_dto.dart';
import '../models/comment_list_dto.dart';
import '../models/create_comment_dto.dart';
import '../models/update_comment_dto.dart';

part 'comments_client.g.dart';

@RestApi()
abstract class CommentsClient {
  factory CommentsClient(Dio dio, {String? baseUrl}) = _CommentsClient;

  /// Комментарии задачи.
  ///
  /// Плоская лента в хронологическом порядке, **сначала старые** (US-70). Видна всем участникам проекта, включая читателя.
  ///
  /// Пагинация идёт **назад по времени**: запрос без курсора отдаёт последние `limit` комментариев, а `nextCursor` ведёт к более ранним — это кнопка «Показать более ранние» над лентой. `limit` по умолчанию 50, жёсткий максимум 100.
  ///
  /// Автор каждого комментария и упомянутые в нём участники приходят сразу: второй запрос за именами и аватарами не нужен.
  ///
  /// [key] - Ключ задачи, регистронезависим.
  ///
  /// [cursor] - Курсор более ранней порции из поля `nextCursor`.
  @GET('/api/issues/{key}/comments')
  Future<CommentListDto> commentsControllerList({
    @Path('key') required String key,
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 50,
  });

  /// Написать комментарий.
  ///
  /// Администратор и участник проекта; читатель — 403 (US-71, D-29). Пустой текст и текст из одних пробелов отклоняются, максимум — 10 000 символов.
  ///
  /// Автор комментария становится подписчиком задачи и дальше получает уведомления по ней (D-17). Подписчики задачи, кроме автора комментария, получают уведомление (US-102); упомянутые — уведомление об упоминании вместо него, то есть **одно, а не два** (US-104).
  ///
  /// Упоминание записывается токеном `@[Имя](user:<uuid>)`. Упомянуть можно **только участника проекта задачи**: токен с посторонним игнорируется молча — без ошибки, без связи и без уведомления (D-41, ADR-0006, п. 6).
  @POST('/api/issues/{key}/comments')
  Future<CommentDto> commentsControllerCreate({
    @Path('key') required String key,
    @Body() required CreateCommentDto body,
  });

  /// Изменить свой комментарий.
  ///
  /// Править может **только автор** — администратор чужой комментарий не редактирует и получает 403 (US-72). Срок правки не ограничен. После сохранения проставляется `editedAt`, и в ленте появляется пометка «изменён».
  ///
  /// Уведомление создаётся только **вновь** упомянутым: ранее упомянутые повторно не уведомляются, нового уведомления о комментарии правка не создаёт (US-74, US-102).
  @PATCH('/api/issues/{key}/comments/{commentId}')
  Future<CommentDto> commentsControllerUpdate({
    @Path('key') required String key,
    @Path('commentId') required String commentId,
    @Body() required UpdateCommentDto body,
  });

  /// Удалить комментарий.
  ///
  /// Свой комментарий удаляет автор, чужой — только администратор проекта; участник чужой удалить не может (US-73).
  ///
  /// Удаление физическое: текст не остаётся нигде, плашки «комментарий удалён» в ленте нет. В историю задачи попадает факт удаления — кто удалил и чей комментарий, **без текста** (US-91). Уведомления, которые на него ссылались, остаются в центре уведомлений, но теряют ссылку на комментарий (US-102). Новых уведомлений удаление не создаёт.
  @DELETE('/api/issues/{key}/comments/{commentId}')
  Future<void> commentsControllerRemove({
    @Path('key') required String key,
    @Path('commentId') required String commentId,
  });
}
