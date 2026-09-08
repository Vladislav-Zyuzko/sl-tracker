import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/core/utils/sl_plural.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/copy_invitation_link_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка приглашения (`docs/design/screens/project.md`).
///
/// Истёкшие и отозванные остаются в списке приглушёнными (US-22), но
/// приглушённость — не единственный носитель смысла: у состояния есть плашка
/// с текстом, иначе «истекло» не прочитал бы ни скринридер, ни человек
/// с плохим зрением.
class InvitationRow extends StatelessWidget {
  /// @nodoc
  const InvitationRow({
    required this.invitation,
    required this.onRevoke,
    super.key,
  });

  /// Приглашение.
  final InvitationDto invitation;

  /// Отозвать. `null` — отзывать нечего: приглашение уже не действует.
  final VoidCallback? onRevoke;

  /// Высота строки на десктопе.
  static const height = 56.0;

  /// Непрозрачность недействующего приглашения.
  static const inactiveOpacity = 0.6;

  bool get _isActive => invitation.state == InvitationDtoState.active;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final isPhone = SLBreakpoint.of(context).isPhone;
    final url = invitation.url;

    // Описание строки и кнопки — разные узлы семантики. Если завернуть
    // строку целиком в `excludeSemantics`, доступное имя кнопки
    // «Скопировать ссылку-приглашение» пропадёт, а вместе с ним и половина
    // разведения D-04: в скринридере оно обязано работать так же.
    final content = Semantics(
      // `container: true` обязателен: без своего узла подпись строки
      // сливается с доступным именем соседней кнопки, и «Скопировать
      // ссылку-приглашение» перестаёт существовать для скринридера.
      container: true,
      label: _semanticsLabel(),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [_buildSummary(context), _buildAuthor(context)],
      ),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Копировать можно только действующую ссылку: у истёкшей и отозванной
        // адреса нет вовсе, повторно активировать её нельзя (US-22).
        if (_isActive && url != null) CopyInvitationLinkButton(url: url),
        if (onRevoke != null) ...[
          const SizedBox(width: SLSpacing.space2),
          _RevokeMenu(onRevoke: onRevoke!),
        ],
      ],
    );

    return Opacity(
      opacity: _isActive ? 1 : inactiveOpacity,
      child: Container(
        constraints: BoxConstraints(minHeight: isPhone ? 0 : height),
        padding: const EdgeInsets.symmetric(
          horizontal: SLSpacing.space3,
          vertical: SLSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: SLBorders.hairline,
            ),
          ),
        ),
        child: isPhone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: SLSpacing.space2),
                  Align(alignment: Alignment.centerLeft, child: actions),
                ],
              )
            : Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: SLSpacing.space3),
                  actions,
                ],
              ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Row(
      children: [
        _StateChip(state: invitation.state),
        const SizedBox(width: SLSpacing.space2),
        Flexible(
          child: Text(
            _summary(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyS.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthor(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final author = invitation.createdBy.displayName ?? 'неизвестно кем';

    return Text(
      'создал: $author, ${SLDateFormat.short(invitation.createdAt)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.label.copyWith(color: colors.textMuted),
    );
  }

  /// «Участник · 7 дней · до 19 фев · вступили: 2».
  ///
  /// У недействующего приглашения срок жизни уже неинтересен — важно,
  /// когда оно перестало работать.
  String _summary() {
    final role = invitation.role.role.label;
    final accepted = 'вступили: ${invitation.acceptedCount.toInt()}';

    return switch (invitation.state) {
      InvitationDtoState.active => [
        role,
        SLPlural.days(_lifetimeDays()),
        'до ${SLDateFormat.short(invitation.expiresAt)}',
        accepted,
      ].join(' · '),
      InvitationDtoState.expired => [
        role,
        'истекло ${SLDateFormat.short(invitation.expiresAt)}',
        accepted,
      ].join(' · '),
      InvitationDtoState.revoked || InvitationDtoState.$unknown => [
        role,
        if (invitation.revokedAt != null)
          'отозвано ${SLDateFormat.short(invitation.revokedAt!)}',
        accepted,
      ].join(' · '),
    };
  }

  /// Срок жизни ссылки в днях.
  ///
  /// Берётся из контракта: раньше он считался по датам создания и истечения,
  /// и это была догадка — теперь сервер отдаёт значение прямо. Незнакомое
  /// значение (бэкенд завёл новый срок) не должно оставлять строку без
  /// подписи, поэтому для него остаётся прежний расчёт.
  int _lifetimeDays() =>
      invitation.lifetimeDays.json?.toInt() ??
      invitation.expiresAt.difference(invitation.createdAt).inDays;

  String _semanticsLabel() =>
      'Приглашение. ${_stateLabel(invitation.state)}. ${_summary()}';

  static String _stateLabel(InvitationDtoState state) => switch (state) {
    InvitationDtoState.active => 'Действует',
    InvitationDtoState.expired => 'Истекло',
    InvitationDtoState.revoked || InvitationDtoState.$unknown => 'Отозвано',
  };
}

/// Плашка состояния приглашения: цвет не единственный носитель смысла.
class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final InvitationDtoState state;

  /// Высота плашки.
  static const height = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final (background, foreground) = switch (state) {
      InvitationDtoState.active => (colors.successSurface, colors.success),
      InvitationDtoState.expired => (
        colors.surfaceSunken,
        colors.textSecondary,
      ),
      InvitationDtoState.revoked ||
      InvitationDtoState.$unknown => (colors.dangerSurface, colors.danger),
    };

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: SLRadii.smAll),
      child: Text(
        InvitationRow._stateLabel(state),
        style: text.caption.copyWith(color: foreground),
      ),
    );
  }
}

/// Меню «⋯» строки приглашения. Есть только у действующего.
class _RevokeMenu extends StatelessWidget {
  const _RevokeMenu({required this.onRevoke});

  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: onRevoke,
          child: Text(
            'Отозвать',
            style: text.bodyS.copyWith(color: colors.danger),
          ),
        ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия с приглашением',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
