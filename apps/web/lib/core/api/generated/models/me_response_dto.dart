// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'me_session_dto.dart';

part 'me_response_dto.freezed.dart';
part 'me_response_dto.g.dart';

@Freezed()
abstract class MeResponseDto with _$MeResponseDto {
  const factory MeResponseDto({
    required String id,

    /// Имя из Яндекс ID, обновляется при входе
    required String displayName,
    required String email,

    /// Аватар из Яндекс ID
    required String? avatarUrl,

    /// Владелец трекера — единственная глобальная роль (permissions.md, п. 1.2). Прав внутри проектов не даёт.
    required bool isInstanceOwner,

    /// Показывать ли пункт «Доступ к трекеру». Флаг приходит с сервера готовым: клиент не вычисляет право сам (design/screens/access-list.md, Q-D30).
    required bool canManageAccessList,
    required MeSessionDto session,
  }) = _MeResponseDto;

  factory MeResponseDto.fromJson(Map<String, Object?> json) =>
      _$MeResponseDtoFromJson(json);
}
