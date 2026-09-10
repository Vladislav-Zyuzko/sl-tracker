import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/core/realtime/realtime_client.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_providers.dart';
import 'package:sl_tracker_web/features/realtime/presentation/realtime_providers.dart';
import 'package:sl_tracker_web/features/shell/presentation/active_issues_providers.dart';
import 'package:sl_tracker_web/features/shell/presentation/shell_header.dart';
import 'package:sl_tracker_web/features/shell/presentation/shell_shortcuts.dart';
import 'package:sl_tracker_web/features/shell/presentation/shell_sidebar.dart';
import 'package:sl_tracker_web/features/shell/presentation/sidebar_providers.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_offline_bar.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Оболочка приложения (`docs/design/screens/app-shell.md`).
///
/// Каркас, внутри которого живут экраны после входа. Шапка и сайдбар
/// отрисовываются сразу и по-настоящему: область содержимого показывает
/// собственный скелетон, а не блокирует всю оболочку.
///
/// Сайдбар живой: он показывает мои незакрытые задачи и ищет по ним
/// **на сервере** (D-20). Сбой этого блока не обрушивает оболочку — шапка,
/// поиск и содержимое продолжают работать.
class AppShell extends ConsumerStatefulWidget {
  /// @nodoc
  const AppShell({required this.child, super.key});

  /// Экран, отрисованный внутри оболочки.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchFocusNode = FocusNode(debugLabel: 'sidebar-search');
  final _contentFocusNode = FocusNode(debugLabel: 'content');
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _contentFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// `/`, `Ctrl/Cmd + K`, `g` `i` — фокус в поиск.
  ///
  /// Если сайдбар свёрнут или спрятан, он сначала раскрывается: иначе фокус
  /// уехал бы в невидимое поле.
  void _focusSearch() {
    final breakpoint = SLBreakpoint.of(context);

    if (breakpoint.isPhone) {
      _scaffoldKey.currentState?.openDrawer();
    } else if (ref.read(sidebarCollapsedProvider)) {
      ref.read(sidebarCollapsedProvider.notifier).toggle();
    }

    // Поле могло только что появиться в дереве — ждём кадр.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
  }

  void _toggleSidebar() => ref.read(sidebarCollapsedProvider.notifier).toggle();

  void _go(String location) {
    if (SLBreakpoint.of(context).isPhone) {
      // Выдвижной сайдбар закрывается сам после перехода по ссылке (US-80).
      Navigator.of(context).maybePop();
    }
    context.go(location);
  }

  /// Запрос поиска ушёл на сервер, а не в фильтр по загруженной странице:
  /// иначе за пределами первых 50 строк осталось бы ровно то, что человек
  /// ищет (D-20).
  void _onSearchChanged(String query) =>
      ref.read(activeIssuesSearchProvider.notifier).search(query);

  void _clearSearch() {
    _searchController.clear();
    ref.read(activeIssuesSearchProvider.notifier).clear();
    _searchFocusNode.requestFocus();
  }

  void _openIssueInNewTab(String issueKey) {
    final navigator = ref.read(browserNavigatorProvider);
    final origin = navigator.origin;

    navigator.openInNewTab('$origin${AppRoutes.issuePath(issueKey)}');
  }

  /// Ключ задачи, открытой прямо сейчас: её строка в сайдбаре выбрана.
  String? _selectedIssueKey(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length != 2 || segments.first != 'issues') return null;

