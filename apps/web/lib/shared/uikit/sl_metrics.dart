import 'package:flutter/widgets.dart';

/// Шкала отступов на базе 4 (`docs/design/system.md`, 10.1).
///
/// Произвольные значения запрещены. Два зафиксированных исключения вшиты
/// внутрь компонентов и наружу не торчат: 2 px — вертикальный padding плашки
/// статуса, 6 px — горизонтальный padding бейджа роли.
sealed class SLSpacing {
  /// 4. Зазор иконка—текст, внутренние зазоры плашки.
  static const space1 = 4.0;

  /// 8. Горизонтальный padding в строке, зазор между чипами.
  static const space2 = 8.0;

  /// 12. Padding кнопки, зазор между полями формы.
  static const space3 = 12.0;

  /// 16. Padding панели и карточки, поля модалки.
  static const space4 = 16.0;

  /// 24. Отступ между блоками секции.
  static const space6 = 24.0;

  /// 32. Отступ между крупными секциями, padding пустого состояния.
  static const space8 = 32.0;
}

/// Радиусы (`docs/design/system.md`, 10.5).
sealed class SLRadii {
  /// 4. Кнопки, поля ввода, бейджи, чекбоксы, блоки кода.
  static const sm = 4.0;

  /// 8. Карточки, меню, поповеры, модалки, тосты, плитки вложений.
  static const md = 8.0;

  /// 999. Аватары, плашки статусов, счётчики-пилюли.
  static const full = 999.0;

  /// [BorderRadius] для [sm].
  static const smAll = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] для [md].
  static const mdAll = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] для [full].
  static const fullAll = BorderRadius.all(Radius.circular(full));
}

/// Размеры иконок (`docs/design/system.md`, 10.4).
///
/// Набор — встроенные Material Icons, вариант Rounded. Внешние пакеты иконок
/// не подключаются: встроенного набора хватает, а лишний шрифт — это лишние
/// килобайты в вебе.
sealed class SLIconSizes {
  /// 12. Внутри плашки статуса.
  static const icon12 = 12.0;

  /// 16. По умолчанию: строки, меню, поля, кнопки `sm` и `md`.
  static const icon16 = 16.0;

  /// 20. Шапка, кнопки `lg`, вкладки.
  static const icon20 = 20.0;

  /// 24. Иконка тоста, крупные акценты.
  static const icon24 = 24.0;

  /// 48. Пустые состояния и состояния ошибки.
  static const icon48 = 48.0;
}

/// Толщины границ (`docs/design/system.md`, 10.6).
sealed class SLBorders {
  /// 1 px — любая граница, кроме кольца фокуса и полосы выделения.
  static const hairline = 1.0;

  /// 2 px — кольцо фокуса, снаружи элемента с зазором 1 px.
  static const focusRing = 2.0;

  /// Зазор между элементом и кольцом фокуса.
  static const focusRingGap = 1.0;

  /// 2 px — `borderFocusThick`: собственная рамка элемента в фокусе
  /// (`system.md`, 10.6.1).
  ///
  /// Применяется там, где рамка сама окрашивается в `borderFocus` — поле
  /// ввода, поиск, селект. Кольцо к такой рамке **не добавляется**: в
  /// `borderFocus` должен быть ровно один контур. Рисуется вместо
  /// собственной рамки, габариты и внутренние отступы при этом не меняются.
  static const controlFocus = 2.0;

  /// 2 px — вертикальная полоса слева у активного пункта сайдбара.
  static const selectionBar = 2.0;
}

/// Фиксированные ширины (`docs/design/system.md`, 10.3).
sealed class SLSizes {
  /// Сайдбар проектов и очередей, развёрнутый.
  static const sidebarWidth = 240.0;

  /// Сайдбар, свёрнутый до иконок.
  static const sidebarCollapsedWidth = 48.0;

  /// Выдвижной сайдбар на телефоне.
  static const sidebarDrawerWidth = 280.0;

  /// Правая панель задачи.
  static const issuePanelWidth = 320.0;

  /// Модалка `sm`.
  static const dialogSm = 400.0;

  /// Модалка `md`.
  static const dialogMd = 560.0;

  /// Модалка `lg`.
  static const dialogLg = 800.0;

  /// Колонка ключа задачи. Вмещает четырёхбуквенный префикс и пятизначный
  /// номер, поэтому ключ никогда не переносится и не усекается.
  static const issueKeyColumn = 88.0;

  /// Колонка статуса.
  static const statusColumn = 132.0;

  /// Колонка исполнителя (аватар и имя).
  static const assigneeColumn = 160.0;

  /// Колонка приоритета.
  static const priorityColumn = 44.0;

  /// Колонка сложности.
  static const complexityColumn = 32.0;

  /// Колонка даты.
  static const dateColumn = 96.0;

  /// Максимальная ширина читаемого текста: описание, комментарий.
  static const readableTextWidth = 720.0;

  /// Максимальная ширина рабочей области на `xl`.
  static const workAreaMaxWidth = 1600.0;

  /// Минимальная поддерживаемая ширина окна.
  static const minSupportedWidth = 360.0;

  /// Зона нажатия на тач-устройствах. Достигается расширением области,
  /// а не увеличением визуального размера.
  static const touchTarget = 44.0;
}
