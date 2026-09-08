// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/mention_suggestion_list_dto.dart';

part 'mentions_client.g.dart';

@RestApi()
abstract class MentionsClient {
  factory MentionsClient(Dio dio, {String? baseUrl}) = _MentionsClient;

  /// Подсказка упоминаний.
  ///
  /// Участники проекта, которому принадлежит задача, отфильтрованные по имени и email без учёта регистра (US-74). Порядок — по имени; не более 10 строк по умолчанию.
  ///
  /// В подсказку попадают участники **в любой роли**, включая читателя и администратора; посторонние пользователи трекера — никогда, и перебором состав трекера отсюда не узнать: выборка идёт по участникам проекта, а не по пользователям (D-41, ADR-0006, п. 6). Себя подсказка показывает — упомянуть себя можно, уведомление себе при этом не приходит.
  ///
  /// Идентификатор из ответа подставляется в токен `@[Имя](user:<uuid>)` в тексте комментария или описания. Читатель текстов не создаёт и получает 403 (D-29). Маршрут ограничен по частоте: это поиск.
  ///
  /// [key] - Ключ задачи, регистронезависим.
  ///
  /// [query] - Строка после `@`. Фильтрует по имени и по email без учёта регистра. Пустая строка — начало списка участников проекта.
  @GET('/api/issues/{key}/mention-suggestions')
  Future<MentionSuggestionListDto> mentionSuggestionsControllerSuggest({
    @Path('key') required String key,
    @Query('limit') num? limit = 10,
    @Query('query') String? query,
  });
}
