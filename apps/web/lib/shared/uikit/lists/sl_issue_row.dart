import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_complexity_indicator.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_priority_indicator.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Набор видимых колонок строки списка задач
/// (`screens/queue-issues.md`, «Колонки по ширине содержимого»).
///
/// Порядок отбрасывания продуман: первой уходит сложность (заполнена
/// не у всех), затем имя исполнителя — но **аватар остаётся**, потому что
/// «кто делает» считывается по нему без имени. Ключ, название, статус
/// и приоритет не отбрасываются никогда: без них список перестаёт быть
/// списком задач.
enum SLIssueColumnSet {
  /// Все колонки экрана.
  full,

  /// Без сложности.
  withoutComplexity,

  /// Без сложности, исполнитель — один аватар без имени.
  assigneeAvatarOnly,

  /// Карточка в две строки: колонок нет вовсе.
  card;

  /// Показывать ли колонку сложности.
  bool get hasComplexity => this == SLIssueColumnSet.full;

  /// Показывать ли имя исполнителя рядом с аватаром.
  bool get hasAssigneeName =>
      this == SLIssueColumnSet.full ||
      this == SLIssueColumnSet.withoutComplexity;
}

/// Раскладка строки списка задач: плотность и набор колонок.
///
/// Две независимые величины, и путать их нельзя. **Высота** строки зависит
/// от брейкпоинта окна — это плотность интерфейса. **Набор колонок** зависит
/// от ширины области содержимого, а не окна: она учитывает и ширину сайдбара,
/// и его свёрнутость. Прежняя привязка колонок к брейкпоинту давала при окне
/// 1024 колонку названия в 84 px — двенадцать символов.
///
/// Раскладка приходит сверху, а не вычисляется в строке: `LayoutBuilder`
/// внутри строки убивает виртуализацию, ради которой всё и затевалось
/// (`components.md`, 10.6).
@immutable
class SLIssueRowLayout {
  const SLIssueRowLayout._({required this.density, required this.columns});

  /// Плотность: от неё высота строки и высота ряда заголовков.
  final SLDensity density;

  /// Набор видимых колонок.
  final SLIssueColumnSet columns;

  /// Десктопная раскладка со всеми колонками. Значение по умолчанию.
  static const desktop = SLIssueRowLayout._(
    density: SLDensity.desktop,
    columns: SLIssueColumnSet.full,
  );

  /// Карточная раскладка телефона.
  static const phone = SLIssueRowLayout._(
    density: SLDensity.phone,
    columns: SLIssueColumnSet.card,
  );

  /// Ширина всего, кроме названия: колонки, зазоры между ними и поля
  /// страницы с двух сторон.
  ///
  /// Считается по тем же константам, из которых строится сама строка,
  /// поэтому не может разойтись с ней.
  static double fixedWidth(SLIssueColumnSet columns) {
    // Колонка чекбокса зарезервирована и пуста, но место занимает всегда.
    var width =
        SLIssueRow.horizontalPadding * 2 +
        SLIssueRow.checkboxColumn +
        SLSizes.issueKeyColumn +
        SLSizes.statusColumn +
        SLSizes.priorityColumn +
        (columns.hasAssigneeName
            ? SLSizes.assigneeColumn
            : SLIssueRow.assigneeAvatarColumn);
    var gaps = 4;

    if (columns.hasComplexity) {
      width += SLSizes.complexityColumn;
      gaps += 1;
    }

    return width + gaps * SLIssueRow.columnGap;
  }

  /// Минимальная ширина содержимого для набора колонок: столько нужно,
  /// чтобы названию осталось не меньше [SLSizes.issueTitleMinWidth].
  static double minContentWidth(SLIssueColumnSet columns) =>
      fixedWidth(columns) + SLSizes.issueTitleMinWidth;

