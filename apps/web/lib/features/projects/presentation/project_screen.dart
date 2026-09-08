import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/tabs/project_invitations_tab.dart';
import 'package:sl_tracker_web/features/projects/presentation/tabs/project_members_tab.dart';
import 'package:sl_tracker_web/features/projects/presentation/tabs/project_queues_tab.dart';
import 'package:sl_tracker_web/features/projects/presentation/tabs/project_settings_tab.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/delete_project_dialog.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_header.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/navigation/sl_tabs.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Вкладки экрана проекта.
enum ProjectTab {
  /// Главный сценарий экрана — попасть в нужную очередь.
  queues,

  /// Виден всем участникам, включая читателя (US-14).
  members,

  /// Только администратору.
  invitations,

  /// Только администратору.
  settings,
}

/// Экран проекта (`docs/design/screens/project.md`).
///
/// Адресуется коротким именем, и **прежнее короткое имя тоже открывает
/// проект**: сервер отвечает 200 с действующим значением в поле `slug`,
/// а экран заменяет им адрес в строке браузера (US-18).
///
/// Проект, которого нет, и проект, где пользователь не состоит, показываются
/// одинаково — «Проект не найден», без названия и любых других данных
/// (US-13, `permissions.md`, п. 5).
class ProjectScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectScreen({required this.slug, super.key});

  /// Короткое имя из адреса. Может быть прежним, а не действующим.
  final String slug;

  /// Ширина контента.
  static const contentWidth = 1200.0;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'project-header');

  var _tab = ProjectTab.queues;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _headerFocusNode.dispose();
    super.dispose();
  }

  /// Заменяет адрес в строке браузера на действующий.
  ///
  /// Именно `replace`, а не `go`: человек пришёл по прежней ссылке, и лишняя
  /// запись в истории заставила бы «Назад» возвращать на тот же экран.
  void _syncAddress(String actualSlug) {
    if (actualSlug == widget.slug) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.replace(AppRoutes.projectPath(actualSlug));
    });
  }

  /// Набор вкладок по роли. У участника и читателя «Приглашений»
  /// и «Настроек» нет вовсе — не серых, а отсутствующих.
  List<ProjectTab> _tabsFor(SLRole role) => [
    ProjectTab.queues,
    ProjectTab.members,
    if (role == SLRole.admin) ...[ProjectTab.invitations, ProjectTab.settings],
  ];

  /// Перезапрашивает проект: нужен, когда истекла подписанная ссылка
  /// на обложку.
  void _refreshProject() =>
      ref.read(projectProvider(widget.slug).notifier).refresh();

  Future<void> _delete(ProjectDto project) async {
    final deleted = await DeleteProjectDialog.show(context, project);
    if (deleted != true || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success('Проект «${project.name}» удалён');
    context.go(AppRoutes.projects);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final project = ref.watch(projectProvider(widget.slug));

    return ColoredBox(
      color: colors.surface,
      child: project.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _buildError(error),
        data: _buildProject,
      ),
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    // 404 — это и «нет такого проекта», и «вы не участник». Различать их
    // снаружи нельзя: иначе экран подтверждал бы существование чужого
    // проекта (US-13).
    if (failure.kind == ApiFailureKind.notFound) {
      return SLErrorState(
        title: 'Проект не найден',
        description:
            'Возможно, он удалён, или вас нет среди его участников. '
            'Попросите ссылку-приглашение у того, кто в проекте.',
        actionLabel: 'К списку проектов',
        onAction: () => context.go(AppRoutes.projects),
      );
    }

    return SLErrorState(
      title: 'Не удалось загрузить проект',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: () => ref.read(projectProvider(widget.slug).notifier).refresh(),
      details: failure.toString(),
    );
  }

  Widget _buildProject(ProjectDto project) {
    _syncAddress(project.slug);

    final role = project.role.role;
    final isAdmin = role == SLRole.admin;
    final tabs = _tabsFor(role);

    // Роль изменили прямо сейчас, и открытая вкладка исчезла: возвращаемся
    // на «Очереди» и говорим, почему (US-15).
    var current = _tab;
    if (!tabs.contains(current)) {
      current = ProjectTab.queues;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || tabs.contains(_tab)) return;
        setState(() => _tab = ProjectTab.queues);
        ref
            .read(toastControllerProvider.notifier)
            .show('Ваша роль в проекте изменилась');
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectHeader(
          project: project,
          focusNode: _headerFocusNode,
          canManage: isAdmin,
          // Адрес проекта и ссылка-приглашение не показываются вместе (D-04).
          showAddress: current != ProjectTab.invitations,
          onEdit: () => setState(() => _tab = ProjectTab.settings),
          onDelete: () => _delete(project),
          // Ссылка на обложку подписана на 10 минут. Истекла — перезапрашиваем
          // проект и получаем свежую; до ответа стоит монограмма.
          onCoverExpired: _refreshProject,
        ),
        SLTabBar<ProjectTab>(
          tabs: _buildTabItems(tabs, project, isAdmin: isAdmin),
          value: current,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ProjectScreen.contentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(SLSpacing.space4),
                child: _buildTabContent(current, project, isAdmin: isAdmin),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<SLTabItem<ProjectTab>> _buildTabItems(
    List<ProjectTab> tabs,
    ProjectDto project, {
    required bool isAdmin,
  }) {
    // Счётчики нужны самим вкладкам — те же провайдеры, те же запросы:
    // лишнего обращения к серверу не будет.
    final invitations = isAdmin
        ? ref.watch(projectInvitationsProvider(project.slug))
        : null;
    final queues = ref.watch(projectQueuesProvider(project.slug));

    return [
      for (final tab in tabs)
        switch (tab) {
          ProjectTab.queues => SLTabItem(
            value: ProjectTab.queues,
            label: 'Очереди',
            count: queues.value?.length ?? SLTabItem.loading,
          ),
          ProjectTab.members => SLTabItem(
            value: ProjectTab.members,
            label: 'Участники',
            count: project.memberCount.toInt(),
          ),
          ProjectTab.invitations => SLTabItem(
            value: ProjectTab.invitations,
            label: 'Приглашения',
            count: invitations?.value?.length ?? SLTabItem.loading,
          ),
          ProjectTab.settings => const SLTabItem(
            value: ProjectTab.settings,
            label: 'Настройки',
          ),
        },
    ];
  }

  Widget _buildTabContent(
    ProjectTab tab,
    ProjectDto project, {
    required bool isAdmin,
  }) => switch (tab) {
    ProjectTab.queues => ProjectQueuesTab(
      slug: project.slug,
      canManage: isAdmin,
    ),
    ProjectTab.members => ProjectMembersTab(
      slug: project.slug,
      canManage: isAdmin,
    ),
    ProjectTab.invitations => ProjectInvitationsTab(slug: project.slug),
    ProjectTab.settings => ProjectSettingsTab(
      project: project,
      onCoverExpired: _refreshProject,
      // Адрес в строке браузера меняем сразу: человек должен видеть новый
      // адрес там же, где он его только что задал.
      onSlugChanged: (slug) => context.replace(AppRoutes.projectPath(slug)),
      onDelete: () => _delete(project),
    ),
  };
}

/// Загрузка: шапка и ряд вкладок отрисованы сразу, содержимое — скелетон.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectHeaderSkeleton(),
        // Вкладки, которые видны всем: набор для администратора появится,
        // когда придёт роль, — гадать о ней до ответа сервера нельзя.
        SLTabBar<ProjectTab>(
          tabs: const [
            SLTabItem(
              value: ProjectTab.queues,
              label: 'Очереди',
              count: SLTabItem.loading,
            ),
            SLTabItem(
              value: ProjectTab.members,
              label: 'Участники',
              count: SLTabItem.loading,
            ),
          ],
          value: ProjectTab.queues,
          onChanged: (_) {},
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(SLSpacing.space4),
            child: SLShimmeringEffect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SLSkeletonLine(height: 44),
                  SizedBox(height: SLSpacing.space2),
                  SLSkeletonLine(height: 44),
                  SizedBox(height: SLSpacing.space2),
                  SLSkeletonLine(height: 44),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
