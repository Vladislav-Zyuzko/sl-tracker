import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_list_providers.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/create_project_dialog.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_card.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран «Мои проекты» (`docs/design/screens/projects.md`).
///
/// Список содержит ровно те проекты, где пользователь состоит: чужой проект
/// отсюда не виден и узнать о его существовании нельзя
/// (`permissions.md`, п. 5). Поэтому состояния «нет прав» у экрана нет.
class ProjectsScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectsScreen({super.key});

  /// Высота шапки экрана.
  static const headerHeight = 44.0;

  /// Сколько карточек показывает скелетон.
  static const skeletonCount = 6;

  /// С какого числа карточек сетка начинает виртуализироваться.
  ///
  /// Порог зафиксирован спекой, а не подобран на глаз: до сотни карточек
  /// `Wrap` дешевле и проще, дальше нужен ленивый `GridView`.
  static const virtualizationThreshold = 100;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'projects-header');

  /// Сколько пикселей до конца списка запускают догрузку.
  static const _loadMoreThreshold = 400.0;

  @override
  void initState() {
    super.initState();
    // Фокус на заголовке экрана: скринридер объявляет, куда человек попал
    // (`screens/README.md`, 6).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _headerFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || slIsTypingInField()) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyN) {
      unawaited(_create());

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _create() async {
    final created = await CreateProjectDialog.show(context);
    if (created == null || !mounted) return;

    ref.read(toastControllerProvider.notifier).success('Проект создан');
    // Адрес берётся из ответа сервера, а не из клиентского предпросмотра:
    // при коллизии сервер добавляет суффикс (D-35).
    context.go(AppRoutes.projectPath(created.slug));
  }

  /// Перезапрашивает список: нужен, когда истекла подписанная ссылка
  /// на обложку — вместе со списком приходят свежие адреса.
  void _refreshList() => ref.read(projectsListProvider.notifier).refresh();

  void _open(ProjectDto project) =>
      context.go(AppRoutes.projectPath(project.slug));

  void _openInNewTab(ProjectDto project) {
    final navigator = ref.read(browserNavigatorProvider);
    final path = AppRoutes.projectPath(project.slug);

    navigator.openInNewTab('${navigator.origin}$path');
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final page = ref.watch(projectsListProvider);

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: ColoredBox(
        color: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              focusNode: _headerFocusNode,
              onCreate: _create,
              isPhone: breakpoint.isPhone,
            ),
            Expanded(
              child: page.when(
                loading: () => _Skeleton(breakpoint: breakpoint),
                error: (error, _) => _buildError(error),
                data: (data) => _buildGrid(data, breakpoint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    return SLErrorState(
      title: 'Не удалось загрузить проекты',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: () => ref.read(projectsListProvider.notifier).refresh(),
      details: failure.toString(),
    );
  }

  Widget _buildGrid(ProjectsListPage data, SLBreakpoint breakpoint) {
    if (data.items.isEmpty) {
      return SLEmptyState(
        icon: Icons.folder_open_outlined,
        title: 'У вас пока нет проектов',
        description:
            'Создайте свой проект или попросите ссылку-приглашение '
            'у коллеги — в чужой проект попадают только по ней.',
        actionLabel: 'Создать проект',
        onAction: _create,
      );
    }

    final isPhone = breakpoint.isPhone;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadMoreThreshold) {
          ref.read(projectsListProvider.notifier).loadMore().onError<Object>((
            _,
            _,
          ) {
            if (!mounted) return;
            ref
                .read(toastControllerProvider.notifier)
                .error('Не удалось загрузить ещё проекты');
          });
        }

        return false;
      },
      child: Semantics(
        container: true,
        label: 'Проекты, ${data.total}',
        child: data.items.length >= ProjectsScreen.virtualizationThreshold
            ? _VirtualizedGrid(
                data: data,
                onOpen: _open,
                onOpenInNewTab: _openInNewTab,
                onCoverExpired: _refreshList,
              )
            : _WrapGrid(
                data: data,
                isPhone: isPhone,
                onOpen: _open,
                onOpenInNewTab: _openInNewTab,
                onCoverExpired: _refreshList,
              ),
      ),
    );
  }
}

/// Шапка экрана: заголовок и создание проекта.
class _Header extends StatelessWidget {
  const _Header({
    required this.focusNode,
    required this.onCreate,
    required this.isPhone,
  });

