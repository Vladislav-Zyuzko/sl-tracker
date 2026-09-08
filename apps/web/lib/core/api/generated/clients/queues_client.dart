// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_queue_dto.dart';
import '../models/created_queue_dto.dart';
import '../models/queue_dto.dart';
import '../models/queue_list_dto.dart';
import '../models/queue_status_list_dto.dart';
import '../models/update_queue_dto.dart';

part 'queues_client.g.dart';

@RestApi()
abstract class QueuesClient {
  factory QueuesClient(Dio dio, {String? baseUrl}) = _QueuesClient;

  /// Очереди проекта.
  ///
  /// Виден всем участникам проекта, включая читателя (US-31). Сортировка — по названию по возрастанию. `openIssueCount` — число незавершённых задач, то есть тех, чей статус **не** в категории `done`. Очередей у проекта единицы, поэтому список отдаётся целиком, без курсора.
  @GET('/api/projects/{slug}/queues')
  Future<QueueListDto> projectQueuesControllerList({
    @Path('slug') required String slug,
  });

  /// Создать очередь.
  ///
  /// Только администратор проекта (US-30). Ключ уникален **на весь трекер**, а не внутри проекта, и после создания не меняется никогда (D-06, ADR-0004). Ключ удалённой очереди повторно не выдаётся (D-25), поэтому 409 возможен и на ключ, которого сейчас ни у кого нет. В каком проекте ключ занят — ответ не сообщает.
  ///
  /// Вместе с очередью создаются пять статусов по умолчанию (US-60): Открыт, В работе, Ревью, Тестирование, Закрыт. Они возвращаются в поле `statuses`, второй запрос за ними не нужен. Первый из них — статус новой задачи по умолчанию.
  @POST('/api/projects/{slug}/queues')
  Future<CreatedQueueDto> projectQueuesControllerCreate({
    @Path('slug') required String slug,
    @Body() required CreateQueueDto body,
  });

  /// Очередь по ключу.
  ///
  /// Видна всем участникам проекта, включая читателя. Ключ регистронезависим. В ответе есть короткое имя и название проекта — для хлебных крошек, без второго запроса.
  @GET('/api/queues/{key}')
  Future<QueueDto> queueControllerGet({@Path('key') required String key});

  /// Переименовать очередь.
  ///
  /// Только администратор проекта (US-33). Меняются название и описание; **ключ не меняется никогда** (D-06) и в теле запроса не принимается. Ключи существующих задач переименование не затрагивает.
  @PATCH('/api/queues/{key}')
  Future<QueueDto> queueControllerUpdate({
    @Path('key') required String key,
    @Body() required UpdateQueueDto body,
  });

  /// Удалить очередь.
  ///
  /// Только администратор проекта и **только пустую**: при наличии хотя бы одной задачи в любом статусе — 409 (US-34, D-24). Каскадного удаления задач нет.
  ///
  /// Ключ удалённой очереди остаётся занятым навсегда и другой очереди не достанется (D-25): иначе старая ссылка `DEV-42` открыла бы совсем другую задачу.
  @DELETE('/api/queues/{key}')
  Future<void> queueControllerRemove({@Path('key') required String key});

  /// Статусы очереди.
  ///
  /// Пять статусов очереди в фиксированном порядке (US-60). Статусы — данные, а не enum: у каждой очереди свой набор, и клиент обязан брать его отсюда, а не хардкодить (ADR-0003). Нужен для выпадающего списка на задаче и для фильтра в списке задач. Редактора статусов в MVP нет: список только читается.
  @GET('/api/queues/{key}/statuses')
  Future<QueueStatusListDto> queueControllerStatuses({
    @Path('key') required String key,
  });
}
