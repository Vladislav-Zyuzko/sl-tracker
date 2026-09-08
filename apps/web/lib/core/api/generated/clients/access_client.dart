// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/access_entry_dto.dart';
import '../models/access_entry_list_dto.dart';
import '../models/create_access_entry_dto.dart';
import '../models/revoke_access_result_dto.dart';
import '../models/update_access_entry_dto.dart';

part 'access_client.g.dart';

@RestApi()
abstract class AccessClient {
  factory AccessClient(Dio dio, {String? baseUrl}) = _AccessClient;

  /// Список доступа.
  ///
  /// Записи от новых к старым, курсорная пагинация. Запись в списке даёт только вход в трекер и никаких прав внутри проектов (ADR-0006).
  ///
  /// [limit] - Размер страницы. Больше максимума не отдаём.
  ///
  /// [cursor] - Курсор следующей страницы из поля `nextCursor`.
  ///
  /// [q] - Поиск по подстроке в email и имени вошедшего (US-07).
  @GET('/api/access-entries')
  Future<AccessEntryListDto> accessControllerList({
    @Query('cursor') String? cursor,
    @Query('q') String? q,
    @Query('limit') num? limit = 50,
  });

  /// Добавить адрес в список доступа.
  ///
  /// Источник записи — `manual`, признак владельца ей не выдаётся. Человек может войти сразу, без перезапуска сервиса (US-06).
  @POST('/api/access-entries')
  Future<AccessEntryDto> accessControllerAdd({
    @Body() required CreateAccessEntryDto body,
  });

  /// Выдать или снять признак владельца трекера.
  ///
  /// Снять признак с последнего владельца нельзя: в трекере всегда есть хотя бы один владелец (US-07).
  @PATCH('/api/access-entries/{id}')
  Future<AccessEntryDto> accessControllerUpdate({
    @Path('id') required String id,
    @Body() required UpdateAccessEntryDto body,
  });

  /// Отозвать доступ.
  ///
  /// Удаляет запись и **немедленно гасит все сессии** этого человека: запросы из уже открытых вкладок получают 401 (US-09). Комментарии, история, авторство и членство в проектах сохраняются.
  @DELETE('/api/access-entries/{id}')
  Future<RevokeAccessResultDto> accessControllerRemove({
    @Path('id') required String id,
  });
}
