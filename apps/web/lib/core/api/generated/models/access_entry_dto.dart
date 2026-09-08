// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_entry_dto_source.dart';
import 'access_entry_user_dto.dart';

part 'access_entry_dto.freezed.dart';
part 'access_entry_dto.g.dart';

@Freezed()
abstract class AccessEntryDto with _$AccessEntryDto {
  const factory AccessEntryDto({
    required String id,

    /// Всегда в нижнем регистре
    required String email,

    /// Откуда запись: `config` — из конфигурации инстанса, `manual` — добавлена владельцем вручную, `invitation` — появилась при приёме приглашения (ADR-0006).
    required AccessEntryDtoSource source,

    /// Владелец трекера — единственная глобальная роль. Даёт право вести список доступа и не даёт никаких прав внутри проектов.
    required bool isInstanceOwner,
    required DateTime createdAt,

    /// Когда этот адрес впервые вошёл. `null` — «ещё не входил» (US-07).
    required DateTime? firstLoginAt,

    /// Пользователь, которым оказался адрес. `null` — человек ещё не входил.
    required AccessEntryUserDto? user,

    /// Кто добавил запись вручную. Для `config` и `invitation` — `null`.
    required AccessEntryUserDto? addedBy,

    /// Запись текущего пользователя: удалить её нельзя (US-09, ответ 409).
    required bool isSelf,
  }) = _AccessEntryDto;

  factory AccessEntryDto.fromJson(Map<String, Object?> json) =>
      _$AccessEntryDtoFromJson(json);
}
