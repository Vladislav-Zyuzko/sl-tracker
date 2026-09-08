import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/utils/sl_plural.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/copy_invitation_link_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Создание ссылки-приглашения (`docs/design/screens/project.md`).
///
/// После создания окно **не закрывается**, а показывает готовую ссылку:
/// иначе человек теряет её и создаёт вторую. Ссылка живёт ровно здесь —
/// это единственная точка копирования (D-04).
///
/// Роли «Администратор» в выборе нет (D-05), бессрочных приглашений нет
/// (US-20).
class CreateInvitationDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const CreateInvitationDialog({required this.slug, super.key});

  /// Короткое имя проекта.
  final String slug;

  /// Роли, доступные в приглашении.
  static const availableRoles = <SLRole>[SLRole.member, SLRole.reader];

  /// Сроки жизни ссылки.
  static const availableLifetimes = <CreateInvitationDtoExpiresInDays>[
    CreateInvitationDtoExpiresInDays.value1,
    CreateInvitationDtoExpiresInDays.value7,
    CreateInvitationDtoExpiresInDays.value30,
  ];

  /// Показывает окно.
  static Future<void> show(BuildContext context, String slug) =>
      showDialog<void>(
        context: context,
        builder: (context) => CreateInvitationDialog(slug: slug),
      );

  @override
  ConsumerState<CreateInvitationDialog> createState() =>
      _CreateInvitationDialogState();
}

class _CreateInvitationDialogState
    extends ConsumerState<CreateInvitationDialog> {
  var _role = SLRole.member;
  var _lifetime = CreateInvitationDtoExpiresInDays.value7;
  var _submitting = false;
  InvitationDto? _created;
  ApiFailure? _failure;

  Future<void> _submit() async {
    if (_submitting || _created != null) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final created = await ref
          .read(projectInvitationsProvider(widget.slug).notifier)
          .create(role: _role, expiresInDays: _lifetime);

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _created = created;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: SLDialog(
        title: created == null ? 'Создать приглашение' : 'Ссылка готова',
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось создать приглашение',
                description: _failure!.kind == ApiFailureKind.forbidden
                    ? 'Похоже, вашу роль в проекте изменили.'
                    : 'Проверьте соединение и попробуйте ещё раз.',
                details: _failure!.toString(),
              ),
        actions: created == null
            ? [
                SLButton(
                  label: 'Отмена',
                  variant: SLButtonVariant.secondary,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                SLButton(
                  label: 'Создать',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ]
            : [
                SLButton(
                  label: 'Готово',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
        child: created == null ? _buildForm() : _buildResult(created),
      ),
    );
  }

  Widget _buildForm() {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Роль для тех, кто вступит',
          style: text.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space2),
        RadioGroup<SLRole>(
          groupValue: _role,
          onChanged: (role) {
            if (role != null) setState(() => _role = role);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in CreateInvitationDialog.availableRoles)
                _RoleOption(
                  role: role,
                  selected: role == _role,
                  onSelect: () => setState(() => _role = role),
                ),
            ],
          ),
        ),
        const SizedBox(height: SLSpacing.space4),
        Text(
          'Срок действия',
          style: text.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space2),
        _LifetimeSelector(
          value: _lifetime,
          onChanged: (value) => setState(() => _lifetime = value),
        ),
        const SizedBox(height: SLSpacing.space4),
        // Главная защита от путаницы с адресом проекта (D-04).
        const SLBanner(
          title: 'По этой ссылке в проект войдёт любой, у кого она окажется',
          description:
              'Это не адрес проекта: ссылка-приглашение даёт членство '
              'в проекте.',
          variant: SLBannerVariant.warning,
        ),
      ],
    );
  }

  Widget _buildResult(InvitationDto created) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final url = created.url ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Роль: ${created.role == InvitationDtoRole.reader ? SLRole.reader.label : SLRole.member.label}'
          ' · ${SLPlural.days(_lifetime.json?.toInt() ?? 7)}',
          style: text.bodyS.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space2),
        // Поле только для чтения: ссылку можно выделить и скопировать руками,
        // а не только кнопкой.
        Container(
          padding: const EdgeInsets.all(SLSpacing.space2),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: SLRadii.smAll,
            border: Border.all(color: colors.border),
          ),
          child: SelectionArea(
            child: Text(
              url,
              style: text.mono.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: SLSpacing.space3),
        if (url.isNotEmpty)
          CopyInvitationLinkButton(
            url: url,
            size: SLButtonSize.md,
            expand: true,
          ),
        const SizedBox(height: SLSpacing.space4),
        const SLBanner(
          title: CopyInvitationLinkButton.explanation,
          description:
              'Отправляйте её только тем, кого действительно зовёте '
              'в проект.',
          variant: SLBannerVariant.warning,
        ),
      ],
    );
  }
}

/// Вариант роли: радиокнопка, название и что она даёт.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onSelect,
  });

  final SLRole role;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '${role.label}. ${role.description}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SLSpacing.space1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<SLRole>(value: role),
                const SizedBox(width: SLSpacing.space1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        role.label,
                        style: text.bodyS.copyWith(color: colors.textPrimary),
                      ),
                      Text(
                        role.description,
                        style: text.label.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Сегментированный выбор срока действия.
///
/// `SegmentedButton` из Material 3 не используется намеренно: его дефолты
/// (высота 40, галочка у выбранного, свои радиусы) пришлось бы переопределять
/// почти целиком, а сегментов здесь три и они однородные.
class _LifetimeSelector extends StatelessWidget {
  const _LifetimeSelector({required this.value, required this.onChanged});

  final CreateInvitationDtoExpiresInDays value;
  final ValueChanged<CreateInvitationDtoExpiresInDays> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SLRadii.smAll,
        border: Border.all(color: colors.borderStrong),
      ),
      child: Row(
        children: [
          for (final lifetime in CreateInvitationDialog.availableLifetimes)
            Expanded(
              child: _LifetimeSegment(
                lifetime: lifetime,
                selected: lifetime == value,
                onSelect: () => onChanged(lifetime),
              ),
            ),
        ],
      ),
    );
  }
}

/// Один сегмент выбора срока.
class _LifetimeSegment extends StatefulWidget {
  const _LifetimeSegment({
    required this.lifetime,
    required this.selected,
    required this.onSelect,
  });

  final CreateInvitationDtoExpiresInDays lifetime;
  final bool selected;
  final VoidCallback onSelect;

  @override
  State<_LifetimeSegment> createState() => _LifetimeSegmentState();
}

class _LifetimeSegmentState extends State<_LifetimeSegment> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final days = widget.lifetime.json?.toInt() ?? 7;
    final label = SLPlural.days(days);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      label: label,
      excludeSemantics: true,
      child: SLFocusRing(
        focused: _focused,
        child: Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            if (key != LogicalKeyboardKey.enter &&
                key != LogicalKeyboardKey.numpadEnter &&
                key != LogicalKeyboardKey.space) {
              return KeyEventResult.ignored;
            }
            widget.onSelect();

            return KeyEventResult.handled;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onSelect,
              child: Container(
                height: density.fieldMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.selected ? colors.surfaceSelected : null,
                  borderRadius: SLRadii.smAll,
                ),
                child: Text(
                  label,
                  style: widget.selected
                      ? text.bodySStrong.copyWith(color: colors.accentPressed)
                      : text.bodyS.copyWith(color: colors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
