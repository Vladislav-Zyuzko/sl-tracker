// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'invitation_author_dto.dart';
import 'invitation_dto_lifetime_days.dart';
import 'invitation_dto_role.dart';
import 'invitation_dto_state.dart';

part 'invitation_dto.freezed.dart';
part 'invitation_dto.g.dart';

@Freezed()
abstract class InvitationDto with _$InvitationDto {
  const factory InvitationDto({
    required String id,

    /// Роль, которую получит вступивший. Администратора выдать нельзя (D-05).
    required InvitationDtoRole role,

    /// Вычисляется из срока и отметки об отзыве, отдельно не хранится. Истёкшие и отозванные остаются в списке, но повторно активировать их нельзя (US-22).
    required InvitationDtoState state,

    /// Полная ссылка-приглашение. Заполнена только у действующего приглашения: у истёкшего и отозванного её нет и копировать нечего (US-22).
    required String? url,
    required DateTime expiresAt,

    /// Срок жизни ссылки в днях — тот, что выбрал администратор при создании. Отдаётся полем, а не выводится клиентом из разницы дат: строка списка показывает «Участник · 7 дней · до 19 фев» (design/screens/project.md), и вычитание дат у истёкшего приглашения дало бы не то, что выбирали.
    required InvitationDtoLifetimeDays lifetimeDays,
    required DateTime? revokedAt,
    required DateTime createdAt,

    /// Кто создал приглашение
    required InvitationAuthorDto createdBy,

    /// Сколько человек вступило по этой ссылке (US-22)
    required num acceptedCount,
  }) = _InvitationDto;

  factory InvitationDto.fromJson(Map<String, Object?> json) =>
      _$InvitationDtoFromJson(json);
}