  /// Раскладка по брейкпоинту окна и ширине области содержимого.
  ///
  /// На телефоне колонок нет независимо от ширины: там карточка в две
  /// строки, и семь колонок в 360 px не поместятся при любой арифметике.
  static SLIssueRowLayout resolve({
    required SLBreakpoint breakpoint,
    required double contentWidth,
  }) {
    if (breakpoint.isPhone) return phone;

    final columns = switch (contentWidth) {
      final width when width >= minContentWidth(SLIssueColumnSet.full) =>
        SLIssueColumnSet.full,
      final width
          when width >= minContentWidth(SLIssueColumnSet.withoutComplexity) =>
        SLIssueColumnSet.withoutComplexity,
      final width
          when width >=
              minContentWidth(SLIssueColumnSet.assigneeAvatarOnly) =>
        SLIssueColumnSet.assigneeAvatarOnly,
      _ => SLIssueColumnSet.card,
    };

    // Колонки кончились раньше, чем брейкпоинт: содержимое сузили сильнее,
    // чем окно. Карточка — это карточка, у неё своя высота.
    if (columns == SLIssueColumnSet.card) return phone;

    return SLIssueRowLayout._(
      density: SLDensity.of(breakpoint),
      columns: columns,
    );
  }

  /// Высота строки. Она же `itemExtent` виртуализированного списка:
  /// без фиксированного экстента прокрутка на тысяче задач деградирует.
  double get extent => density.issueRowHeight;

  /// Высота ряда заголовков колонок. Ноль означает «заголовков нет».
  double get headerHeight => density.tableHeaderHeight;

  /// Карточная раскладка: две строки вместо колонок.
  bool get isCard => columns == SLIssueColumnSet.card;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SLIssueRowLayout &&
          identical(other.density, density) &&
          other.columns == columns;

  @override
  int get hashCode => Object.hash(identityHashCode(density), columns);

  @override
  String toString() => 'SLIssueRowLayout(${columns.name})';
}

/// Строка списка задач (`docs/design/components.md`, 10).
///
/// Ключевой компонент продукта: от него зависит и плотность, и скорость
/// прокрутки. Отсюда ограничения, которые выглядят придирками, но ими
/// не являются (`components.md`, 10.6):
///
/// * внутри — только `Row`, `SizedBox` фиксированной ширины и один `Expanded`;
///   никаких `IntrinsicWidth`, `IntrinsicHeight` и вложенных `LayoutBuilder`;
/// * разделитель рисуется границей самой строки, а не отдельным виджетом;
/// * состояние наведения хранится в родителе, поэтому строка остаётся
///   `const`-конструируемым [StatelessWidget];
/// * тултип на длинную тему создаётся только у наведённой строки — в дереве
///   он всегда один, а не тысяча.
class SLIssueRow extends StatelessWidget {
  /// @nodoc
  const SLIssueRow({
    required this.issueKey,
    required this.title,
    required this.status,
    required this.priority,
    required this.onTap,
    this.storyPoints,
    this.assignee,
    this.layout = SLIssueRowLayout.desktop,
    this.hovered = false,
    this.focused = false,
    this.onHover,
    this.onOpenInNewTab,
    this.onStatusPressed,
    this.onSecondaryTap,
    this.isStatusMenuOpen = false,
    super.key,
  });

  /// Ключ задачи вида `DEV-42`.
  final String issueKey;

  /// Тема задачи. Пустая заменяется на «Без названия» — сервер такого
  /// вернуть не должен, но экран из-за этого не ломается.
  final String title;

  /// Статус: палитра, название и категория.
  final IssueStatusRef status;

  /// Приоритет 0–100.
  final int priority;

  /// Сложность в story points. `null` — прочерк в тех же габаритах.
  final int? storyPoints;

  /// Исполнитель. `null` — «Не назначен».
  final SLAvatarData? assignee;

  /// Набор колонок.
  final SLIssueRowLayout layout;

  /// Наведена ли мышь. Состояние хранит родитель.
  final bool hovered;

  /// Стоит ли на строке клавиатурный курсор: тот же фон плюс полоса `accent`
  /// слева. Полоса — единственное, что отличает курсор от наведения, и это
  /// намеренно (`components.md`, 10.2).
  final bool focused;

  /// Мышь вошла в строку или вышла из неё.
  final ValueChanged<bool>? onHover;

  /// Открыть задачу.
  final VoidCallback onTap;

  /// `Ctrl/Cmd + клик` и средний клик.
  final VoidCallback? onOpenInNewTab;

  /// Открыть меню смены статуса. `null` — у пользователя нет прав, плашка
  /// показывается как текст (US-32, состояние «читатель»).
  final VoidCallback? onStatusPressed;

  /// Правый клик: контекстное меню строки.
  final ValueChanged<Offset>? onSecondaryTap;

