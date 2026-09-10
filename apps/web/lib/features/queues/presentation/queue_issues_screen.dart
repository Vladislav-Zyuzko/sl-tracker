import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/create_issue_dialog.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/issues_list_view.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/queue_issues_toolbar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/lists/sl_issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран списка задач очереди (`docs/design/screens/queue-issues.md`).
///
/// Самый нагруженный по данным экран продукта: до 1000 задач в очереди.
/// Отсюда всё остальное — фиксированный `itemExtent`, курсорная пагинация
/// и запрет на перестройку строк ради наведения мыши.
///
/// Фильтр и сортировка живут **в адресе страницы**: ссылку на отфильтрованный
/// список можно скопировать и отправить, а F5 не сбрасывает выбор (US-32).
class QueueIssuesScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const QueueIssuesScreen({
    required this.queueKey,
    this.statusKeys = const [],
    this.sort = IssueSort.priority,
    super.key,
  });

  /// Ключ очереди из адреса. Уникален глобально и неизменяем (D-06).
  final String queueKey;

  /// Ключи статусов из `?status=`.
  final List<String> statusKeys;

  /// Порядок из `?sort=`.
  final IssueSort sort;

  /// Сколько строк-скелетонов показывать при первой загрузке.
  static const skeletonRows = 12;

  @override
  ConsumerState<QueueIssuesScreen> createState() => _QueueIssuesScreenState();
}

class _QueueIssuesScreenState extends ConsumerState<QueueIssuesScreen> {
  final _filterFocusNode = FocusNode(debugLabel: 'queue-status-filter');

  @override
  void dispose() {
    _filterFocusNode.dispose();
    super.dispose();
  }

  QueueIssuesQuery get _query => QueueIssuesQuery(
    queueKey: widget.queueKey,
    statusKeys: widget.statusKeys,
    sort: widget.sort,
  );

