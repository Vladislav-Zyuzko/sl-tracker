import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/utils/sl_plural.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_member_row.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/remove_member_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_confirm_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Вкладка «Участники» (`docs/design/screens/project.md`).
///
/// Список виден всем участникам, включая читателя (US-14). Управление ролями
/// и исключение — только администратору; у остальных меню «⋯» нет вовсе,
/// а не серое.
///
/// Пустого состояния у вкладки нет и быть не может: в проекте всегда есть
/// хотя бы один администратор (`permissions.md`, п. 7).
class ProjectMembersTab extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectMembersTab({
    required this.slug,
    required this.canManage,
    super.key,
  });

  /// Короткое имя проекта.
  final String slug;

  /// Администратор ли текущий пользователь.
  final bool canManage;

  /// Сколько строк-скелетонов показывать.
  static const skeletonRows = 5;

  @override
  ConsumerState<ProjectMembersTab> createState() => _ProjectMembersTabState();
}

class _ProjectMembersTabState extends ConsumerState<ProjectMembersTab> {
  /// Пояснение вместо выключенных пунктов меню.
  static const _lastAdminNotice =
      'В проекте должен остаться хотя бы один администратор';

  /// Сколько пикселей до конца списка запускают догрузку.
  static const _loadMoreThreshold = 200.0;

  Future<void> _changeRole(ProjectMemberDto member, SLRole role) async {
    // Понижение самого себя — потеря управления проектом. Об этом
    // предупреждаем до, а не показываем исчезнувшие вкладки после (US-15).
    if (member.isSelf && role != SLRole.admin) {
      final confirmed = await SLConfirmDialog.show(
        context,
        title: 'Сменить свою роль на «${role.label.toLowerCase()}»?',
        message:
            'После этого вы потеряете управление проектом: настройки '
            'и приглашения станут недоступны. Вернуть роль сможет только '
            'другой администратор.',
        confirmLabel: 'Сменить роль',
        variant: SLButtonVariant.danger,
      );

      if (confirmed != true || !mounted) return;
    }

    try {
      await ref
          .read(projectMembersProvider(widget.slug).notifier)
          .changeRole(member.userId, role);

      if (!mounted) return;
      // Роль текущего пользователя определяет набор вкладок — перечитываем
      // проект, чтобы интерфейс перестроился без перезагрузки страницы.
      if (member.isSelf) {
        ref.read(projectProvider(widget.slug).notifier).refresh();
      }

      ref
          .read(toastControllerProvider.notifier)
          .success('Роль изменена: ${role.label.toLowerCase()}');
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      // Бейдж уже откатился контроллером — здесь только объяснение.
      ref.read(toastControllerProvider.notifier).error(switch ((
        failure.kind,
        failure.code,
      )) {
        (_, 'last_project_admin') => _lastAdminNotice,
        (ApiFailureKind.forbidden, _) => 'Недостаточно прав',
        (ApiFailureKind.notFound, _) => 'Участника больше нет в проекте',
        _ => 'Не удалось изменить роль',
      });
    }
  }

  Future<void> _remove(ProjectMemberDto member) async {
    final unassigned = await RemoveMemberDialog.show(
      context,
      slug: widget.slug,
      member: member,
    );
    if (unassigned == null || !mounted) return;

    // Число задач без исполнителя приходит от сервера: показать его —
    // единственный способ дать человеку узнать последствие точно (D-31).
    final tail = unassigned > 0
        ? '. Задач осталось без исполнителя: $unassigned'
        : '';

    ref
        .read(toastControllerProvider.notifier)
        .success(
          member.isSelf
              ? 'Вы вышли из проекта$tail'
              : '${member.displayName} исключён из проекта$tail',
        );

    if (member.isSelf) {
      // Себя исключили — проекта для нас больше нет.
      ref.read(projectProvider(widget.slug).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = SLBreakpoint.of(context);
    final page = ref.watch(projectMembersProvider(widget.slug));

    return page.when(
      loading: () => _Skeleton(breakpoint: breakpoint),
      error: (error, _) => SLErrorState(
        title: 'Не удалось загрузить участников',
        description: 'Проверьте соединение и попробуйте ещё раз.',
        onAction: () =>
            ref.read(projectMembersProvider(widget.slug).notifier).refresh(),
        details: ApiFailure.of(error).toString(),
      ),
      data: (data) => _buildList(data, breakpoint),
    );
  }

  Widget _buildList(ProjectMembersPage data, SLBreakpoint breakpoint) {
    final isPhone = breakpoint.isPhone;
    final isTablet = breakpoint.isTablet;
    final extent = ProjectMemberRow.heightOf(
      compact: isPhone,
      tablet: isTablet,
    );
    final itemCount = data.items.length + (data.hasMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadMoreThreshold) {
          ref
              .read(projectMembersProvider(widget.slug).notifier)
              .loadMore()
              .onError<Object>((_, _) {
                if (!mounted) return;
                ref
                    .read(toastControllerProvider.notifier)
                    .error('Не удалось загрузить ещё участников');
              });
        }

        return false;
      },
      child: Semantics(
        container: true,
        label: 'Участники, ${SLPlural.members(data.total)}',
        child: ListView.builder(
          // Виртуализация: участников у проекта единицы, но список строится
          // по общему правилу, а не «пока их мало».
          itemExtent: extent,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index >= data.items.length) return const _LoadMoreRow();

            final member = data.items[index];
            final isLastAdmin =
                member.role == ProjectMemberDtoRole.admin &&
                data.hasSingleAdmin;

            return ProjectMemberRow(
              key: ValueKey(member.userId),
              member: member,
              compact: isPhone,
              tablet: isTablet,
              // Роль меняет только администратор. Последнего администратора
              // понизить нельзя — сервер ответит 409.
              onChangeRole: widget.canManage
                  ? (role) => _changeRole(member, role)
                  : null,
              // Выйти из проекта может любой участник — для этого достаточно
              // быть собой (US-16).
              onRemove: (widget.canManage || member.isSelf) && !isLastAdmin
                  ? () => _remove(member)
                  : null,
              lastAdminNotice:
                  isLastAdmin && (widget.canManage || member.isSelf)
                  ? _lastAdminNotice
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// Строка догрузки следующей страницы.
class _LoadMoreRow extends StatelessWidget {
  const _LoadMoreRow();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Center(
      child: SizedBox.square(
        dimension: SLIconSizes.icon16,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
      ),
    );
  }
}

/// Скелетон: пять строк в геометрии реальных.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.breakpoint});

  final SLBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final height = ProjectMemberRow.heightOf(
      compact: breakpoint.isPhone,
      tablet: breakpoint.isTablet,
    );

    return SLShimmeringEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < ProjectMembersTab.skeletonRows; index++)
            SizedBox(
              height: height,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: SLSpacing.space3),
                child: Row(
                  children: [
                    SLSkeletonBox.circle(diameter: 24),
                    SizedBox(width: SLSpacing.space2),
                    Expanded(child: SLSkeletonLine(width: 160)),
                    SizedBox(width: SLSpacing.space3),
                    SizedBox(
                      width: ProjectMemberRow.emailColumnWidth,
                      child: SLSkeletonLine(width: 180),
                    ),
                    SizedBox(
                      width: ProjectMemberRow.roleColumnWidth,
                      child: SLSkeletonBox(width: 64, height: 18),
                    ),
                    SizedBox(width: ProjectMemberRow.actionsColumnWidth),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