    return segments[1];
  }

  void _showHotkeys() {
    showDialog<void>(
      context: context,
      builder: (context) => const _HotkeysDialog(),
    );
  }

  /// Выход.
  ///
  /// Уводить на экран входа руками не нужно: состояние сессии меняется,
  /// и роутер сам приводит адрес в порядок.
  Future<void> _signOut() async {
    try {
      await ref.read(sessionControllerProvider.notifier).signOut();
    } on Object {
      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось выйти',
            actionLabel: 'Повторить',
            onAction: _signOut,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final location = GoRouterState.of(context).uri.path;
    // Узкая подписка: шапка перерисовывается на смене профиля,
    // а не на каждом чихе состояния сессии.
    final user = ref.watch(
      sessionControllerProvider.select((session) => session.user),
    );

    // На планшете сайдбар свёрнут принудительно, выбор пользователя
    // при этом сохраняется и вернётся на десктопе.
    final collapsed =
        breakpoint.isTablet || ref.watch(sidebarCollapsedProvider);

    // Счётчик уведомлений живой: `user:me` приносит его вместе с событием,
    // и отдельный запрос ради колокольчика не нужен.
    final unreadCount = ref.watch(unreadCountProvider).value;
    final connection = ref.watch(realtimeStatusProvider);

    // Возвращение связи подтверждается тостом, а полоса офлайна пропадает
    // сама (`components.md`, 17.4).
    ref.listen(realtimeStatusProvider, (previous, next) {
      if (previous == RealtimeStatus.offline && next == RealtimeStatus.online) {
        ref
            .read(toastControllerProvider.notifier)
            .success('Соединение восстановлено');
      }
    });

    final activeIssues = ref.watch(activeIssuesProvider);
    final searchQuery = ref.watch(activeIssuesSearchProvider);
    final page = activeIssues.value;

    // Состояние списка выводится из ответа и запроса: «задач нет»
    // и «поиск ничего не нашёл» — разные сообщения, и подменять одно другим
    // нельзя (`app-shell.md`, «Поиск: главный риск экрана»).
    final issuesState = switch (activeIssues) {
      AsyncError() => ActiveIssuesState.error,
      AsyncLoading(hasValue: false) => ActiveIssuesState.loading,
      _ when (page?.items.isEmpty ?? true) && searchQuery.isNotEmpty =>
        ActiveIssuesState.searchEmpty,
      _ when page?.items.isEmpty ?? true => ActiveIssuesState.empty,
      _ => ActiveIssuesState.data,
    };

    ShellSidebar buildSidebar({required bool collapsed}) => ShellSidebar(
      collapsed: collapsed,
      // На телефоне сайдбар живёт в выдвижной панели, и шеврон закрывает
      // её, а не сворачивает до 48 px — сворачивать там нечего.
      onToggleCollapsed: breakpoint.isPhone
          ? () => Navigator.of(context).maybePop()
          : _toggleSidebar,
      onOpenProjects: () => _go(AppRoutes.projects),
      searchFocusNode: _searchFocusNode,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      searchQuery: searchQuery,
      state: issuesState,
      issues: page?.items ?? const [],
      activeIssuesCount: page?.total,
      selectedIssueKey: _selectedIssueKey(location),
      isLoadingMore: page?.isLoadingMore ?? false,
      onRetry: () => ref.read(activeIssuesProvider.notifier).refresh(),
      onClearSearch: _clearSearch,
      onOpenIssue: (key) => _go(AppRoutes.issuePath(key)),
      onOpenIssueInNewTab: _openIssueInNewTab,
      onLoadMore: () => ref.read(activeIssuesProvider.notifier).loadMore(),
      isProjectsActive: location == AppRoutes.projects,
    );

    final sidebar = buildSidebar(collapsed: collapsed);

    return ShellShortcuts(
      onFocusSearch: _focusSearch,
      onToggleSidebar: _toggleSidebar,
      onGoProjects: () => _go(AppRoutes.projects),
      onGoNotifications: () => _go(AppRoutes.notifications),
      onShowHelp: _showHotkeys,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.surfaceSunken,
        drawer: breakpoint.isPhone
            ? Drawer(
                width: SLSizes.sidebarWidth,
                backgroundColor: colors.surfaceSunken,
                child: buildSidebar(collapsed: false),
              )
            : null,
        body: Column(
          children: [
            _SkipToContentLink(focusNode: _contentFocusNode),
            ShellHeader(
              onLogoTap: () => _go(AppRoutes.projects),
              onCreateIssue: null,
              onNotifications: () => _go(AppRoutes.notifications),
              onOpenProfile: () => _go(AppRoutes.profile),
              onOpenAccessList: () => _go(AppRoutes.access),
              userName: user?.displayName,
              userId: user?.id,
              userAvatarUrl: user?.avatarUrl,
              // Пункт «Доступ к трекеру» показывается по флагу из
              // `GET /api/me`: клиент не вычисляет право сам.
              canManageAccessList: user?.canManageAccessList ?? false,
              onSignOut: _signOut,
              unreadCount: unreadCount,
              onMenuTap: breakpoint.isPhone
                  ? () => _scaffoldKey.currentState?.openDrawer()
                  : null,
            ),
            // Полоса офлайна живёт под шапкой и над содержимым: она про всё
            // приложение сразу, а не про один экран.
            SLOfflineBar(visible: connection == RealtimeStatus.offline),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!breakpoint.isPhone)
                    AnimatedSize(
                      duration: SLMotion.durationOf(context, SLMotion.slow),
                      curve: SLMotion.slowCurve,
                      alignment: Alignment.centerLeft,
                      child: sidebar,
                    ),
                  Expanded(
                    child: Focus(
                      focusNode: _contentFocusNode,
                      skipTraversal: true,
                      child: Semantics(
                        container: true,
                        label: 'Содержимое',
                        child: _ContentArea(
                          breakpoint: breakpoint,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Область содержимого.
///
/// На `xl` центрируется и ограничивается 1600 px: растягивать рабочую область
/// на ультраширокий монитор нельзя, читать такие строки невозможно.
class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.breakpoint, required this.child});

  final SLBreakpoint breakpoint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final content = ColoredBox(color: colors.surface, child: child);

    if (breakpoint != SLBreakpoint.xl) return content;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SLSizes.workAreaMaxWidth),
        child: content,
      ),
    );
  }
}

/// Скрытая ссылка «Перейти к содержимому».
///
/// Видна только при фокусе. Без неё клавиатурный пользователь каждый раз
/// проходит весь сайдбар, чтобы добраться до экрана.
class _SkipToContentLink extends StatefulWidget {
  const _SkipToContentLink({required this.focusNode});

  final FocusNode focusNode;

  @override
  State<_SkipToContentLink> createState() => _SkipToContentLinkState();
}

class _SkipToContentLinkState extends State<_SkipToContentLink> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      // Только `Enter` и `Space`: ссылка не должна съедать `Tab`, иначе
      // из неё не выйти обычным обходом фокуса.
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final key = event.logicalKey;
        if (key != LogicalKeyboardKey.enter &&
            key != LogicalKeyboardKey.numpadEnter &&
            key != LogicalKeyboardKey.space) {
          return KeyEventResult.ignored;
        }

        widget.focusNode.requestFocus();

        return KeyEventResult.handled;
      },
      child: _focused
          ? Container(
              width: double.infinity,
              color: colors.accentSurface,
              padding: const EdgeInsets.all(SLSpacing.space2),
              child: Text(
                'Перейти к содержимому',
                style: text.bodySStrong.copyWith(color: colors.accentPressed),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// Окно со списком горячих клавиш — открывается по `?`.
class _HotkeysDialog extends StatelessWidget {
  const _HotkeysDialog();

  static const _hotkeys = <(String, String)>[
    ('/', 'Фокус в поиск по моим активным задачам'),
    ('Ctrl/Cmd + K', 'То же, работает и в полях ввода'),
    ('g затем p', 'К списку проектов'),
    ('g затем i', 'К списку активных задач'),
    ('g затем n', 'Центр уведомлений'),
    ('[', 'Свернуть и развернуть панель'),
    ('?', 'Это окно'),
    ('Esc', 'Закрыть верхний слой'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SLSizes.dialogMd),
        child: Padding(
          padding: const EdgeInsets.all(SLSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Горячие клавиши',
                style: text.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: SLSpacing.space4),
              for (final (key, description) in _hotkeys)
                Padding(
                  padding: const EdgeInsets.only(bottom: SLSpacing.space2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          key,
                          style: text.mono.copyWith(color: colors.textPrimary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          description,
                          style: text.bodyS.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
