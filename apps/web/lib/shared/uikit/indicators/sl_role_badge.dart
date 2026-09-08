import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Роль участника проекта (`docs/design/system.md`, 7).
///
/// Отдельное перечисление, а не один из сгенерированных enum'ов: ролей
/// в контракте четыре штуки (`ProjectDtoRole`, `ProjectMemberDtoRole`,
/// `InvitationDtoRole`, `AcceptInvitationResultDtoRole`), они описывают одно
/// и то же, и подписи не должны расползаться по коду в четырёх экземплярах.
enum SLRole {
  /// Полные права в проекте.
  admin('Администратор', 'Админ', Icons.shield_outlined),

  /// Роль по умолчанию: работает с задачами.
  member('Участник', 'Участник', null),

  /// Только просмотр.
  reader('Читатель', 'Читатель', Icons.visibility_off_outlined);

  /// @nodoc
  const SLRole(this.label, this.shortLabel, this.icon);

  /// Полное название. Оно же уходит в скринридер.
  final String label;

  /// Короткое название для узкой колонки.
  final String shortLabel;

  /// Иконка бейджа. У роли по умолчанию иконки нет — у неё нет и бейджа.
  final IconData? icon;

  /// Что даёт роль (`docs/product/permissions.md`, 3).
  ///
  /// Показывается там, где человек выбирает роль или принимает решение
  /// вступить: «Участник» само по себе ничего не объясняет.
  String get description => switch (this) {
    SLRole.admin => 'Управляет проектом, очередями и участниками',
    SLRole.member => 'Сможете создавать и менять задачи, комментировать',
    SLRole.reader =>
      'Сможете просматривать задачи и обсуждения, но не менять их',
  };
}

/// Бейдж роли (`docs/design/system.md`, 7).
///
/// Роль передаётся текстом, а не цветом или положением: это требование
/// доступности, а не оформление.
///
/// Роль «Участник» — по умолчанию, и в списке участников бейджа не получает
/// (`system.md`, 7). Исключение — карточка проекта, где роль показывается
/// всегда: там она отвечает на вопрос «куда я могу вносить изменения»
/// (`screens/projects.md`). Решает вызывающий, а не компонент.
class SLRoleBadge extends StatelessWidget {
  /// @nodoc
  const SLRoleBadge({required this.role, this.short = false, super.key});

  /// Роль.
  final SLRole role;

  /// Короткая подпись: «Админ» вместо «Администратор».
  final bool short;

  /// Высота бейджа.
  static const height = 18.0;

  /// Горизонтальный padding. Одно из двух зафиксированных исключений
  /// из шкалы отступов (`system.md`, 10.1).
  static const horizontalPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final icon = role.icon;

    return Semantics(
      label: 'Роль: ${role.label}',
      excludeSemantics: true,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          borderRadius: SLRadii.smAll,
          border: Border.all(
            color: colors.borderStrong,
            width: SLBorders.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: SLIconSizes.icon12, color: colors.textSecondary),
              const SizedBox(width: SLSpacing.space1),
            ],
            // Гибкий, чтобы бейдж не ломал узкую колонку при крупном
            // системном шрифте: роль всё равно целиком читается
            // скринридером из доступного имени выше.
            Flexible(
              child: Text(
                short ? role.shortLabel : role.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: text.overline.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
