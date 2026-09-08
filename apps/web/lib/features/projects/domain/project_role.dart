import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';

/// Перевод ролей из контракта в роль интерфейса.
///
/// В контракте одна и та же роль описана четырьмя разными перечислениями —
/// по одному на каждую схему. Приводим их к [SLRole] в одном месте, чтобы
/// подписи и логика «что показывать администратору» не расползались.
///
/// Неизвестное значение с сервера трактуется как [SLRole.reader]: если
/// когда-нибудь появится новая роль, интерфейс скорее не покажет кнопку,
/// чем покажет лишнюю. Молча решать в пользу прав — плохой обмен.
extension ProjectDtoRoleX on ProjectDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    ProjectDtoRole.admin => SLRole.admin,
    ProjectDtoRole.member => SLRole.member,
    ProjectDtoRole.reader || ProjectDtoRole.$unknown => SLRole.reader,
  };
}

/// @nodoc
extension ProjectMemberDtoRoleX on ProjectMemberDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    ProjectMemberDtoRole.admin => SLRole.admin,
    ProjectMemberDtoRole.member => SLRole.member,
    ProjectMemberDtoRole.reader ||
    ProjectMemberDtoRole.$unknown => SLRole.reader,
  };
}

/// @nodoc
extension ProjectMemberPreviewDtoRoleX on ProjectMemberPreviewDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    ProjectMemberPreviewDtoRole.admin => SLRole.admin,
    ProjectMemberPreviewDtoRole.member => SLRole.member,
    ProjectMemberPreviewDtoRole.reader ||
    ProjectMemberPreviewDtoRole.$unknown => SLRole.reader,
  };
}

/// @nodoc
extension InvitationDtoRoleX on InvitationDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    InvitationDtoRole.member => SLRole.member,
    InvitationDtoRole.reader || InvitationDtoRole.$unknown => SLRole.reader,
  };
}

/// @nodoc
extension InvitationPreviewDtoRoleX on InvitationPreviewDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    InvitationPreviewDtoRole.admin => SLRole.admin,
    InvitationPreviewDtoRole.member => SLRole.member,
    InvitationPreviewDtoRole.reader ||
    InvitationPreviewDtoRole.$unknown => SLRole.reader,
  };
}

/// Обратный перевод: роль интерфейса в тело запроса смены роли.
extension SLRoleX on SLRole {
  /// @nodoc
  UpdateMemberRoleDtoRole get updateDto => switch (this) {
    SLRole.admin => UpdateMemberRoleDtoRole.admin,
    SLRole.member => UpdateMemberRoleDtoRole.member,
    SLRole.reader => UpdateMemberRoleDtoRole.reader,
  };

  /// Роль для приглашения. Администратора через приглашение выдать нельзя
  /// (D-05), поэтому [SLRole.admin] сюда не приводится и в выборе роли
  /// не появляется.
  CreateInvitationDtoRole? get invitationDto => switch (this) {
    SLRole.admin => null,
    SLRole.member => CreateInvitationDtoRole.member,
    SLRole.reader => CreateInvitationDtoRole.reader,
  };
}

/// Роль в проекте, которому принадлежит очередь. Прав уровня очереди в MVP
/// нет: они наследуются от проекта (`permissions.md`, п. 3).
extension QueueDtoRoleX on QueueDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    QueueDtoRole.admin => SLRole.admin,
    QueueDtoRole.member => SLRole.member,
    QueueDtoRole.reader || QueueDtoRole.$unknown => SLRole.reader,
  };
}

/// @nodoc
extension CreatedQueueDtoRoleX on CreatedQueueDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    CreatedQueueDtoRole.admin => SLRole.admin,
    CreatedQueueDtoRole.member => SLRole.member,
    CreatedQueueDtoRole.reader || CreatedQueueDtoRole.$unknown => SLRole.reader,
  };
}

/// Роль запросившего в ответе списка задач: по ней прячется «Создать задачу».
///
/// Поле необязательное. Его отсутствие трактуется как [SLRole.reader] —
/// без явного разрешения кнопку не показываем.
extension IssueListDtoRoleX on IssueListDtoRole {
  /// @nodoc
  SLRole get role => switch (this) {
    IssueListDtoRole.admin => SLRole.admin,
    IssueListDtoRole.member => SLRole.member,
    IssueListDtoRole.reader || IssueListDtoRole.$unknown => SLRole.reader,
  };
}
