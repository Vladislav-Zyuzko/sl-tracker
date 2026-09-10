import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/create_queue_dialog.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/delete_queue_dialog.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/queue_row.dart';
import 'package:sl_tracker_web/features/queues/presentation/widgets/rename_queue_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Вкладка «Очереди» (`docs/design/screens/project.md`).
///
/// Главный сценарий экрана проекта — попасть в нужную очередь, поэтому
/// вкладка первая и открыта по умолчанию. Создание, переименование
/// и удаление — только администратору (US-30, US-33, US-34); у остальных
/// кнопок и меню нет вовсе, а не серые.
class ProjectQueuesTab extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectQueuesTab({
    required this.slug,
    required this.canManage,
    super.key,
  });

  /// Короткое имя проекта.
  final String slug;

  /// Администратор ли текущий пользователь.
  final bool canManage;

  /// Сколько строк-скелетонов показывать при загрузке.
  static const skeletonRows = 5;

  /// С какого числа очередей список виртуализируется.
  ///
  /// У проекта их единицы, и `ListView.builder` ради трёх строк — лишняя
  /// прокручиваемая область внутри вкладки. На сотне очередей всё меняется.
  static const virtualizationThreshold = 100;

  @override
  ConsumerState<ProjectQueuesTab> createState() => _ProjectQueuesTabState();
}

class _ProjectQueuesTabState extends ConsumerState<ProjectQueuesTab> {
  void _open(String key) => context.go(AppRoutes.queuePath(key));

  void _openInNewTab(String key) {
    final navigator = ref.read(browserNavigatorProvider);

    navigator.openInNewTab('${navigator.origin}${AppRoutes.queuePath(key)}');
  }

  Future<void> _create() async {
    if (!widget.canManage) return;

    final created = await CreateQueueDialog.show(context, widget.slug);
    if (created == null || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success('Очередь ${created.key} создана');
  }

  Future<void> _rename(QueueDto queue) async {
    final updated = await RenameQueueDialog.show(
      context,
      slug: widget.slug,
      queue: queue,
    );
    if (updated == null || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success('Очередь ${updated.key} изменена');
  }

  Future<void> _delete(QueueDto queue) async {
    final deleted = await DeleteQueueDialog.show(
      context,
      slug: widget.slug,
      queue: queue,
    );
    if (deleted != true || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success('Очередь ${queue.key} удалена');
  }

  @override
  Widget build(BuildContext context) {
    final queues = ref.watch(projectQueuesProvider(widget.slug));
    final isPhone = SLBreakpoint.of(context).isPhone;

    return SLShortcuts(
      // `n` — создать очередь (админ). Хоткей живёт на вкладке, а не глобально:
      // на других вкладках создавать нечего.
      //
      // `SLShortcuts` не отбирает клавишу у поля ввода: модалка создания
      // открывается над вкладкой, и «н» в её поле должна набираться.
      bindings: {const SingleActivator(LogicalKeyboardKey.keyN): _create},
      child: Focus(
        autofocus: false,
        child: queues.when(
          loading: () => _Skeleton(compact: isPhone),
          error: (error, _) => SLErrorState(
            title: 'Не удалось загрузить очереди',
            description: 'Проверьте соединение и попробуйте ещё раз.',
            onAction: () =>
                ref.read(projectQueuesProvider(widget.slug).notifier).refresh(),
            details: ApiFailure.of(error).toString(),
          ),
          data: (items) => _buildContent(items, isPhone: isPhone),
        ),
      ),
    );
  }

  Widget _buildContent(List<QueueDto> queues, {required bool isPhone}) {
    if (queues.isEmpty) {
      return SLEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Очередей пока нет',
        description: widget.canManage
            ? 'Очередь — это поток задач. Ключ очереди станет началом '
                  'ключей её задач: DEV-1, DEV-2.'
            : 'Попросите администратора проекта создать очередь.',
        actionLabel: widget.canManage ? 'Создать очередь' : null,
        onAction: widget.canManage ? _create : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildList(queues, isPhone: isPhone)),
        if (widget.canManage) ...[
          const SizedBox(height: SLSpacing.space4),
          Align(
            alignment: isPhone ? Alignment.center : Alignment.centerRight,
            child: CreateQueueButton(expand: isPhone, onPressed: _create),
          ),
        ],
      ],
    );
  }

  Widget _buildList(List<QueueDto> queues, {required bool isPhone}) {
    final extent = QueueRow.heightOf(compact: isPhone);

    Widget rowAt(int index) {
      final queue = queues[index];

      return QueueRow(
        key: ValueKey(queue.key),
        queue: queue,
        compact: isPhone,
        onOpen: () => _open(queue.key),
        onOpenInNewTab: () => _openInNewTab(queue.key),
        onRename: widget.canManage ? () => _rename(queue) : null,
        onDelete: widget.canManage ? () => _delete(queue) : null,
      );
    }

    if (queues.length >= ProjectQueuesTab.virtualizationThreshold) {
      return ListView.builder(
        itemExtent: extent,
        itemCount: queues.length,
        itemBuilder: (context, index) => rowAt(index),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < queues.length; i++) rowAt(i)],
      ),
    );
  }
}

/// Загрузка: пять строк-скелетонов в геометрии реальных.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = QueueRow.heightOf(compact: compact);

    return SLShimmeringEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < ProjectQueuesTab.skeletonRows; index++)
            SizedBox(
              height: height,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: SLSpacing.space3),
                child: Row(
                  children: [
                    SizedBox(
                      width: QueueRow.keyColumnWidth,
                      child: SLSkeletonLine(width: 40),
                    ),
                    SizedBox(width: SLSpacing.space3),
                    Expanded(child: SLSkeletonLine(width: 180)),
                    SizedBox(width: SLSpacing.space3),
                    SLSkeletonLine(width: 56),
                    SizedBox(width: QueueRow.actionsColumnWidth),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
