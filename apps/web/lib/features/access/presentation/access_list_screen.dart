import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/not_found_screen.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_providers.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/access_entry_row.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/access_source_badge.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/add_access_entry_dialog.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/revoke_access_dialog.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран списка доступа к трекеру (`docs/design/screens/access-list.md`).
///
/// Экран **об уровне 0, а не об уровне 1**: запись в списке даёт только вход
/// в трекер и никаких прав внутри проектов. Это самая частая путаница,
/// и экран снимает её текстом, а не рассчитывает на память пользователя.
///
/// Прямой переход без права — «Страница не найдена», а не «нет прав»:
/// существование раздела не подтверждается.
class AccessListScreen extends ConsumerWidget {
  /// @nodoc
  const AccessListScreen({super.key});

  /// Ширина контента.
  static const contentWidth = 880.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    // Пока непонятно, кто перед нами, ни экрана, ни «не найдено» показывать
    // нельзя: и то и другое было бы враньём.
    if (session.isResolving) {
      return const Center(child: SizedBox.shrink());
    }

    if (!session.canManageAccessList) return const NotFoundScreen();

    return const _AccessListView();
  }
}

class _AccessListView extends ConsumerStatefulWidget {
  const _AccessListView();

  @override
  ConsumerState<_AccessListView> createState() => _AccessListViewState();
}

class _AccessListViewState extends ConsumerState<_AccessListView> {
  final _headerFocusNode = FocusNode(debugLabel: 'access-list-header');

  /// Сколько пикселей до конца списка запускают догрузку.
  static const _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    // При переходе на экран фокус ставится на заголовок, чтобы скринридер
    // объявил, куда человек попал (`screens/README.md`, 6).
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
      _add();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _add() async {
    final email = await AddAccessEntryDialog.show(context);
    if (email == null || !mounted) return;

    ref.read(toastControllerProvider.notifier).success('Адрес добавлен');
  }

  Future<void> _revoke(AccessEntryDto entry) async {
    final revokedSessions = await RevokeAccessDialog.show(context, entry);
    if (revokedSessions == null || !mounted) return;

    ref
        .read(toastControllerProvider.notifier)
        .success(
          revokedSessions > 0
              ? 'Доступ отозван, сессий завершено: $revokedSessions'
              : 'Доступ отозван',
        );
  }

  Future<void> _toggleOwner(AccessEntryDto entry) async {
    try {
      await ref
          .read(accessListProvider.notifier)
          .setInstanceOwner(entry.id, value: !entry.isInstanceOwner);

      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .success(
            entry.isInstanceOwner
                ? 'Права владельца сняты'
                : 'Теперь это владелец трекера',
          );
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      ref.read(toastControllerProvider.notifier).error(switch (failure.code) {
        'last_instance_owner' =>
          'В трекере должен остаться хотя бы один владелец',
        'access_entry_not_found' => 'Записи больше нет — обновите список',
        _ => 'Не удалось изменить права',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final page = ref.watch(accessListProvider);
    final query = ref.watch(accessSearchQueryProvider);

    return Focus(
      onKeyEvent: _onKeyEvent,
      child: ColoredBox(
        color: colors.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AccessListScreen.contentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SLSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    focusNode: _headerFocusNode,
                    onAdd: _add,
                    onRefresh: () =>
                        ref.read(accessListProvider.notifier).refresh(),
                    isPhone: breakpoint.isPhone,
                  ),
                  const SizedBox(height: SLSpacing.space3),
                  // Не сворачивается и не скрывается: этот баннер и есть
                  // защита от путаницы уровней доступа.
                  const SLBanner(
                    title: 'Эти адреса могут войти в трекер',
                    description:
                        'Доступ в трекер и участие в проектах — разные вещи: '
                        'запись здесь не даёт доступа ни к одному проекту.',
                    variant: SLBannerVariant.info,
                  ),
                  const SizedBox(height: SLSpacing.space3),
                  if (!breakpoint.isPhone)
                    _ColumnHeaders(dense: breakpoint.isTablet),
                  Expanded(
                    child: page.when(
                      loading: () => _Skeleton(isPhone: breakpoint.isPhone),
                      error: (error, _) => _buildError(error),
                      data: (data) => _buildList(data, query, breakpoint),
                    ),
                  ),
                  if (page.hasValue) _Footer(total: page.requireValue.total),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    // Право отобрали, пока экран был открыт: существование раздела
    // не подтверждаем, а о причине говорим тостом.
    if (failure.kind == ApiFailureKind.forbidden) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(toastControllerProvider.notifier)
            .show('Раздел больше не доступен');
      });

      return const NotFoundScreen();
    }

    return SLErrorState(
      title: 'Не удалось загрузить список доступа',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: () => ref.read(accessListProvider.notifier).refresh(),
      details: failure.toString(),
    );
  }

  Widget _buildList(
    AccessListPage data,
    String query,
    SLBreakpoint breakpoint,
  ) {
    if (data.items.isEmpty) {
      return query.isEmpty
          ? SLEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'В списке доступа никого нет',
              description: 'Добавьте адрес, чтобы человек мог войти.',
              actionLabel: 'Добавить адрес',
              onAction: _add,
            )
          : SLEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Ничего не нашлось',
              description:
                  'Проверьте написание адреса или очистите поиск, '
                  'чтобы увидеть весь список.',
              actionLabel: 'Очистить поиск',
              onAction: () =>
                  ref.read(accessSearchQueryProvider.notifier).update(''),
            );
    }

