import 'package:flutter/material.dart';

import 'package:sl_tracker_web/features/issues/domain/issue_row.dart';
import 'package:sl_tracker_web/features/shell/presentation/widgets/active_issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/navigation/sl_sidebar_item.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Что показывает список активных задач.
enum ActiveIssuesState {
  /// Данные грузятся: восемь строк-скелетонов по 36.
  loading,

  /// Активных задач нет.
  empty,

  /// Поиск ничего не нашёл.
  searchEmpty,

  /// Список не загрузился. Шапка, поиск и остальная оболочка при этом
  /// работают: сбой одного блока не обрушивает приложение.
  error,

  /// Есть данные.
  data,
}

/// Сайдбар оболочки (`docs/design/screens/app-shell.md`).
///
/// Отвечает ровно на один вопрос: «что делаю лично я» (D-19). Он не показывает
/// всё, что происходит в трекере, и не должен пытаться.
class ShellSidebar extends StatelessWidget {
  /// @nodoc
  const ShellSidebar({
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onOpenProjects,
    required this.searchFocusNode,
    required this.onSearchChanged,
    this.searchController,
    this.state = ActiveIssuesState.loading,
    this.issues = const [],
    this.activeIssuesCount,
    this.selectedIssueKey,
    this.searchQuery = '',
    this.isLoadingMore = false,
    this.onRetry,
    this.onClearSearch,
    this.onOpenIssue,
    this.onOpenIssueInNewTab,
    this.onLoadMore,
    this.isProjectsActive = false,
    super.key,
  });

  /// Свёрнут ли сайдбар до 48 px.
  final bool collapsed;

  /// Свернуть или развернуть.
  final VoidCallback onToggleCollapsed;

  /// Перейти к списку проектов.
  final VoidCallback onOpenProjects;

  /// Узел фокуса поля поиска: на него наводят `/` и `Ctrl/Cmd + K`.
  final FocusNode searchFocusNode;

  /// Изменился запрос поиска.
  final ValueChanged<String> onSearchChanged;

  /// Контроллер поля поиска. Нужен, чтобы «Очистить поиск» очищало и поле,
  /// а не только список.
  final TextEditingController? searchController;

  /// Состояние списка активных задач.
  final ActiveIssuesState state;

  /// Загруженные задачи.
  final List<MyIssue> issues;

  /// Число активных задач. `null` — ещё не загружено.
  final int? activeIssuesCount;

  /// Ключ открытой сейчас задачи: её строка показывается выбранной.
  final String? selectedIssueKey;

  /// Текущий запрос поиска: при непустом под полем появляется подпись
  /// о границах поиска.
  final String searchQuery;

  /// Идёт ли догрузка следующей порции.
  final bool isLoadingMore;

  /// Повторить загрузку списка.
  final VoidCallback? onRetry;

  /// Очистить поиск.
  final VoidCallback? onClearSearch;

  /// Открыть задачу.
  final ValueChanged<String>? onOpenIssue;

  /// Открыть задачу в новой вкладке.
  final ValueChanged<String>? onOpenIssueInNewTab;

  /// Догрузить следующую порцию.
  final VoidCallback? onLoadMore;

  /// Открыт ли сейчас экран списка проектов.
  final bool isProjectsActive;

  /// Высота строки активной задачи. Это `itemExtent` списка: без фиксированного
  /// экстента виртуализация в Flutter Web деградирует.
  static const issueRowExtent = 36.0;

  /// Сколько строк-скелетонов показывать при загрузке.
  static const skeletonRowCount = 8;

  /// Сколько пикселей до конца списка запускают догрузку.
  static const loadMoreThreshold = 200.0;

  /// Плейсхолдер поиска.
  ///
  /// Говорит, что вводить, — область поиска называет заголовок над полем
  /// (`components.md`, 4.2). Прежнее «Поиск по моим активным задачам»
  /// не помещалось в поле и обрезалось.
  static const searchHint = 'Название или ключ';

  /// Подпись под полем при непустом запросе.
  static const searchScopeNotice = 'Только среди ваших активных задач';

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    // Ширина одна на все случаи: 280 и закреплённым, и оверлеем,
    // и выдвижной панелью (`app-shell.md`, «Адаптив»).
    final width = collapsed
        ? SLSizes.sidebarCollapsedWidth
        : SLSizes.sidebarWidth;

