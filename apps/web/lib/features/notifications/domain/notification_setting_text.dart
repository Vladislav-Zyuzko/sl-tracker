import 'package:sl_tracker_web/core/api/generated/export.dart';

/// Тексты настроек подписки (`docs/design/screens/profile.md`).
///
/// Формулировка **от первого лица и от события**, а не от системы: «Меня
/// упомянули в тексте», а не «Уведомления об упоминаниях». Общая шапка
/// «Присылать уведомления, когда:» превращает список в связное предложение.
sealed class NotificationSettingText {
  /// Порядок пунктов на экране.
  ///
  /// Не алфавит и не порядок из ответа сервера: «упоминание» стоит **перед**
  /// «комментарием» намеренно — так видна связка «оставить только те
  /// комментарии, где меня позвали лично» (US-104).
  static const order = <NotificationSettingDtoType>[
    NotificationSettingDtoType.issueAssigned,
    NotificationSettingDtoType.issueAuthorAssigned,
    NotificationSettingDtoType.issueMentioned,
    NotificationSettingDtoType.issueStatusChanged,
    NotificationSettingDtoType.issueCommented,
    NotificationSettingDtoType.projectMemberJoined,
  ];

  /// Название типа.
  static String labelOf(NotificationSettingDtoType type) => switch (type) {
    NotificationSettingDtoType.issueAssigned =>
      'Меня назначили исполнителем задачи',
    NotificationSettingDtoType.issueAuthorAssigned =>
      'Меня указали автором задачи',
    NotificationSettingDtoType.issueMentioned => 'Меня упомянули в тексте',
    NotificationSettingDtoType.issueStatusChanged =>
      'Изменился статус задачи, на которую я подписан',
    NotificationSettingDtoType.issueCommented =>
      'Появился комментарий к задаче, на которую я подписан',
    NotificationSettingDtoType.projectMemberJoined =>
      'В проект вступил новый участник',
    // Сервер вправе добавить тип: показываем его как есть, а не прячем.
    // Скрытая настройка хуже незнакомой — о ней невозможно догадаться.
    NotificationSettingDtoType.$unknown => 'Другие события',
  };

  /// Уточнение под названием. `null` — уточнения нет.
  ///
  /// Спека просит различать «только для проектов, где вы администратор»
  /// и «сейчас вы не администратор ни в одном проекте», но признака
  /// «администратор хоть где-нибудь» в контракте нет: `GET /api/me` его
  /// не отдаёт. Вычислять его выкачиванием списка проектов ради подписи —
  /// лишний запрос на экране, который открывают дважды в год, и вдобавок
  /// неверный ответ у того, у кого проектов больше страницы. Поэтому
  /// показывается общая формулировка; запрос флага записан в отчёте.
  static String? hintOf(NotificationSettingDtoType type) =>
      type == NotificationSettingDtoType.projectMemberJoined
      ? 'Только для проектов, где вы администратор'
      : null;
}