    final isPhone = breakpoint.isPhone;
    final itemCount = data.items.length + (data.hasMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadMoreThreshold) {
          // Ошибка догрузки не рушит уже показанный список: контроллер
          // возвращает его как был, а сообщение приходит тостом.
          ref.read(accessListProvider.notifier).loadMore().onError<Object>((
            _,
            _,
          ) {
            if (!mounted) return;
            ref
                .read(toastControllerProvider.notifier)
                .error('Не удалось загрузить ещё записи');
          });
        }

        return false;
      },
      child: ListView.builder(
        // Виртуализация обязательна: список административный, но расти ему
        // никто не запрещал.
        itemExtent: isPhone
            ? AccessEntryRow.compactHeight
            : AccessEntryRow.height,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= data.items.length) return const _LoadMoreRow();

          final entry = data.items[index];

          return AccessEntryRow(
            key: ValueKey(entry.id),
            entry: entry,
            highlighted: data.highlightedId == entry.id,
            compact: isPhone,
            dense: breakpoint.isTablet,
            // Пункта «Удалить» у собственной записи нет вовсе: сервер откажет
            // (`cannot_revoke_self`), а показывать действие, которое заведомо
            // не выполнится, — обманывать.
            onRevoke: entry.isSelf ? null : () => _revoke(entry),
            onToggleOwner: () => _toggleOwner(entry),
          );
        },
      ),
    );
  }
}

/// Шапка экрана: заголовок, поиск, обновление, добавление.
class _Header extends ConsumerWidget {
  const _Header({
    required this.focusNode,
    required this.onAdd,
    required this.onRefresh,
    required this.isPhone,
  });

  final FocusNode focusNode;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;
  final bool isPhone;

  /// Ширина поля поиска на десктопе.
  static const searchWidth = 240.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final title = Focus(
      focusNode: focusNode,
      child: Semantics(
        header: true,
        child: Text(
          'Доступ к трекеру',
          style: text.h2.copyWith(color: colors.textPrimary),
        ),
      ),
    );

    final search = SLSearchField(
      hint: 'Поиск по адресу и имени',
      showHotkeyHint: false,
      onQueryChanged: (query) =>
          ref.read(accessSearchQueryProvider.notifier).update(query),
    );

    final refresh = SLIconButton(
      icon: Icons.refresh_rounded,
      tooltip: 'Обновить список',
      onPressed: onRefresh,
    );

    final add = SLButton(
      label: 'Добавить адрес',
      icon: Icons.person_add_alt_1_rounded,
      expand: isPhone,
      onPressed: onAdd,
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: title),
              refresh,
            ],
          ),
          const SizedBox(height: SLSpacing.space2),
          search,
          const SizedBox(height: SLSpacing.space2),
          add,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        SizedBox(width: searchWidth, child: search),
        const SizedBox(width: SLSpacing.space2),
        refresh,
        const SizedBox(width: SLSpacing.space2),
        add,
      ],
    );
  }
}

/// Заголовки колонок.
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final style = text.overline.copyWith(color: colors.textMuted);

    return Container(
      height: SLDensity.ofContext(context).tableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
      color: colors.surfaceSunken,
      child: Row(
        children: [
          Expanded(child: Text('АДРЕС', style: style)),
          const SizedBox(width: SLSpacing.space3),
          SizedBox(
            width: AccessSourceBadge.columnWidth,
            child: Text('ИСТОЧНИК', style: style),
          ),
          SizedBox(
            width: dense
                ? AccessEntryRow.denseDateColumnWidth
                : AccessEntryRow.dateColumnWidth,
            child: Text('ДОБАВЛЕН', style: style),
          ),
          const SizedBox(width: AccessEntryRow.actionsColumnWidth),
        ],
      ),
    );
  }
}

/// Счётчик под списком.
class _Footer extends StatelessWidget {
  const _Footer({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      height: SLDensity.ofContext(context).tableHeaderHeight,
      alignment: Alignment.centerRight,
      child: Text(
        'Всего: $total',
        style: text.label.copyWith(color: colors.textMuted),
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

/// Скелетон списка: шесть строк по геометрии реальных.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isPhone});

  final bool isPhone;

  /// Сколько строк-скелетонов показывать.
  static const rowCount = 6;

  @override
  Widget build(BuildContext context) {
    return SLShimmeringEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rowCount; index++)
            SizedBox(
              height: isPhone
                  ? AccessEntryRow.compactHeight
                  : AccessEntryRow.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space3,
                ),
                child: Row(
                  children: [
                    const Expanded(child: SLSkeletonLine(width: 220)),
                    const SizedBox(width: SLSpacing.space3),
                    const SizedBox(
                      width: AccessSourceBadge.columnWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SLSkeletonBox(width: 100, height: 20),
                      ),
                    ),
                    SizedBox(
                      width: AccessEntryRow.dateColumnWidth,
                      child: const SLSkeletonLine(width: 60),
                    ),
                    const SizedBox(width: AccessEntryRow.actionsColumnWidth),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