    return Semantics(
      container: true,
      label: 'Навигация',
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          border: Border(
            right: BorderSide(color: colors.border, width: SLBorders.hairline),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: SLSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
              child: Align(
                alignment: collapsed ? Alignment.center : Alignment.centerRight,
                child: SLIconButton(
                  icon: collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  tooltip: collapsed ? 'Развернуть панель' : 'Свернуть панель',
                  size: SLButtonSize.sm,
                  onPressed: onToggleCollapsed,
                ),
              ),
            ),
            const SizedBox(height: SLSpacing.space2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
              child: SLSidebarItem(
                icon: Icons.folder_outlined,
                title: 'Мои проекты',
                collapsed: collapsed,
                isActive: isProjectsActive,
                onTap: onOpenProjects,
              ),
            ),
            const SizedBox(height: SLSpacing.space2),
            if (collapsed) ...[
              _CollapsedSearchButton(focusNode: searchFocusNode),
              const SizedBox(height: SLSpacing.space2),
              // В свёрнутом сайдбаре список не рисуется вовсе: на 48 px
              // строка задачи не помещается, и вместо неё — иконка
              // со счётчиком-точкой, как в раскладке из спеки.
              Expanded(child: _CollapsedActiveIssues(count: activeIssuesCount)),
            ] else ...[
              // Заголовок секции стоит **над** полем поиска, а не под ним:
              // он и есть постоянно видимое объяснение области поиска, и
              // плейсхолдеру эту работу больше не поручают
              // (`app-shell.md`, `components.md` 4.2).
              _buildListHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space2,
                ),
                child: SLSearchField(
                  hint: searchHint,
                  focusNode: searchFocusNode,
                  controller: searchController,
                  onQueryChanged: onSearchChanged,
                ),
              ),
              // Подпись появляется только при непустом запросе: пустое поле
              // не должно занимать место под объяснение (`app-shell.md`).
              if (searchQuery.isNotEmpty) _buildSearchScopeNotice(context),
              const SizedBox(height: SLSpacing.space2),
              Expanded(child: _buildList(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchScopeNotice(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SLSpacing.space2,
        SLSpacing.space1,
        SLSpacing.space2,
        0,
      ),
      // Подсказка переносится на вторую строку, а не обрезается:
      // обрезанная на середине, она бесполезна (`app-shell.md`).
      child: Text(
        searchScopeNotice,
        style: text.label.copyWith(color: colors.textMuted),
      ),
    );
  }

  Widget _buildListHeader(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return SizedBox(
      height: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'МОИ АКТИВНЫЕ ЗАДАЧИ',
                style: text.overline.copyWith(color: colors.textMuted),
              ),
            ),
            if (activeIssuesCount == null)
              const SLSkeletonBox(width: 20, height: 12)
            else
              Text(
                activeIssuesCount! > SLSidebarItem.countThreshold
                    ? '${SLSidebarItem.countThreshold}+'
                    : '$activeIssuesCount',
                style: text.label.copyWith(color: colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return switch (state) {
      ActiveIssuesState.loading => const _ActiveIssuesSkeleton(),
      ActiveIssuesState.empty => const _SidebarNotice(
        icon: Icons.check_circle_outline_rounded,
        title: 'Нет активных задач',
        description:
            'Сюда попадают задачи, где вы исполнитель '
            'и которые ещё не закрыты.',
      ),
      ActiveIssuesState.searchEmpty => _SidebarNotice(
        icon: Icons.search_off_rounded,
        title: 'Ничего не найдено среди ваших активных задач',
        description:
            'Поиск работает только по задачам, где вы исполнитель '
            'и которые не закрыты.',
        actionLabel: 'Очистить поиск',
        onAction: onClearSearch,
      ),
      ActiveIssuesState.error => _SidebarNotice(
        icon: Icons.error_outline_rounded,
        title: 'Не удалось загрузить задачи',
        description: 'Остальная часть приложения продолжает работать.',
        actionLabel: 'Повторить',
        onAction: onRetry,
      ),
      ActiveIssuesState.data => _buildIssues(context),
    };
  }

  Widget _buildIssues(BuildContext context) {
    final itemCount = issues.length + (isLoadingMore ? 1 : 0);

    return Semantics(
      container: true,
      label: 'Мои активные задачи, ${activeIssuesCount ?? issues.length}',
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < loadMoreThreshold) {
            onLoadMore?.call();
          }

          return false;
        },
        child: ListView.builder(
          // Виртуализация обязательна: у активного человека здесь сотни строк,
          // и рисовать их все ради панели 240 px недопустимо.
          itemExtent: issueRowExtent,
          itemCount: itemCount,
          padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
          itemBuilder: (context, index) {
            if (index >= issues.length) {
              return const SLShimmeringEffect(
                child: Row(
                  children: [
                    SLSkeletonBox(width: 26, height: 14),
                    SizedBox(width: SLSpacing.space2),
                    Expanded(child: SLSkeletonLine()),
                  ],
                ),
              );
            }

            final issue = issues[index];

            return ActiveIssueRow(
              key: ValueKey(issue.key),
              issue: issue,
              isSelected: issue.key == selectedIssueKey,
              onOpen: () => onOpenIssue?.call(issue.key),
              onOpenInNewTab: () => onOpenIssueInNewTab?.call(issue.key),
            );
          },
        ),
      ),
    );
  }
}

