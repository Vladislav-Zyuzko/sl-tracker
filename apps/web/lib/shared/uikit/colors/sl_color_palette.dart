import 'package:flutter/widgets.dart';

/// Слой 1 дизайн-системы — сырая палитра SL Tracker.
///
/// **Использовать напрямую в UI запрещено.** Виджеты декорируются только
/// ролями из [SLColorScheme] и доменными шкалами (слой 3). Правило действует
/// в том числе ради тёмной темы: там меняются значения ролей, а не виджеты
/// (`docs/design/system.md`, разделы 1 и 12).
///
/// Значения перенесены из `docs/design/system.md` (разделы 2.1 и 2.2)
/// один в один: контраст уже посчитан дизайнером, пересчитывать его здесь
/// не нужно.
sealed class SLColorPalette {
  // ---------------------------------------------------------------------------
  // Нейтральная шкала: холодный сине-серый, hue около 216°, построен
  // от indigoRainbow (#26395B). Даёт фоны, границы и три уровня текста.
  // ---------------------------------------------------------------------------

  /// Поверхность. Контраст на белом 1.00.
  static const n0 = Color(0xFFFFFFFF);

  /// Утопленный фон приложения. 1.07.
  static const n50 = Color(0xFFF4F7FB);

  /// Наведение на строку и кнопку. 1.11.
  static const n100 = Color(0xFFEFF3F8);

  /// Разделители, скелетон (= brightGrey). 1.16.
  static const n150 = Color(0xFFE8EFF5);

  /// Границы панелей и карточек. 1.27.
  static const n200 = Color(0xFFDDE5EE);

  /// Скелетон-акцент, трек ползунка. 1.52.
  static const n300 = Color(0xFFC8D3E0);

  /// Отключённый текст и иконки. 2.18.
  static const n400 = Color(0xFFA3B1C4);

  /// Границы интерактивных элементов, иконки-подсказки. 3.50.
  static const n500 = Color(0xFF7A8AA3);

  /// Третий уровень текста. 5.32.
  static const n600 = Color(0xFF5C6C87);

  /// Второй уровень текста. 7.64.
  static const n700 = Color(0xFF445470);

  /// Основной текст (= indigoRainbow). 11.55.
  static const n800 = Color(0xFF26395B);

  /// Затемнение, подложка модалок. 14.59.
  static const n900 = Color(0xFF1A2942);

  // ---------------------------------------------------------------------------
  // Хроматическая палитра.
  // ---------------------------------------------------------------------------

  /// blueCrayola. Только декоративные заливки, как текст не проходит AA.
  static const blue500 = Color(0xFF1D77FC);

  /// Акцент: кнопки, ссылки, фокус.
  static const blue600 = Color(0xFF1A6CE5);

  /// Наведение на акцент.
  static const blue700 = Color(0xFF1560D0);

  /// Нажатие, текст на синей плашке.
  static const blue800 = Color(0xFF1153B4);

  /// Выделенная строка, инфо-баннер.
  static const blue50 = Color(0xFFE7F0FE);

  /// Плашка «в работе».
  static const blue100 = Color(0xFFDDEAFD);

  /// pattensBlue. Наведение на выделенную строку.
  static const blue150 = Color(0xFFDAEDFF);

  /// paleCornflowerBlue. Граница инфо-плашки.
  static const blue200 = Color(0xFFACCCFA);

  /// limeGreen. Заливка индикаторов.
  static const green500 = Color(0xFF43C637);

  /// success: текст, иконка, заливка.
  static const green600 = Color(0xFF2B7E23);

  /// grannySmithApple. Граница success-плашки.
  static const green200 = Color(0xFFAAE38F);

  /// Плашка «закрыт».
  static const green100 = Color(0xFFE2F3DD);

  /// Фон success-плашки.
  static const green50 = Color(0xFFE9F7E5);

  /// saffron. Заливка индикаторов, полоса предупреждения.
  static const amber500 = Color(0xFFF6C23C);

  /// Заливка шкалы приоритета «высокий».
  static const amber700 = Color(0xFFC77700);

  /// warning: текст и иконка.
  static const amber800 = Color(0xFF8A5B0A);

  /// Плашка «тестирование».
  static const amber100 = Color(0xFFFBEECB);

  /// Фон warning-плашки.
  static const amber50 = Color(0xFFFDF3DC);

  /// coralRed. Заливка индикаторов.
  static const red500 = Color(0xFFFF3737);

  /// pastelRed. Граница danger-плашки.
  static const red400 = Color(0xFFF6656C);

  /// danger: текст, иконка, заливка.
  static const red600 = Color(0xFFC62828);

  /// Наведение на опасную кнопку.
  static const red700 = Color(0xFFB02222);

  /// Фон danger-плашки.
  static const red50 = Color(0xFFFDE6E6);

  /// mediumPurple. Заливка индикаторов.
  static const purple500 = Color(0xFF9C80EF);

  /// review: текст и иконка.
  static const purple700 = Color(0xFF5C3FBF);

  /// Плашка «ревью».
  static const purple50 = Color(0xFFEAE3FC);

  // ---------------------------------------------------------------------------
  // Цвета аватаров. Все восемь дают не менее 4.5:1 с белыми инициалами.
  // ---------------------------------------------------------------------------

  /// От celticBlue. Контраст с белым 4.88.
  static const blueAvatar = Color(0xFF2F6FD0);

  /// Контраст с белым 4.95.
  static const teal600 = Color(0xFF0E7C86);

  /// Контраст с белым 5.01.
  static const orange600 = Color(0xFFB0561A);

  /// От roseQuartzPink. Контраст с белым 5.80.
  static const pink600 = Color(0xFFA3417F);

  /// От mediumPurple. Контраст с белым 5.71.
  static const violet600 = Color(0xFF7A4BC9);
}