  /// Открыто ли меню статуса этой строки: шеврон повёрнут.
  final bool isStatusMenuOpen;

  /// Зарезервированная колонка чекбокса. Массовых операций в MVP нет,
  /// чекбокс не рисуется, но место занято: иначе добавление выделения
  /// в релизе 2 сдвинет всю таблицу (Q-D14).
  static const checkboxColumn = 32.0;

  /// Горизонтальный отступ строки.
  static const horizontalPadding = SLSpacing.space4;

  /// Зазор между колонками.
  static const columnGap = SLSpacing.space3;

  /// Ширина колонки исполнителя, когда имя скрыто (планшет).
  static const assigneeAvatarColumn = 32.0;

  /// Через сколько наведения показывается полная тема.
  static const tooltipDelay = Duration(milliseconds: 500);

  /// Ширина полосы клавиатурного курсора.
  static const cursorBarWidth = SLBorders.selectionBar;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    final background = focused || hovered
        ? colors.surfaceHover
        : colors.surface;

    Widget row = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: SLBorders.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding - (focused ? cursorBarWidth : 0),
          right: horizontalPadding,
        ),
        child: layout.isCard
            ? _buildPhone(context, colors)
            : _buildWide(context, colors),
      ),
    );

    if (focused) {
      row = Row(
        children: [
          Container(width: cursorBarWidth, color: colors.accent),
          Expanded(child: row),
        ],
      );
    }

    return Semantics(
      button: true,
      selected: focused,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: onHover == null ? null : (_) => onHover!(true),
          onExit: onHover == null ? null : (_) => onHover!(false),
          child: Listener(
            onPointerDown: _onPointerDown,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTap,
              onSecondaryTapDown: onSecondaryTap == null
                  ? null
                  : (details) => onSecondaryTap!(details.globalPosition),
              child: row,
            ),
          ),
        ),
      ),
    );
  }

  /// Доступное имя строки: все колонки в фиксированном порядке.
  ///
  /// Порядок задан спекой доступности экрана и не зависит от того, какие
  /// колонки скрыты на планшете: скринридеру видимость колонки безразлична,
  /// а вот пропавшее посреди списка поле сбивает.
  String get semanticsLabel {
    final buffer = StringBuffer()
      ..write(issueKey)
      ..write(', ')
      ..write(title.trim().isEmpty ? 'Без названия' : title)
      ..write(', статус: ')
      ..write(status.name)
      ..write(', исполнитель: ')
      ..write(assignee?.fullName ?? 'не назначен')
      ..write(', приоритет $priority из ${IssuePriority.max}, ')
      ..write(PriorityRange.of(priority).label.toLowerCase());

    if (storyPoints != null) {
      buffer.write(', сложность $storyPoints story points');
    } else {
      buffer.write(', сложность не задана');
    }

    return buffer.toString();
  }

  bool get _isModifierPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _onTap() {
    if (_isModifierPressed && onOpenInNewTab != null) {
      onOpenInNewTab!();

      return;
    }

    onTap();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) onOpenInNewTab?.call();
  }

  /// Десктоп и планшет: одна строка колонок.
  Widget _buildWide(BuildContext context, SLColorScheme colors) {
    final columns = layout.columns;
    final showName = columns.hasAssigneeName;

    return Row(
      children: [
        const SizedBox(width: checkboxColumn),
        SizedBox(width: SLSizes.issueKeyColumn, child: _buildKey(context)),
        const SizedBox(width: columnGap),
        Expanded(child: _buildTitle(context)),
        const SizedBox(width: columnGap),
        // Колонка статуса задана минимумом, а не жёсткой шириной: текст
        // статуса не обрезается никогда, и если он длиннее колонки, сжимается
        // тема, а не он (`components.md`, 7).
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: SLSizes.statusColumn),
          child: Align(alignment: Alignment.centerLeft, child: _buildStatus()),
        ),
        const SizedBox(width: columnGap),
        SizedBox(
          width: showName ? SLSizes.assigneeColumn : assigneeAvatarColumn,
          child: _buildAssignee(context, showName: showName),
        ),
        const SizedBox(width: columnGap),
        SizedBox(
          width: SLSizes.priorityColumn,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SLPriorityIndicator(value: priority),
          ),
        ),
        if (columns.hasComplexity) ...[
          const SizedBox(width: columnGap),
          SizedBox(
            width: SLSizes.complexityColumn,
            child: Align(
              alignment: Alignment.centerRight,
              child: SLComplexityIndicator(value: storyPoints),
            ),
          ),
        ],
      ],
    );
  }

  /// Телефон: две строки, зона нажатия — вся строка 56 px.
  Widget _buildPhone(BuildContext context, SLColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildKey(context),
            const SizedBox(width: SLSpacing.space2),
            Expanded(child: _buildTitle(context)),
          ],
        ),
        const SizedBox(height: SLSpacing.space1),
        Row(
          children: [
            _buildStatus(),
            const SizedBox(width: SLSpacing.space2),
            if (assignee != null)
              SLAvatar(
                userId: assignee!.userId,
                fullName: assignee!.fullName,
                photoUrl: assignee!.photoUrl,
                size: SLAvatarSize.xs,
                decorative: true,
              ),
            const Spacer(),
            SLPriorityIndicator(value: priority),
            const SizedBox(width: SLSpacing.space2),
            SLComplexityIndicator(value: storyPoints),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Text(
      issueKey,
      maxLines: 1,
      // Ключ не обрезается никогда: он и есть адрес задачи.
      softWrap: false,
      style: text.bodySStrong.copyWith(
        color: status.isDone ? colors.textMuted : colors.accent,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final isEmpty = title.trim().isEmpty;

    final label = Text(
      isEmpty ? 'Без названия' : title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodyS.copyWith(
        color: isEmpty || status.isDone ? colors.textMuted : colors.textPrimary,
        fontStyle: isEmpty ? FontStyle.italic : null,
      ),
    );

    // Тултип живёт только у наведённой строки: в дереве он всегда один
    // (`components.md`, 10.6). `Tooltip` на каждой строке списка на тысячу
    // задач — это тысяча таймеров и подписок на указатель.
    if (!hovered || isEmpty) return label;

    return Tooltip(
      message: title,
      waitDuration: tooltipDelay,
      excludeFromSemantics: true,
      child: label,
    );
  }

  Widget _buildStatus() => SLStatusChip(
    status: status.palette,
    label: status.name,
    onPressed: onStatusPressed,
    isMenuOpen: isStatusMenuOpen,
  );

  Widget _buildAssignee(BuildContext context, {required bool showName}) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final user = assignee;

    if (user == null) {
      if (!showName) return const SizedBox.shrink();

      return Text(
        'Не назначен',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyS.copyWith(color: colors.textMuted),
      );
    }

    final avatar = SLAvatar(
      userId: user.userId,
      fullName: user.fullName,
      photoUrl: user.photoUrl,
      size: SLAvatarSize.xs,
      decorative: true,
    );

    if (!showName) {
      return Align(alignment: Alignment.centerLeft, child: avatar);
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: SLSpacing.space2),
        Expanded(
          child: Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyS.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Заголовки колонок таблицы задач.
///
/// Кликом по заголовку сортировка не меняется: вариантов всего два, и они
/// живут в явном выпадающем списке. Заголовок, который выглядит кликабельным,
/// но не сортирует, хуже очевидно статичного (`screens/queue-issues.md`).
class SLIssueTableHeader extends StatelessWidget {
  /// @nodoc
  const SLIssueTableHeader({this.layout = SLIssueRowLayout.desktop, super.key});

  /// @nodoc
  final SLIssueRowLayout layout;

  /// Высота ряда заголовков. На телефоне заголовков нет вовсе.
  double get height => layout.headerHeight;

  @override
  Widget build(BuildContext context) {
    if (layout.isCard) return const SizedBox.shrink();

    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final style = text.overline.copyWith(color: colors.textMuted);
    final columns = layout.columns;
    final showName = columns.hasAssigneeName;

    Widget cell(String label, {TextAlign align = TextAlign.left}) => Text(
      label,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: style,
    );

    return Semantics(
      header: true,
      // Заголовки не входят в порядок фокуса и не читаются построчно:
      // содержимое строки объявляется её собственным доступным именем.
      child: ExcludeSemantics(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            border: Border(
              bottom: BorderSide(
                color: colors.border,
                width: SLBorders.hairline,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SLIssueRow.horizontalPadding,
          ),
          child: Row(
            children: [
              const SizedBox(width: SLIssueRow.checkboxColumn),
              SizedBox(width: SLSizes.issueKeyColumn, child: cell('КЛЮЧ')),
              const SizedBox(width: SLIssueRow.columnGap),
              Expanded(child: cell('НАЗВАНИЕ')),
              const SizedBox(width: SLIssueRow.columnGap),
              SizedBox(width: SLSizes.statusColumn, child: cell('СТАТУС')),
              const SizedBox(width: SLIssueRow.columnGap),
              SizedBox(
                width: showName
                    ? SLSizes.assigneeColumn
                    : SLIssueRow.assigneeAvatarColumn,
                child: cell(showName ? 'ИСПОЛНИТЕЛЬ' : ''),
              ),
              const SizedBox(width: SLIssueRow.columnGap),
              SizedBox(width: SLSizes.priorityColumn, child: cell('П')),
              if (columns.hasComplexity) ...[
                const SizedBox(width: SLIssueRow.columnGap),
                SizedBox(
                  width: SLSizes.complexityColumn,
                  child: cell('С', align: TextAlign.right),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Скелетон строки списка задач.
///
/// Повторяет геометрию реальной строки: те же ширины колонок, та же высота.
/// Ширина полоски темы чередуется 40 / 70 / 55 %, чтобы двенадцать строк
/// не выглядели сеткой (`screens/queue-issues.md`).
class SLIssueRowSkeleton extends StatelessWidget {
  /// @nodoc
  const SLIssueRowSkeleton({
    required this.index,
    this.layout = SLIssueRowLayout.desktop,
    super.key,
  });

  /// Номер строки: от него зависит ширина полоски темы.
  final int index;

  /// @nodoc
  final SLIssueRowLayout layout;

  /// Доли ширины колонки темы.
  static const titleFractions = <double>[0.4, 0.7, 0.55];

  @override
  Widget build(BuildContext context) {
    final columns = layout.columns;
    final showName = columns.hasAssigneeName;
    final fraction = titleFractions[index % titleFractions.length];

    // На телефоне колонок нет вовсе: строка становится карточкой в две
    // строки, и скелетон обязан повторять именно её. Ширины десктопных
    // колонок в 360 px просто не помещаются.
    if (layout.isCard) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SLIssueRow.horizontalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SLSkeletonLine(width: 56),
                const SizedBox(width: SLSpacing.space2),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: const SLSkeletonLine(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SLSpacing.space2),
            const Row(
              children: [
                SLSkeletonBox(width: 84, height: 20),
                SizedBox(width: SLSpacing.space2),
                SLSkeletonBox.circle(diameter: 20),
                Spacer(),
                SLSkeletonLine(width: 34),
                SizedBox(width: SLSpacing.space2),
                SLSkeletonBox(width: 22, height: 18),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SLIssueRow.horizontalPadding,
      ),
      child: Row(
        children: [
          const SizedBox(width: SLIssueRow.checkboxColumn),
          const SizedBox(
            width: SLSizes.issueKeyColumn,
            child: SLSkeletonLine(width: 56),
          ),
          const SizedBox(width: SLIssueRow.columnGap),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: const SLSkeletonLine(),
            ),
          ),
          const SizedBox(width: SLIssueRow.columnGap),
          const SizedBox(
            width: SLSizes.statusColumn,
            child: SLSkeletonBox(width: 84, height: 20),
          ),
          const SizedBox(width: SLIssueRow.columnGap),
          SizedBox(
            width: showName
                ? SLSizes.assigneeColumn
                : SLIssueRow.assigneeAvatarColumn,
            child: Row(
              children: [
                const SLSkeletonBox.circle(diameter: 20),
                if (showName) ...[
                  const SizedBox(width: SLSpacing.space2),
                  const Expanded(child: SLSkeletonLine()),
                ],
              ],
            ),
          ),
          const SizedBox(width: SLIssueRow.columnGap),
          const SizedBox(
            width: SLSizes.priorityColumn,
            child: SLSkeletonLine(width: 34),
          ),
          if (columns.hasComplexity) ...[
            const SizedBox(width: SLIssueRow.columnGap),
            const SizedBox(
              width: SLSizes.complexityColumn,
              child: SLSkeletonBox(width: 22, height: 18),
            ),
          ],
        ],
      ),
    );
  }
}
