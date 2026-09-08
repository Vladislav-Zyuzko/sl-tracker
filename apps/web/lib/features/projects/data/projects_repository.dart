import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';

/// Проекты и их участники.
class ProjectsRepository {
  /// @nodoc
  const ProjectsRepository(this._client, this._dio);

  final ProjectsClient _client;

  /// Нужен для одного запроса — загрузки обложки, см. [uploadCover].
  final Dio _dio;

  /// Размер страницы списка проектов.
  ///
  /// Проектов у команды единицы, но пагинация в контракте есть, и делать вид,
  /// что её нет, — верный способ однажды потерять половину списка.
  static const pageSize = 50;

  /// Мои проекты.
  Future<ProjectListDto> list({String? cursor}) async {
    try {
      return await _client.projectsControllerList(
        limit: pageSize,
        cursor: cursor,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Проект по короткому имени.
  ///
  /// Работает и для прежних коротких имён: в ответе всегда действующее `slug`,
  /// и экран заменяет им адрес в строке браузера (US-18).
  Future<ProjectDto> bySlug(String slug) async {
    try {
      return await _client.projectsControllerGet(slug: slug);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Создаёт проект. Короткое имя выдаёт сервер — оно в поле `slug` ответа.
  Future<ProjectDto> create({required String name, String? description}) async {
    try {
      return await _client.projectsControllerCreate(
        body: CreateProjectDto(
          name: name,
          description: description == null || description.isEmpty
              ? null
              : description,
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Меняет название и описание. Короткое имя при этом не меняется (US-18).
  Future<ProjectDto> update(
    String slug, {
    required String name,
    required String description,
  }) async {
    try {
      return await _client.projectsControllerUpdate(
        slug: slug,
        body: UpdateProjectDto(name: name, description: description),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Меняет короткое имя в адресе. Прежнее остаётся занятым навсегда.
  Future<ProjectDto> changeSlug(String slug, String newSlug) async {
    try {
      return await _client.projectsControllerChangeSlug(
        slug: slug,
        body: UpdateProjectSlugDto(slug: newSlug),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет проект со всем содержимым (US-17).
  Future<void> remove(String slug) async {
    try {
      await _client.projectsControllerRemove(slug: slug);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Загружает обложку.
  ///
  /// Единственное место, где запрос собирается руками, а не сгенерированным
  /// клиентом. Причина техническая: `swagger_parser` описывает `multipart`
  /// как `dart:io File`, а в браузере файловой системы нет — файл приходит
  /// массивом байтов из `<input type="file">`. Тело и ответ при этом строго
  /// по контракту: путь из него же, ответ разбирается в [ProjectDto].
  Future<ProjectDto> uploadCover(String slug, PickedFile file) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.name,
          // Тип, о котором сказал браузер, — подсказка: сервер всё равно
          // определяет его по содержимому файла.
          contentType: file.mimeType.isEmpty
              ? null
              : DioMediaType.parse(file.mimeType),
        ),
      });

      final response = await _dio.put<Map<String, dynamic>>(
        '/api/projects/$slug/cover',
        data: form,
      );

      return ProjectDto.fromJson(response.data!);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет обложку: в списке и в шапке снова заглушка (US-12).
  Future<ProjectDto> removeCover(String slug) async {
    try {
      return await _client.projectsControllerRemoveCover(slug: slug);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Участники проекта. Виден всем участникам, включая читателя (US-14).
  Future<ProjectMemberListDto> members(String slug, {String? cursor}) async {
    try {
      return await _client.membersControllerList(
        slug: slug,
        limit: pageSize,
        cursor: cursor,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Меняет роль участника (US-15).
  Future<ProjectMemberDto> changeMemberRole(
    String slug,
    String userId,
    SLRole role,
  ) async {
    try {
      return await _client.membersControllerChangeRole(
        slug: slug,
        userId: userId,
        body: UpdateMemberRoleDto(role: role.updateDto),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Исключает участника или выводит из проекта самого себя (US-16).
  ///
  /// Возвращает число задач, у которых очистился исполнитель: человек должен
  /// узнать последствие числом, а не догадываться о нём (D-31).
  Future<int> removeMember(String slug, String userId) async {
    try {
      final result = await _client.membersControllerRemove(
        slug: slug,
        userId: userId,
      );

      return result.unassignedIssues.toInt();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(
    ref.watch(apiClientProvider).projects,
    ref.watch(dioProvider),
  ),
);
