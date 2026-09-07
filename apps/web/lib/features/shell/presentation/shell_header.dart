import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_counter_badge.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Шапка приложения (`docs/design/screens/app-shell.md`).
///
/// Отрисовывается сразу и по-настоящему, даже пока данные грузятся: сбой
/// или задержка одного блока не должны обрушивать оболочку.
class ShellHeader extends StatelessWidget {
  /// @nodoc
  const ShellHeader({
    required this.onLogoTap,
    required this.onCreateIssue,
    required this.onNotifications,
    required this.onOpenProfile,
    required this.onOpenAccessList,
    this.unreadCount,
    this.userName,
    this.userId,
    this.canManageAccessList = false,
    this.onSignOut,
    this.onMenuTap,
    super.key,
  });

  /// Клик по логотипу — к списку проектов.
  final VoidCallback onLogoTap;

  /// Создать задачу.
  final VoidCallback? onCreateIssue;

  /// Центр уведомлений.
  final VoidCallback onNotifications;

  /// Число непрочитанных уведомлений. `null` — ещё не загружено, пилюля
  /// не рисуется.
  final int? unreadCount;

  /// Имя пользователя. `null` — данные ещё не пришли, вместо имени скелетон.
  final String? userName;

  /// Идентификатор пользователя — по нему выбирается цвет аватара.
  final String? userId;

  /// Есть ли право вести список доступа.
  ///
  /// Приходит флагом `canManageAccessList` из `GET /api/me`. Пункт меню
  /// «Доступ к трекеру» показывается только по нему.
  final bool canManageAccessList;

  /// Открыть профиль.
  final VoidCallback onOpenProfile;

  /// Открыть список доступа.
  final VoidCallback onOpenAccessList;

  /// Выйти. `null` — выход ещё не подключён.
  final VoidCallback? onSignOut;

  /// Кнопка-бургер на телефоне. `null` — сайдбар виден и без неё.
  final VoidCallback? onMenuTap;

  /// Максимальная ширина имени пользователя в шапке.
  static const userNameMaxWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final density = SLDensity.of(breakpoint);
    final isPhone = breakpoint.isPhone;

    return Semantics(
      container: true,
      header: true,
      child: Container(
        height: density.appBarHeight,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
        child: Row(
          children: [
            if (onMenuTap != null) ...[
              SLIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Открыть панель навигации',
                onPressed: onMenuTap,
              ),
              const SizedBox(width: SLSpacing.space2),
            ],
            _Logo(onTap: onLogoTap),
            const SizedBox(width: SLSpacing.space6),
            if (isPhone)
              SLIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Создать задачу',
                variant: SLButtonVariant.primary,
                onPressed: onCreateIssue,
              )
            else
              SLButton(
                label: 'Создать задачу',
                icon: Icons.add_rounded,
                onPressed: onCreateIssue,
              ),
            const Spacer(),
            _NotificationsButton(
              unreadCount: unreadCount,
              onPressed: onNotifications,
            ),
            const SizedBox(width: SLSpacing.space3),
            _ProfileMenu(
              userName: userName,
              userId: userId,
              showName: !isPhone && breakpoint != SLBreakpoint.md,
              canManageAccessList: canManageAccessList,
              onOpenProfile: onOpenProfile,
              onOpenAccessList: onOpenAccessList,
              onSignOut: onSignOut,
              colors: colors,
              text: text,
            ),
          ],
        ),
      ),
    );
  }
}

/// Логотип-текст. Не сжимается ни при какой ширине окна.
class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      button: true,
      label: 'SL Tracker, к списку проектов',
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              'SL Tracker',
              softWrap: false,
              style: text.bodySStrong.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Колокольчик со счётчиком непрочитанных.
///
/// Счётчик — не только цвет: он и число, и часть доступного имени.
class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int? unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final count = unreadCount ?? 0;
    final tooltip = count > 0
        ? 'Уведомления, ${SLCounterBadge.format(count, 99)} непрочитанных'
        : 'Уведомления';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SLIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: tooltip,
          size: SLButtonSize.lg,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: ExcludeSemantics(
              child: SLCounterBadge(count: count, accented: true),
            ),
          ),
      ],
    );
  }
}

/// Меню профиля: аватар, имя и шеврон.
///
/// Пункт «Доступ к трекеру» показывается только тем, у кого есть право вести
/// список доступа. Обычный участник о существовании экрана не узнаёт,
/// поэтому пункт именно отсутствует, а не выключен.
class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.userName,
    required this.userId,
    required this.showName,
    required this.canManageAccessList,
    required this.onOpenProfile,
    required this.onOpenAccessList,
    required this.onSignOut,
    required this.colors,
    required this.text,
  });

  final String? userName;
  final String? userId;
  final bool showName;
  final bool canManageAccessList;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAccessList;
  final VoidCallback? onSignOut;
  final SLColorScheme colors;
  final SLTextScheme text;

  @override
  Widget build(BuildContext context) {
    if (userName == null || userId == null) {
      return Row(
        children: [
          const SLSkeletonBox.circle(diameter: 24),
          if (showName) ...[
            const SizedBox(width: SLSpacing.space2),
            const SLSkeletonLine(width: 96),
          ],
        ],
      );
    }

    return MenuAnchor(
      menuChildren: [
        _menuItem('Профиль', onOpenProfile),
        // Пункта нет вовсе, когда права нет: скрытый контрол — это удобство,
        // но здесь ещё и то, что пользователь не должен узнать о существовании
        // экрана. Флаг приходит из `GET /api/me`.
        if (canManageAccessList)
          _menuItem('Доступ к трекеру', onOpenAccessList),
        const Divider(),
        _menuItem('Выйти', onSignOut),
      ],
      builder: (context, controller, child) => Semantics(
        button: true,
        label: 'Меню профиля, $userName',
        child: ExcludeSemantics(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SLAvatar(
                    userId: userId!,
                    fullName: userName!,
                    size: SLAvatarSize.sm,
                    decorative: true,
                  ),
                  if (showName) ...[
                    const SizedBox(width: SLSpacing.space2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ShellHeader.userNameMaxWidth,
                      ),
                      child: Text(
                        userName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyS.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ],
                  const SizedBox(width: SLSpacing.space1),
                  Icon(
                    Icons.expand_more_rounded,
                    size: SLIconSizes.icon16,
                    color: colors.iconMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String label, VoidCallback? onPressed) => MenuItemButton(
    onPressed: onPressed,
    child: Text(label, style: text.bodyS.copyWith(color: colors.textPrimary)),
  );
}