  /// Записывает фильтр и сортировку в адрес страницы.
  ///
  /// Значения по умолчанию в адрес не пишутся: чистый адрес `/queues/DEV`
  /// означает «все статусы, по приоритету», и захламлять ссылку пустыми
  /// параметрами незачем.
  void _applyQuery({List<String>? statusKeys, IssueSort? sort}) {
    final keys = statusKeys ?? widget.statusKeys;
    final order = sort ?? widget.sort;

    final query = <String, String>{
      if (keys.isNotEmpty) 'status': keys.join(','),
      if (order != IssueSort.initial) 'sort': order.code,
    };

    context.go(
      Uri(
        path: AppRoutes.queuePath(widget.queueKey),
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  /// Ключи статусов в порядке самой очереди, а не в порядке кликов: в адресе
  /// `?status=in_progress,review` читается как знакомый ряд.
  void _onStatusesChanged(List<String> keys, List<IssueStatusRef> statuses) {
    final ordered = [
      for (final status in statuses)
        if (keys.contains(status.key)) status.key,
    ];

    _applyQuery(
      statusKeys: ordered.isEmpty && keys.isNotEmpty ? keys : ordered,
    );
  }

  void _openIssue(String issueKey) => context.go(AppRoutes.issuePath(issueKey));

  void _openIssueInNewTab(String issueKey) {
    final navigator = ref.read(browserNavigatorProvider);

    navigator.openInNewTab(
      '${navigator.origin}${AppRoutes.issuePath(issueKey)}',
    );
  }

  Future<void> _createIssue() async {
    final created = await CreateIssueDialog.show(context, widget.queueKey);
    if (created == null || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success('Задача ${created.key} создана');
    // Новая задача попадает в список только после перезапроса: её место
    // в порядке по приоритету знает сервер, а не клиент.
    ref.read(queueIssuesProvider(_query).notifier).refresh();
  }

  /// Возвращает `false`, если сервер отказал: список подсветит строку
  /// и вернёт прежний статус.
  Future<bool> _changeStatus(String issueKey, IssueStatusRef status) async {
    try {
      await ref
          .read(queueIssuesProvider(_query).notifier)
          .changeStatus(issueKey, status);

      return true;
    } on Object {
      if (!mounted) return false;

      // Строку контроллер уже вернул к прежнему статусу — здесь только
      // объяснение и возможность повторить.
      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось изменить статус $issueKey',
            actionLabel: 'Повторить',
            onAction: () => _changeStatus(issueKey, status),
          );

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final queue = ref.watch(queueProvider(widget.queueKey));
    final statuses =
        ref.watch(queueStatusesProvider(widget.queueKey)).value ?? const [];
    final issues = ref.watch(queueIssuesProvider(_query));

    // Очереди нет или пользователь не участник проекта — снаружи это одно
    // и то же, и различать их нельзя (`permissions.md`, п. 5).
    final queueFailure = queue.error == null
        ? null
        : ApiFailure.of(queue.error!);
    if (queueFailure?.kind == ApiFailureKind.notFound) {
      return const _QueueNotFound();
    }

    final page = issues.value;
    final canEdit = page?.canEdit ?? false;
    final isPhone = SLBreakpoint.of(context).isPhone;

    return ColoredBox(
      color: colors.surface,
      child: SLShortcuts(
        // `c` и `f` живут на уровне экрана, а не списка: они нужны и когда
        // список пуст, и когда он не в фокусе.
        //
        // `SLShortcuts`, а не `CallbackShortcuts`: на этом же экране стоит
        // поле фильтра, и `c`/`f` (на русской раскладке «с» и «а») обязаны
        // в него набираться, а не поглощаться хоткеем.
        bindings: {
          // Создавать нечего — клавишу не отбираем вовсе.
          if (canEdit)
            const SingleActivator(LogicalKeyboardKey.keyC): _createIssue,
          const SingleActivator(LogicalKeyboardKey.keyF):
              _filterFocusNode.requestFocus,
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QueueHeader(
                  queue: queue.value,
                  queueKey: widget.queueKey,
                  // Кнопка появляется только когда роль известна и это
                  // не читатель: показать её и убрать — хуже, чем показать
                  // на секунду позже.
                  onCreateIssue: canEdit && !isPhone ? _createIssue : null,
                ),
                QueueIssuesToolbar(
                  statuses: statuses,
                  selectedKeys: widget.statusKeys,
                  sort: widget.sort,
                  total: page?.total,
                  filterFocusNode: _filterFocusNode,
                  onStatusesChanged: (keys) =>
                      _onStatusesChanged(keys, statuses),
                  onSortChanged: (sort) => _applyQuery(sort: sort),
                ),
                Expanded(child: _buildBody(issues, statuses)),
              ],
            ),
            // На телефоне «Создать задачу» — плавающая кнопка: в шапке
            // 44 px для неё места нет.
            if (canEdit && isPhone)
              Positioned(
                right: SLSpacing.space4,
                bottom: SLSpacing.space4,
                child: FloatingActionButton(
                  onPressed: _createIssue,
                  tooltip: 'Создать задачу',
                  backgroundColor: colors.accent,
                  foregroundColor: colors.textOnAccent,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<QueueIssuesPage> issues,
    List<IssueStatusRef> statuses,
  ) {
    final layout = SLIssueRowLayout.of(SLBreakpoint.of(context));

    return issues.when(
      loading: () => _Skeleton(layout: layout),
      error: (error, _) => _buildError(error),
      data: (page) {
        if (page.items.isEmpty) return _buildEmpty(page);

        return IssuesListView(
          page: page,
          statuses: statuses,
          layout: layout,
          queueKey: widget.queueKey,
          onOpenIssue: _openIssue,
          onOpenIssueInNewTab: _openIssueInNewTab,
          onChangeStatus: _changeStatus,
          onLoadMore: () =>
              ref.read(queueIssuesProvider(_query).notifier).loadMore(),
          onRetryLoadMore: () =>
              ref.read(queueIssuesProvider(_query).notifier).retryLoadMore(),
          onEscape: () {
            _filterFocusNode.requestFocus();
          },
        );
      },
    );
  }

  Widget _buildEmpty(QueueIssuesPage page) {
    if (widget.statusKeys.isNotEmpty) {
      return SLEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Ничего не найдено',
        description: 'Ни одна задача не подходит под выбранные статусы.',
        actionLabel: 'Сбросить фильтры',
        actionVariant: SLButtonVariant.ghost,
        onAction: () => _applyQuery(statusKeys: const []),
      );
    }

    return SLEmptyState(
      icon: Icons.inbox_outlined,
      title: 'В этой очереди пока нет задач',
      description: page.canEdit
          ? 'Создайте первую — она получит ключ ${widget.queueKey}-1.'
          : 'Задачи появятся, когда их создадут участники проекта.',
      actionLabel: page.canEdit ? 'Создать задачу' : null,
      onAction: page.canEdit ? _createIssue : null,
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    if (failure.kind == ApiFailureKind.notFound) return const _QueueNotFound();

    return SLErrorState(
      title: 'Не удалось загрузить задачи',
      description: widget.statusKeys.isEmpty
          ? 'Проверьте соединение и попробуйте ещё раз.'
          : 'Проверьте соединение или сбросьте фильтры и попробуйте снова.',
      onAction: () => ref.read(queueIssuesProvider(_query).notifier).refresh(),
      details: failure.toString(),
    );
  }
}

/// Шапка экрана: название очереди, её ключ и «Создать задачу».
class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.queue,
    required this.queueKey,
    this.onCreateIssue,
  });

  final QueueDto? queue;
  final String queueKey;
  final VoidCallback? onCreateIssue;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final description = queue?.description;

    return Container(
      height: density.toolbarHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
      child: Row(
        children: [
          Flexible(
            child: queue == null
                ? const SLShimmeringEffect(
                    child: SLSkeletonLine(width: 180, height: 20),
                  )
                : Text(
                    queue!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.h2.copyWith(color: colors.textPrimary),
                  ),
          ),
          if (description != null && description.trim().isNotEmpty)
            _DescriptionPopover(description: description),
          const SizedBox(width: SLSpacing.space3),
          // Ключ очереди — подсказка, из чего складываются ключи задач.
          Text(
            queue?.key ?? queueKey,
            style: text.bodySStrong.copyWith(color: colors.textMuted),
          ),
          const Spacer(),
          if (onCreateIssue != null)
            SLButton(
              label: 'Создать задачу',
              icon: Icons.add_rounded,
              onPressed: onCreateIssue,
            ),
        ],
      ),
    );
  }
}

/// Описание очереди — в поповере, а не в шапке: в шапке оно съело бы строку
/// данных.
///
/// Текст показывается как есть, без разбора Markdown: рендерер разметки —
/// отдельный компонент (`components.md`, 18), и его ещё нет. Показывать
/// исходник честнее, чем исполнять неизвестно что (D-22).
class _DescriptionPopover extends StatelessWidget {
  const _DescriptionPopover({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SLSizes.readableTextWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(SLSpacing.space3),
            child: SelectionArea(
              child: Text(
                description,
                style: text.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.info_outline_rounded,
        tooltip: 'Описание очереди',
        size: SLButtonSize.sm,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Очередь не найдена — или её нет, или пользователь не участник проекта.
///
/// Текст намеренно не различает эти случаи: иначе экран подтверждал бы
/// существование чужой очереди.
class _QueueNotFound extends StatelessWidget {
  const _QueueNotFound();

  @override
  Widget build(BuildContext context) => SLErrorState(
    title: 'Очередь не найдена',
    description:
        'Возможно, она удалена, или у вас нет доступа '
        'к её проекту.',
    actionLabel: 'К списку проектов',
    onAction: () => GoRouter.of(context).go(AppRoutes.projects),
  );
}

/// Загрузка: заголовки колонок настоящие, ниже двенадцать строк-скелетонов.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.layout});

  final SLIssueRowLayout layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SLIssueTableHeader(layout: layout),
        Expanded(
          child: SLShimmeringEffect(
            child: ListView.builder(
              itemExtent: layout.extent,
              itemCount: QueueIssuesScreen.skeletonRows,
              itemBuilder: (context, index) =>
                  SLIssueRowSkeleton(index: index, layout: layout),
            ),
          ),
        ),
      ],
    );
  }
}
