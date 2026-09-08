import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/invites/data/invitations_repository.dart';

/// Приглашение по токену из адреса `/invite/<token>`.
///
/// Ошибки наружу отдаются как есть: экран различает 404 («Приглашение
/// не найдено»), 410 («Больше не действует») и сбой связи («Не удалось
/// проверить») — и это три разных состояния, а не одно «что-то пошло не так».
///
/// Автоповтор выключен: по протухшей ссылке долбить сервер незачем.
final invitePreviewProvider =
    AsyncNotifierProvider.family<
      InvitePreviewController,
      InvitationPreviewDto,
      String
    >(InvitePreviewController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер экрана приёма приглашения.
class InvitePreviewController extends AsyncNotifier<InvitationPreviewDto> {
  /// @nodoc
  InvitePreviewController(this.token);

  /// Токен из адреса.
  final String token;

  @override
  Future<InvitationPreviewDto> build() =>
      ref.watch(invitationsRepositoryProvider).preview(token);

  /// Проверить ссылку ещё раз — кнопка «Повторить» после сбоя связи.
  void refresh() => ref.invalidateSelf();

  /// Вступить в проект.
  ///
  /// Состояние провайдера не трогаем: при успехе человек уходит на экран
  /// проекта, при ошибке остаётся на этом же экране с баннером над кнопкой,
  /// и подменять под ним данные приглашения незачем.
  Future<AcceptInvitationResultDto> accept() =>
      ref.read(invitationsRepositoryProvider).accept(token);
}
