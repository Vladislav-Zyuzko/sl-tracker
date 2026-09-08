// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_project_dto.dart';
import '../models/project_dto.dart';
import '../models/project_list_dto.dart';
import '../models/project_member_dto.dart';
import '../models/project_member_list_dto.dart';
import '../models/remove_member_result_dto.dart';
import '../models/update_member_role_dto.dart';
import '../models/update_project_dto.dart';
import '../models/update_project_slug_dto.dart';

part 'projects_client.g.dart';

@RestApi()
abstract class ProjectsClient {
  factory ProjectsClient(Dio dio, {String? baseUrl}) = _ProjectsClient;

  /// Мои проекты.
  ///
  /// Проекты, где пользователь состоит в любой роли, по названию по возрастанию. Чужие проекты в список не попадают, даже если известен их адрес (US-10).
  ///
  /// [limit] - Размер страницы. Больше максимума не отдаём.
  ///
  /// [cursor] - Курсор следующей страницы из поля `nextCursor`.
  @GET('/api/projects')
  Future<ProjectListDto> projectsControllerList({
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 50,
  });

  /// Создать проект.
  ///
  /// Создать проект может любой пользователь, прошедший список доступа; отдельного права нет. Создатель становится администратором и единственным участником (US-11).
  ///
  /// **Короткое имя в адресе выдаёт сервер** по названию: кириллица транслитерируется (`и` → `i`, `й` → `y`, `ж` → `zh`, `ч` → `ch`, `ш` → `sh`, `щ` → `sch`, `ю` → `yu`, `я` → `ya`, `ь` и `ъ` пропадают), регистр приводится к нижнему, всё недопустимое заменяется дефисом, повторные дефисы схлопываются, крайние обрезаются, длина ограничена 40 символами. «Сладкий Лимит 2026!» → `sladkiy-limit-2026`. Если допустимых символов не осталось, имя будет вида `project-7`. При коллизии добавляется числовой суффикс (`sladkiy-limit-2`), поэтому предпросмотр на клиенте может разойтись с итогом: окончательное значение всегда в поле `slug` ответа.
  @POST('/api/projects')
  Future<ProjectDto> projectsControllerCreate({
    @Body() required CreateProjectDto body,
  });

  /// Проект по короткому имени.
  ///
  /// Работает и для прежних коротких имён проекта: в ответе всегда действующее `slug`, и клиент заменяет им адрес в строке браузера (US-18). Не-участник получает 404 без каких-либо данных проекта.
  @GET('/api/projects/{slug}')
  Future<ProjectDto> projectsControllerGet({
    @Path('slug') required String slug,
  });

  /// Изменить название и описание.
  ///
  /// Только администратор проекта. Переименование **не меняет** короткое имя в адресе: ранее отправленные ссылки продолжают работать (US-18).
  @PATCH('/api/projects/{slug}')
  Future<ProjectDto> projectsControllerUpdate({
    @Path('slug') required String slug,
    @Body() required UpdateProjectDto body,
  });

  /// Удалить проект.
  ///
  /// Только администратор (US-17). Удаляются очереди, задачи, комментарии и вложения. Ключи очередей и прежние короткие имена остаются занятыми и повторно не выдаются (D-25, US-18).
  @DELETE('/api/projects/{slug}')
  Future<void> projectsControllerRemove({@Path('slug') required String slug});

  /// Изменить короткое имя в адресе.
  ///
  /// Только администратор и только явным действием (US-18). Прежнее короткое имя остаётся занятым навсегда и продолжает открывать этот же проект; другому проекту оно достаться не может. Системные адреса приложения (`issues`, `invite`, `projects`, `profile`, `me`, `api`, `login`, `access-denied`, `notifications`, `queues`) отклоняются.
  @PUT('/api/projects/{slug}/slug')
  Future<ProjectDto> projectsControllerChangeSlug({
    @Path('slug') required String slug,
    @Body() required UpdateProjectSlugDto body,
  });

  /// Загрузить обложку проекта.
  ///
  /// Только администратор. Один файл в поле `file`: PNG, JPEG или WEBP до 5 МБ (US-12). Тип определяется по содержимому файла, а не по заголовку и не по расширению; имя объекта в хранилище генерирует сервер. Загрузка второй обложки заменяет предыдущую. Обложка отдаётся подписанной ссылкой в поле `coverUrl` и по прямой ссылке без подписи недоступна.
  @MultiPart()
  @PUT('/api/projects/{slug}/cover')
  Future<ProjectDto> projectsControllerUploadCover({
    @Path('slug') required String slug,
    @Part(name: 'file') required File file,
  });

  /// Удалить обложку проекта.
  ///
  /// Только администратор. В списке и в шапке снова показывается заглушка (US-12).
  @DELETE('/api/projects/{slug}/cover')
  Future<ProjectDto> projectsControllerRemoveCover({
    @Path('slug') required String slug,
  });

  /// Участники проекта.
  ///
  /// Виден всем участникам проекта, включая читателя (US-14). Порядок: сначала администраторы, дальше по имени.
  ///
  /// [cursor] - Курсор следующей страницы из поля `nextCursor`.
  @GET('/api/projects/{slug}/members')
  Future<ProjectMemberListDto> membersControllerList({
    @Path('slug') required String slug,
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 50,
  });

  /// Изменить роль участника.
  ///
  /// Только администратор (US-15). Администратор может понизить себя, если он не последний. Понижение последнего администратора — 409.
  @PATCH('/api/projects/{slug}/members/{userId}')
  Future<ProjectMemberDto> membersControllerChangeRole({
    @Path('slug') required String slug,
    @Path('userId') required String userId,
    @Body() required UpdateMemberRoleDto body,
  });

  /// Исключить участника или выйти из проекта.
  ///
  /// Исключить другого может только администратор; выйти самостоятельно может любой участник — для этого в `userId` передаётся собственный идентификатор (US-16). Последний администратор не уходит ни тем, ни другим путём — 409.
  ///
  /// Задачи исключённого остаются, поле «Исполнитель» в них очищается, и на каждую такую задачу пишется запись истории в той же транзакции (D-31).
  @DELETE('/api/projects/{slug}/members/{userId}')
  Future<RemoveMemberResultDto> membersControllerRemove({
    @Path('slug') required String slug,
    @Path('userId') required String userId,
  });
}
