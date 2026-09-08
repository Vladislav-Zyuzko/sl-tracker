// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/my_issue_list_dto.dart';

part 'issues_client.g.dart';

@RestApi()
abstract class IssuesClient {
  factory IssuesClient(Dio dio, {String? baseUrl}) = _IssuesClient;

  /// Мои активные задачи.
  ///
  /// Задачи, где текущий пользователь — исполнитель, а категория статуса **не** `done` (US-81). Других условий нет. Задачи собираются из всех проектов, где пользователь состоит. Порядок: приоритет по убыванию, при равенстве — сначала недавно изменённые. Параметр `q` ищет по подстроке в теме и в ключе среди этого же набора; поиск выполняет сервер (D-20).
  ///
  /// [cursor] - Курсор следующей страницы из поля `nextCursor`.
  ///
  /// [q] - Поиск по подстроке в теме и в ключе, без учёта регистра. Ищет только среди активных задач текущего пользователя (D-20).
  @GET('/api/issues/my-active')
  Future<MyIssueListDto> myIssuesControllerMyActive({
    @Query('cursor') String? cursor,
    @Query('q') String? q,
    @Query('limit') num? limit = 50,
  });
}
