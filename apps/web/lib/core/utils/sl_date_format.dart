/// Форматирование дат для интерфейса.
///
/// Без `intl`: пакет тянет полтора мегабайта данных локалей ради трёх строк,
/// а в вебе размер бандла — первое, что чувствует пользователь. Локаль
/// в MVP одна — русская.
sealed class SLDateFormat {
  static const _shortMonths = <String>[
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  static const _genitiveMonths = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  /// «12 фев», а для прошлых лет — «12 фев 2025».
  ///
  /// Год показывается только тогда, когда он отличается от текущего:
  /// в списке из десятков строк повторять «2026» бессмысленно.
  static String short(DateTime date, {DateTime? now}) {
    final local = date.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final month = _shortMonths[local.month - 1];

    return local.year == today.year
        ? '${local.day} $month'
        : '${local.day} $month ${local.year}';
  }

  /// «14:32» сегодня, «вчера» вчера, дальше — «12 фев».
  ///
  /// Лента уведомлений читается сверху вниз и в основном за сегодня: точное
  /// время у свежего события полезнее даты, а у позавчерашнего — наоборот
  /// (`docs/design/screens/notifications.md`).
  static String timeOrDay(DateTime date, {DateTime? now}) {
    final local = date.toLocal();
    final today = (now ?? DateTime.now()).toLocal();
    final startOfToday = DateTime(today.year, today.month, today.day);

    if (!local.isBefore(startOfToday)) {
      return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
    }
    if (!local.isBefore(startOfToday.subtract(const Duration(days: 1)))) {
      return 'вчера';
    }

    return short(local, now: today);
  }

  /// «12.02» — компактный вид для узкой колонки.
  static String numeric(DateTime date) {
    final local = date.toLocal();

    return '${_twoDigits(local.day)}.${_twoDigits(local.month)}';
  }

  /// «12 февраля 2026, 14:30» — точное время для тултипа.
  static String exact(DateTime date) => '${long(date)}, ${clock(date)}';

  /// «12 февраля 2026» — дата словами, без времени.
  ///
  /// Нужна там, где дата стоит внутри фразы: «Токен перестанет работать
  /// 24 сентября 2027 года» (`screens/tokens.md`). Год показывается всегда:
  /// такие фразы читают вне контекста списка.
  static String long(DateTime date) {
    final local = date.toLocal();

    return '${local.day} ${_genitiveMonths[local.month - 1]} ${local.year}';
  }

  /// «14:32» — время суток.
  static String clock(DateTime date) {
    final local = date.toLocal();

    return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
