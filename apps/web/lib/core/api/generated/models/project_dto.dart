// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_dto_role.dart';
import 'project_member_preview_dto.dart';

part 'project_dto.freezed.dart';
part 'project_dto.g.dart';

@Freezed()
abstract class ProjectDto with _$ProjectDto {
  const factory ProjectDto({
    required String id,

    /// Действующее короткое имя в адресе. Если проект запрошен по прежнему короткому имени, здесь всё равно действующее — клиенту следует заменить адрес в строке браузера на него (US-18).
    required String slug,
    required String name,

    /// Markdown, до 5000 символов
    required String? description,

    /// Подписанная ссылка на обложку со сроком жизни 10 минут. Бакет не публичный: ссылка без подписи содержимое не отдаёт. `null` — обложки нет, клиент рисует заглушку.
    required String? coverUrl,

    /// Роль текущего пользователя в этом проекте (permissions.md, 2.1).
    required ProjectDtoRole role,

    /// Сколько всего участников в проекте
    required num memberCount,

    /// Первые участники для группы аватаров: администраторы, затем по имени.
    required List<ProjectMemberPreviewDto> members,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProjectDto;

  factory ProjectDto.fromJson(Map<String, Object?> json) =>
      _$ProjectDtoFromJson(json);
}
