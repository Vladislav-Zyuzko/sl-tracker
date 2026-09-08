// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accept_invitation_result_dto.dart';
import '../models/create_invitation_dto.dart';
import '../models/invitation_dto.dart';
import '../models/invitation_list_dto.dart';
import '../models/invitation_preview_dto.dart';

part 'invitations_client.g.dart';

@RestApi()
abstract class InvitationsClient {
  factory InvitationsClient(Dio dio, {String? baseUrl}) = _InvitationsClient;

  /// Создать ссылку-приглашение.
  ///
  /// Только администратор проекта (US-20). Роль администратора через приглашение выдать нельзя (D-05), срок жизни — 1, 7 или 30 дней (по умолчанию 7); бессрочных приглашений нет. По одной ссылке может вступить любое число людей, пока она действует. Полный адрес ссылки — в поле `url`.
  @POST('/api/projects/{slug}/invitations')
  Future<InvitationDto> projectInvitationsControllerCreate({
    @Path('slug') required String slug,
    @Body() required CreateInvitationDto body,
  });

  /// Приглашения проекта.
  ///
  /// Все приглашения проекта, сначала новые: действующие, истёкшие и отозванные с числом вступивших по каждому (US-22).
  ///
  /// [cursor] - Курсор следующей страницы из поля `nextCursor`.
  @GET('/api/projects/{slug}/invitations')
  Future<InvitationListDto> projectInvitationsControllerList({
    @Path('slug') required String slug,
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 50,
  });

  /// Отозвать приглашение.
  ///
  /// Отозвать может любой администратор проекта, в том числе не тот, кто создавал ссылку. Сразу после отзыва переход по ссылке даёт 410. Уже вступившие остаются участниками (US-22).
  @POST('/api/projects/{slug}/invitations/{id}/revoke')
  Future<InvitationDto> projectInvitationsControllerRevoke({
    @Path('slug') required String slug,
    @Path('id') required String id,
  });

  /// Приглашение по токену.
  ///
  /// Данные для экрана подтверждения: название проекта, обложка и роль, которую получит человек. Ни задач, ни очередей, ни участников (US-21). Неизвестный токен — 404, истёкший или отозванный — 410; по сообщению нельзя понять, существует ли такой проект. `alreadyMember: true` означает, что экран показывать не нужно — клиент сразу открывает проект.
  ///
  /// [token] - Токен из ссылки `/invite/<token>`.
  @GET('/api/invitations/{token}')
  Future<InvitationPreviewDto> invitationAcceptControllerPreview({
    @Path('token') required String token,
  });

  /// Вступить в проект по приглашению.
  ///
  /// Человек становится участником с ролью из приглашения, а его email попадает в список доступа с источником `invitation` — со следующего входа ссылка ему уже не нужна (ADR-0006, п. 3). Тот, кто уже состоит в проекте, просто получает адрес проекта: роль не меняется и не понижается (US-21).
  @POST('/api/invitations/{token}/accept')
  Future<AcceptInvitationResultDto> invitationAcceptControllerAccept({
    @Path('token') required String token,
  });
}