/// Кнопка поиска в свёрнутом сайдбаре.
///
/// Клик по ней разворачивает сайдбар и ставит фокус в поле — то же самое
/// делает `/`.
class _CollapsedSearchButton extends StatelessWidget {
  const _CollapsedSearchButton({required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SLIconButton(
        icon: Icons.search_rounded,
        tooltip: 'Поиск по моим активным задачам',
        size: SLButtonSize.sm,
        onPressed: focusNode.requestFocus,
      ),
    );
  }
}

/// Список активных задач в свёрнутом сайдбаре.
///
/// На 48 px строка задачи не помещается, поэтому от списка остаётся иконка,
/// а счётчик превращается в точку `accent` в правом верхнем углу — ровно так,
/// как описан свёрнутый сайдбар в спеке. Число остаётся в доступном имени:
/// точка не должна быть единственным носителем смысла.
class _CollapsedActiveIssues extends StatelessWidget {
  const _CollapsedActiveIssues({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final label = count == null
        ? 'Мои активные задачи'
        : 'Мои активные задачи, $count';

    return Align(
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: SLSizes.sidebarCollapsedWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: SLIconSizes.icon16,
                    color: colors.iconMuted,
                  ),
                  if (count != null && count! > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Скелетон списка активных задач: восемь строк по 36.
class _ActiveIssuesSkeleton extends StatelessWidget {
  const _ActiveIssuesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SLShimmeringEffect(
      child: ListView.builder(
        itemCount: ShellSidebar.skeletonRowCount,
        itemExtent: ShellSidebar.issueRowExtent,
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
        // Индикатор приоритета слева, дальше ключ и название — скелетон
        // повторяет геометрию реальной строки. Первый блок обёрнут во
        // Flexible: в узкой колонке он сжимается, а не ломает раскладку.
        itemBuilder: (context, index) => const Row(
          children: [
            Flexible(child: SLSkeletonBox(width: 26, height: 14)),
            SizedBox(width: SLSpacing.space2),
            Expanded(child: SLSkeletonLine()),
          ],
        ),
      ),
    );
  }
}

/// Сообщение на месте списка: пусто, пусто после поиска, ошибка.
class _SidebarNotice extends StatelessWidget {
  const _SidebarNotice({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(SLSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SLIconSizes.icon24, color: colors.iconMuted),
          const SizedBox(height: SLSpacing.space2),
          Text(title, style: text.bodyS.copyWith(color: colors.textPrimary)),
          const SizedBox(height: SLSpacing.space1),
          Text(
            description,
            style: text.label.copyWith(color: colors.textMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: SLSpacing.space2),
            SLButton(
              label: actionLabel!,
              variant: SLButtonVariant.ghost,
              size: SLButtonSize.sm,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
