import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/create_invitation_dialog.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/invitation_row.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_confirm_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Вкладка «Приглашения» (`docs/design/screens/project.md`).
///
/// Видна только администратору — у участника и читателя её нет вовсе,
/// а не серая (`screens/README.md`, 4).
///
/// Баннер вверху обязателен и не сворачивается: он и есть основная защита
/// от путаницы ссылки-приглашения с адресом проекта (D-04).
class ProjectInvitationsTab extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectInvitationsTab({required this.slug, super.key});

  /// Короткое имя проекта.
  final String slug;

  /// Сколько строк-скелетонов показывать.
  static const skeletonRows = 3;

  @override
  ConsumerState<ProjectInvitationsTab> createState() =>
      _ProjectInvitationsTabState();
}

class _ProjectInvitationsTabState extends ConsumerState<ProjectInvitationsTab> {
  Future<void> _create() => CreateInvitationDialog.show(context, widget.slug);

  Future<void> _revoke(InvitationDto invitation) async {
    final confirmed = await SLConfirmDialog.show(
      context,
      title: 'Отозвать приглашение?',
      message:
          'Ссылка сразу перестанет работать: тот, кто откроет её после '
          'отзыва, в проект не попадёт. Уже вступившие останутся '
          'участниками, и вернуть ссылку к жизни будет нельзя — '
          'понадобится новая.',
      confirmLabel: 'Отозвать',
      variant: SLButtonVariant.danger,
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(projectInvitationsProvider(widget.slug).notifier)
          .revoke(invitation.id);

      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .success('Приглашение отозвано');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      ref.read(toastControllerProvider.notifier).error(switch ((
        failure.kind,
        failure.code,
      )) {
        (_, 'invitation_not_found') => 'Приглашения больше нет',
        (ApiFailureKind.forbidden, _) => 'Недостаточно прав',
        _ => 'Не удалось отозвать приглашение',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitations = ref.watch(projectInvitationsProvider(widget.slug));
    final isPhone = SLBreakpoint.of(context).isPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: SLSpacing.space3),
          child: SLBanner(
            title:
                'Ссылка-приглашение даёт членство в проекте. '
                'Любой, кто её откроет, войдёт в проект с указанной ролью',
            description: 'Это не адрес проекта.',
            variant: SLBannerVariant.info,
          ),
        ),
        Align(
          alignment: isPhone ? Alignment.center : Alignment.centerRight,
          child: SLButton(
            label: 'Создать приглашение',
            icon: Icons.person_add_alt_1_rounded,
            expand: isPhone,
            onPressed: _create,
          ),
        ),
        const SizedBox(height: SLSpacing.space3),
        Expanded(
          child: invitations.when(
            loading: _Skeleton.new,
            error: (error, _) => SLErrorState(
              title: 'Не удалось загрузить приглашения',
              description: 'Проверьте соединение и попробуйте ещё раз.',
              onAction: () => ref
                  .read(projectInvitationsProvider(widget.slug).notifier)
                  .refresh(),
              details: ApiFailure.of(error).toString(),
            ),
            data: _buildList,
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<InvitationDto> invitations) {
    if (invitations.isEmpty) {
      return SLEmptyState(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Приглашений пока нет',
        description:
            'Создайте ссылку, чтобы позвать человека в проект. '
            'По ней войдёт любой, у кого она окажется.',
        actionLabel: 'Создать приглашение',
        onAction: _create,
      );
    }

    return ListView.builder(
      // Виртуализация без фиксированной высоты: строка растёт на телефоне,
      // где кнопка уезжает под текст.
      itemCount: invitations.length,
      itemBuilder: (context, index) {
        final invitation = invitations[index];

        return InvitationRow(
          key: ValueKey(invitation.id),
          invitation: invitation,
          // Отзывать нечего у истёкшего и отозванного: повторно активировать
          // их нельзя (US-22).
          onRevoke: invitation.state == InvitationDtoState.active
              ? () => _revoke(invitation)
              : null,
        );
      },
    );
  }
}

/// Скелетон списка приглашений.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return SLShimmeringEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var index = 0;
            index < ProjectInvitationsTab.skeletonRows;
            index++
          )
            Container(
              height: InvitationRow.height,
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.borderSubtle,
                    width: SLBorders.hairline,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  SLSkeletonBox(width: 72, height: 20),
                  SizedBox(width: SLSpacing.space2),
                  Expanded(child: SLSkeletonLine(width: 240)),
                  SizedBox(width: SLSpacing.space3),
                  SLSkeletonBox(width: 160, height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
