import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка участника проекта (`docs/design/screens/project.md`).
///
/// Высота фиксирована и задана числом: это `itemExtent` виртуализированного
/// списка, а не сумма отступов.
class ProjectMemberRow extends StatefulWidget {
  /// @nodoc
  const ProjectMemberRow({
    required this.member,
    required this.onChangeRole,
    required this.onRemove,
    required this.lastAdminNotice,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  /// Участник.
  final ProjectMemberDto member;

  /// Сменить роль. `null` — прав нет, меню действий не показывается вовсе.
  final ValueChanged<SLRole>? onChangeRole;

  /// Исключить из проекта. `null` — исключить нельзя.
  final VoidCallback? onRemove;

  /// Почему нельзя понизить и исключить: строка-пояснение вместо
  /// выключенных пунктов меню. `null` — ограничения нет.
  final String? lastAdminNotice;

  /// Телефонная раскладка: карточка вместо строки таблицы.
  final bool compact;

  /// Планшетная раскладка: email уходит под имя третьей строкой.
  final bool tablet;

  /// Высота строки на десктопе.
  static const height = 48.0;

  /// Высота строки на планшете.
  static const tabletHeight = 64.0;

  /// Высота карточки на телефоне.
  static const compactHeight = 88.0;

  /// Ширина колонки адреса.
  static const emailColumnWidth = 220.0;

  /// Ширина колонки роли.
  static const roleColumnWidth = 96.0;

  /// Ширина колонки действий.
  static const actionsColumnWidth = 40.0;

  /// Высота строки для раскладки.
  static double heightOf({required bool compact, required bool tablet}) {
    if (compact) return compactHeight;

    return tablet ? tabletHeight : height;
  }

  @override
  State<ProjectMemberRow> createState() => _ProjectMemberRowState();
}

class _ProjectMemberRowState extends State<ProjectMemberRow> {
  final _menuController = MenuController();
  var _hovered = false;
  var _focused = false;

  bool get _hasMenu =>
      widget.onChangeRole != null ||
      widget.onRemove != null ||
      widget.lastAdminNotice != null;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        node.focusInDirection(TraversalDirection.down);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        node.focusInDirection(TraversalDirection.up);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (!_hasMenu) return KeyEventResult.ignored;
        _menuController.open();

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Focus(
      onKeyEvent: _onKeyEvent,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: SLFocusRing(
          focused: _focused,
          inset: true,
          child: Container(
            height: ProjectMemberRow.heightOf(
              compact: widget.compact,
              tablet: widget.tablet,
            ),
            decoration: BoxDecoration(
              color: _hovered ? colors.surfaceHover : colors.surface,
              border: Border(
                bottom: BorderSide(
                  color: colors.borderSubtle,
                  width: SLBorders.hairline,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
            child: widget.compact || widget.tablet
                ? _buildStacked()
                : _buildWide(),
          ),
        ),
      ),
    );
  }

  /// Описание строки — отдельный узел семантики, не накрывающий кнопку меню.
  ///
  /// Если завернуть строку целиком в `excludeSemantics`, у кнопки «⋯»
  /// пропадёт доступное имя, и человек со скринридером узнает, что действия
  /// есть, только методом тыка.
  Widget _describe(Widget child) => Semantics(
    // Свой узел: иначе подпись строки сольётся с доступным именем кнопки
    // действий, и обе станут нечитаемыми.
    container: true,
    label: _semanticsLabel(),
    excludeSemantics: true,
    child: child,
  );

  /// Десктоп: имя и дата слева, дальше адрес, роль и меню колонками.
  Widget _buildWide() {
    return Row(
      children: [
        Expanded(
          child: _describe(
            Row(
              children: [
                SLAvatar(
                  userId: widget.member.userId,
                  fullName: widget.member.displayName,
                  photoUrl: widget.member.avatarUrl,
                  size: SLAvatarSize.sm,
                  decorative: true,
                ),
                const SizedBox(width: SLSpacing.space2),
                Expanded(child: _buildNameAndJoined()),
                const SizedBox(width: SLSpacing.space3),
                SizedBox(
                  width: ProjectMemberRow.emailColumnWidth,
                  child: _buildEmail(),
                ),
                SizedBox(
                  width: ProjectMemberRow.roleColumnWidth,
                  child: _buildRole(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: ProjectMemberRow.actionsColumnWidth,
          child: _hasMenu ? _buildMenu() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Планшет и телефон: адрес уходит под имя, роль остаётся справа.
  Widget _buildStacked() {
    return Row(
      children: [
        Expanded(
          child: _describe(
            Row(
              children: [
                SLAvatar(
                  userId: widget.member.userId,
                  fullName: widget.member.displayName,
                  photoUrl: widget.member.avatarUrl,
                  size: SLAvatarSize.sm,
                  decorative: true,
                ),
                const SizedBox(width: SLSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNameAndJoined(),
                      const SizedBox(height: SLSpacing.space1),
                      _buildEmail(),
                    ],
                  ),
                ),
                const SizedBox(width: SLSpacing.space2),
                _buildRole(),
              ],
            ),
          ),
        ),
        SizedBox(
          width: ProjectMemberRow.actionsColumnWidth,
          child: _hasMenu ? _buildMenu() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNameAndJoined() {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Tooltip(
                message: widget.member.displayName,
                child: Text(
                  widget.member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyS.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
            // Пометка текстом, а не цветом.
            if (widget.member.isSelf) ...[
              const SizedBox(width: SLSpacing.space1),
              Text('(вы)', style: text.label.copyWith(color: colors.textMuted)),
            ],
          ],
        ),
        Text(
          'в проекте с ${SLDateFormat.short(widget.member.joinedAt)}',
          style: text.label.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildEmail() {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Tooltip(
      message: widget.member.email,
      child: SLMiddleEllipsisText(
        value: widget.member.email,
        style: text.bodyS.copyWith(color: colors.textMuted),
      ),
    );
  }

  /// Роль по умолчанию бейджа не получает (`system.md`, 7): в списке
  /// участников выделять «Участник» нечем и незачем. Скринридер роль всё
  /// равно слышит — она в доступном имени строки.
  Widget _buildRole() {
    final role = widget.member.role.role;
    if (role == SLRole.member) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: SLRoleBadge(role: role, short: true),
    );
  }

  Widget _buildMenu() {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final current = widget.member.role.role;
    final onChangeRole = widget.onChangeRole;
    final notice = widget.lastAdminNotice;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        if (onChangeRole != null)
          for (final role in SLRole.values)
            if (role != current && _isRoleAvailable(role))
              MenuItemButton(
                onPressed: () => onChangeRole(role),
                child: Text(switch (role) {
                  SLRole.admin => 'Сделать администратором',
                  SLRole.member => 'Сделать участником',
                  SLRole.reader => 'Сделать читателем',
                }, style: text.bodyS.copyWith(color: colors.textPrimary)),
              ),
        if (widget.onRemove != null) ...[
          const Divider(),
          MenuItemButton(
            onPressed: widget.onRemove,
            child: Text(
              widget.member.isSelf
                  ? 'Выйти из проекта'
                  : 'Исключить из проекта',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          ),
        ],
        // Не выключенный пункт, а пояснение: выключенный контрол выглядит
        // поломкой, а причина остаётся невысказанной.
        if (notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SLSpacing.space3,
              vertical: SLSpacing.space2,
            ),
            child: SizedBox(
              width: 240,
              child: Text(
                notice,
                style: text.label.copyWith(color: colors.textMuted),
              ),
            ),
          ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия для ${widget.member.displayName}',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  /// Понижение последнего администратора невозможно: сервер ответит 409,
  /// и предлагать такое действие нечестно.
  bool _isRoleAvailable(SLRole role) =>
      widget.lastAdminNotice == null ||
      widget.member.role.role != SLRole.admin ||
      role == SLRole.admin;

  String _semanticsLabel() {
    final member = widget.member;

    return [
      member.displayName,
      if (member.isSelf) 'вы',
      member.email,
      'роль: ${member.role.role.label.toLowerCase()}',
      'в проекте с ${SLDateFormat.short(member.joinedAt)}',
    ].join(', ');
  }
}