  final FocusNode focusNode;
  final VoidCallback onCreate;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      height: ProjectsScreen.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: SLBorders.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: focusNode,
              child: Semantics(
                header: true,
                child: Text(
                  'Мои проекты',
                  style: text.h2.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          ),
          // Кнопка видна всем: отдельного права на создание проектов нет
          // (US-11, `permissions.md` 2.1).
          if (isPhone)
            // На телефоне подпись уходит, остаётся иконка. Доступное имя
            // при этом остаётся полным — оно же тултип.
            SLIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Создать проект',
              variant: SLButtonVariant.primary,
              onPressed: onCreate,
            )
          else
            SLButton(
              label: 'Создать проект',
              icon: Icons.add_rounded,
              onPressed: onCreate,
            ),
        ],
      ),
    );
  }
}

/// Сетка карточек с переносом — до сотни проектов.
class _WrapGrid extends StatelessWidget {
  const _WrapGrid({
    required this.data,
    required this.isPhone,
    required this.onOpen,
    required this.onOpenInNewTab,
    required this.onCoverExpired,
  });

  final ProjectsListPage data;
  final bool isPhone;
  final ValueChanged<ProjectDto> onOpen;
  final ValueChanged<ProjectDto> onOpenInNewTab;
  final VoidCallback onCoverExpired;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SLSpacing.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // На телефоне карточка занимает колонку целиком: обложка — главный
          // способ узнать проект глазами, и терять её ради плотности не стоит.
          final width = isPhone
              ? constraints.maxWidth
              : ProjectCard.defaultWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: SLSpacing.space4,
                runSpacing: SLSpacing.space4,
                children: [
                  for (final project in data.items)
                    ProjectCard(
                      key: ValueKey(project.id),
                      project: project,
                      width: width,
                      onOpen: () => onOpen(project),
                      onOpenInNewTab: () => onOpenInNewTab(project),
                      onCoverExpired: onCoverExpired,
                    ),
                ],
              ),
              if (data.isLoadingMore) const _LoadingMoreRow(),
            ],
          );
        },
      ),
    );
  }
}

/// Ленивая сетка — от сотни проектов и дальше.
class _VirtualizedGrid extends StatelessWidget {
  const _VirtualizedGrid({
    required this.data,
    required this.onOpen,
    required this.onOpenInNewTab,
    required this.onCoverExpired,
  });

  final ProjectsListPage data;
  final ValueChanged<ProjectDto> onOpen;
  final ValueChanged<ProjectDto> onOpenInNewTab;
  final VoidCallback onCoverExpired;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(SLSpacing.space4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: ProjectCard.defaultWidth + SLSpacing.space4,
        mainAxisSpacing: SLSpacing.space4,
        crossAxisSpacing: SLSpacing.space4,
        mainAxisExtent: ProjectCard.defaultHeight,
      ),
      itemCount: data.items.length,
      itemBuilder: (context, index) {
        final project = data.items[index];

        return ProjectCard(
          key: ValueKey(project.id),
          project: project,
          onOpen: () => onOpen(project),
          onOpenInNewTab: () => onOpenInNewTab(project),
          onCoverExpired: onCoverExpired,
        );
      },
    );
  }
}

/// Индикатор догрузки под сеткой.
class _LoadingMoreRow extends StatelessWidget {
  const _LoadingMoreRow();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: SLSpacing.space4),
      child: Center(
        child: SizedBox.square(
          dimension: SLIconSizes.icon16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.accent,
          ),
        ),
      ),
    );
  }
}

/// Скелетон сетки: шесть карточек в габаритах реальных.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.breakpoint});

  final SLBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SLSpacing.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = breakpoint.isPhone
              ? constraints.maxWidth
              : ProjectCard.defaultWidth;

          return SLShimmeringEffect(
            child: Wrap(
              spacing: SLSpacing.space4,
              runSpacing: SLSpacing.space4,
              children: [
                for (
                  var index = 0;
                  index < ProjectsScreen.skeletonCount;
                  index++
                )
                  _CardSkeleton(width: width),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Скелетон одной карточки.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final coverHeight = width / ProjectCard.coverAspectRatio;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: SLRadii.mdAll,
        border: Border.all(color: colors.border, width: SLBorders.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SLSkeletonBox(height: coverHeight, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(SLSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: ProjectCard.titleHeight,
                  child: SLSkeletonLine(width: width * 0.6, height: 16),
                ),
                SizedBox(
                  height: ProjectCard.descriptionHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SLSkeletonLine(width: width - SLSpacing.space6),
                      const SizedBox(height: SLSpacing.space1),
                      SLSkeletonLine(width: (width - SLSpacing.space6) * 0.4),
                    ],
                  ),
                ),
                const SizedBox(
                  height: ProjectCard.footerHeight,
                  child: Row(
                    children: [
                      SLSkeletonBox.circle(diameter: 20),
                      SizedBox(width: SLSpacing.space1),
                      SLSkeletonBox.circle(diameter: 20),
                      SizedBox(width: SLSpacing.space1),
                      SLSkeletonBox.circle(diameter: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
