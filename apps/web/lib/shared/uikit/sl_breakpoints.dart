import 'package:flutter/widgets.dart';

/// Брейкпоинты приложения (`docs/design/screens/README.md`, 2).
///
/// Ниже 360 px интерфейс не поддерживается — это зафиксировано, а не забыто.
enum SLBreakpoint {
  /// < 768. Сайдбар — выдвижная панель поверх контента, таблицы становятся
  /// списками.
  sm,

  /// 768–1023. Сайдбар свёрнут до 48, часть колонок таблицы скрыта.
  md,

  /// 1024–1439. Базовая десктопная раскладка, сайдбар 240 развёрнут.
  lg,

  /// >= 1440. Всё видно; контент центрируется, максимальная ширина рабочей
  /// области 1600.
  xl;

  /// Граница между [sm] и [md].
  static const mdMinWidth = 768.0;

  /// Граница между [md] и [lg].
  static const lgMinWidth = 1024.0;

  /// Граница между [lg] и [xl].
  static const xlMinWidth = 1440.0;

  /// Брейкпоинт по ширине окна.
  static SLBreakpoint ofWidth(double width) {
    if (width >= xlMinWidth) return SLBreakpoint.xl;
    if (width >= lgMinWidth) return SLBreakpoint.lg;
    if (width >= mdMinWidth) return SLBreakpoint.md;

    return SLBreakpoint.sm;
  }

  /// Брейкпоинт текущего окна.
  ///
  /// Подписка узкая: перестраивается только при смене размера окна.
  static SLBreakpoint of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  /// Телефон: сайдбара на экране нет, таблицы становятся списками.
  bool get isPhone => this == SLBreakpoint.sm;

  /// Планшет: сайдбар принудительно свёрнут.
  bool get isTablet => this == SLBreakpoint.md;

  /// Десктоп: сайдбар разворачивается по выбору пользователя.
  bool get isDesktop => this == SLBreakpoint.lg || this == SLBreakpoint.xl;
}

/// Плотность интерфейса — высоты элементов по брейкпоинтам
/// (`docs/design/system.md`, 10.2).
///
/// Одного `VisualDensity` не хватает: высоты задаются явно, иначе дефолты
/// Material 3 (кнопка 40, поле 56) сделают трекер вдвое просторнее, чем нужно.
class SLDensity {
  const SLDensity._({
    required this.appBarHeight,
    required this.toolbarHeight,
    required this.tableHeaderHeight,
    required this.issueRowHeight,
    required this.sidebarItemHeight,
    required this.tabHeight,
    required this.buttonSm,
    required this.buttonMd,
    required this.buttonLg,
    required this.fieldMd,
    required this.fieldLg,
    required this.statusChipRow,
    required this.statusChipCard,
  });

  /// Плотность для десктопа (>= 1024).
  static const desktop = SLDensity._(
    appBarHeight: 48,
    toolbarHeight: 44,
    tableHeaderHeight: 32,
    issueRowHeight: 36,
    sidebarItemHeight: 32,
    tabHeight: 40,
    buttonSm: 24,
    buttonMd: 32,
    buttonLg: 40,
    fieldMd: 32,
    fieldLg: 40,
    statusChipRow: 20,
    statusChipCard: 24,
  );

  /// Плотность для планшета (768–1023). От десктопной отличается только
  /// высотой строки списка.
  static const tablet = SLDensity._(
    appBarHeight: 48,
    toolbarHeight: 44,
    tableHeaderHeight: 32,
    issueRowHeight: 40,
    sidebarItemHeight: 32,
    tabHeight: 40,
    buttonSm: 24,
    buttonMd: 32,
    buttonLg: 40,
    fieldMd: 32,
    fieldLg: 40,
    statusChipRow: 20,
    statusChipCard: 24,
  );

  /// Плотность для телефона (< 768). Заголовок таблицы скрыт, поэтому
  /// [tableHeaderHeight] равен нулю.
  static const phone = SLDensity._(
    appBarHeight: 52,
    toolbarHeight: 48,
    tableHeaderHeight: 0,
    issueRowHeight: 56,
    sidebarItemHeight: 44,
    tabHeight: 44,
    buttonSm: 32,
    buttonMd: 40,
    buttonLg: 44,
    fieldMd: 40,
    fieldLg: 44,
    statusChipRow: 24,
    statusChipCard: 24,
  );

  /// Шапка приложения.
  final double appBarHeight;

  /// Панель фильтров и тулбар.
  final double toolbarHeight;

  /// Заголовок таблицы. Ноль означает «скрыт».
  final double tableHeaderHeight;

  /// Строка списка задач. Это `itemExtent` виртуализированного списка.
  final double issueRowHeight;

  /// Элемент сайдбара.
  final double sidebarItemHeight;

  /// Вкладка.
  final double tabHeight;

  /// Кнопка `sm`.
  final double buttonSm;

  /// Кнопка `md`, по умолчанию.
  final double buttonMd;

  /// Кнопка `lg`.
  final double buttonLg;

  /// Поле ввода `md`.
  final double fieldMd;

  /// Поле ввода `lg`.
  final double fieldLg;

  /// Плашка статуса в строке списка.
  final double statusChipRow;

  /// Плашка статуса в карточке задачи.
  final double statusChipCard;

  /// Плотность для брейкпоинта.
  static SLDensity of(SLBreakpoint breakpoint) => switch (breakpoint) {
    SLBreakpoint.sm => phone,
    SLBreakpoint.md => tablet,
    SLBreakpoint.lg || SLBreakpoint.xl => desktop,
  };

  /// Плотность текущего окна.
  static SLDensity ofContext(BuildContext context) =>
      of(SLBreakpoint.of(context));
}
