import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';

/// Ссылки-приглашения в проект (US-20 … US-23).
///
/// Один репозиторий на две стороны одного механизма: администратор создаёт
/// и отзывает ссылки на вкладке «Приглашения», приглашённый открывает
/// `/invite/<token>`. Контракт у них общий, и разводить его по двум фичам
/// значило бы дважды описывать одни и те же коды ошибок.
class InvitationsRepository {
  /// @nodoc
  const InvitationsRepository(this._client);

  final InvitationsClient _client;

  /// Размер страницы списка приглашений.
  static const pageSize = 50;

  /// Приглашения проекта: действующие, истёкшие и отозванные (US-22).
  Future<InvitationListDto> list(String slug, {String? cursor}) async {
    try {
      return await _client.projectInvitationsControllerList(
        slug: slug,
        limit: pageSize,
        cursor: cursor,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Создаёт ссылку. Полный адрес — в поле `url` ответа.
  Future<InvitationDto> create(
    String slug, {
    required SLRole role,
    required CreateInvitationDtoExpiresInDays expiresInDays,
  }) async {
    final dtoRole = role.invitationDto;
    if (dtoRole == null) {
      // Администратора через приглашение выдать нельзя (D-05). До сервера
      // такой запрос доходить не должен вовсе — это ошибка вызывающего кода.
      throw ArgumentError.value(role, 'role', 'Роль недоступна в приглашении');
    }

    try {
      return await _client.projectInvitationsControllerCreate(
        slug: slug,
        body: CreateInvitationDto(role: dtoRole, expiresInDays: expiresInDays),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Отзывает ссылку. Уже вступившие остаются участниками (US-22).
  Future<InvitationDto> revoke(String slug, String id) async {
    try {
      return await _client.projectInvitationsControllerRevoke(
        slug: slug,
        id: id,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Приглашение по токену: название проекта, обложка и роль.
  ///
  /// Ни задач, ни очередей, ни участников (US-21). Неизвестный токен — 404,
  /// истёкший или отозванный — 410.
  Future<InvitationPreviewDto> preview(String token) async {
    try {
      return await _client.invitationAcceptControllerPreview(token: token);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Вступление в проект.
  Future<AcceptInvitationResultDto> accept(String token) async {
    try {
      return await _client.invitationAcceptControllerAccept(token: token);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final invitationsRepositoryProvider = Provider<InvitationsRepository>(
  (ref) => InvitationsRepository(ref.watch(apiClientProvider).invitations),
);
