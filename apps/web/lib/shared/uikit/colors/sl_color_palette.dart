import 'package:flutter/widgets.dart';

/// Слой 1 дизайн-системы — сырая палитра SL Tracker.
///
/// **Использовать напрямую в UI запрещено.** Виджеты декорируются только
/// ролями из [SLColorScheme] и доменными шкалами (слой 3). Правило действует
/// в том числе ради тёмной темы: там меняются значения ролей, а не виджеты
/// (`docs/design/system.md`, разделы 1 и 12).
///
/// Значения перенесены из `docs/design/system.md` (разделы 2.1–2.4)
/// один в один: контраст уже посчитан дизайнером, пересчитывать его здесь
/// не нужно. Токены с префиксом `n`/`blue600`/… — светлая схема,
/// с префиксом `d` и суффиксом `D` — тёмная.
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

  // ---------------------------------------------------------------------------
  // Нейтральная шкала тёмной схемы (`system.md`, 2.3). Не инверсия светлой,
  // а своя: индекс означает то же самое — удаление от базовой поверхности,
  // только в светлой схеме шкала идёт от `n0` вниз по светлоте, а в тёмной
  // от `d0` вверх. Ни одна ступень не является чистым чёрным или белым.
  //
  // Контрасты в столбцах — к `d50`, базовой поверхности тёмной схемы.
  // ---------------------------------------------------------------------------

  /// Фон приложения, сайдбар, шапка таблицы. L* 6.3, контраст к `d50` 1.07.
  static const d0 = Color(0xFF10141C);

  /// Базовая поверхность: контент, карточки, модалки, меню. L* 9.8.
  static const d50 = Color(0xFF161B26);

  /// Наведение, заливка отключённых контролов. L* 14.1, 1.11.
  static const d100 = Color(0xFF1D2431);

  /// Нажатие, разделители, скелетон, плашка «открыт». L* 18.3, 1.24.
  static const d150 = Color(0xFF242D3C);

  /// Светлая полоса шиммера. Промежуточная ступень между [d150] и [d200]:
  /// в шкале 2.3 её нет, значение взято из таблицы ролей 3.1
  /// (`skeletonHighlight`), где шаг шиммера подобран отдельно.
  static const d175 = Color(0xFF2A3341);

  /// Контур панели, карточки, меню, модалки. L* 23.3, 1.46.
  static const d200 = Color(0xFF2E3849);

  /// Трек переключателя, фон тултипа. L* 31.2, 1.92.
  static const d300 = Color(0xFF3E4A5E);

  /// Отключённый текст и иконки. L* 41.0, 2.77.
  static const d400 = Color(0xFF55617A);

  /// Границы интерактивных элементов, иконки-подсказки. L* 58.0, 5.08.
  static const d500 = Color(0xFF7E8CA6);

  /// Третий уровень текста, иконки. L* 67.8, 7.00.
  static const d600 = Color(0xFF99A6BC);

  /// Второй уровень текста. L* 78.1, 9.58.
  static const d700 = Color(0xFFB7C2D4);

  /// Основной текст. L* 90.0, 13.34. Намеренно не белый: чистый белый даёт
  /// ореол вокруг мелкого текста 11–13 px, которым набран весь трекер.
  static const d800 = Color(0xFFDCE3EE);

  /// Текст на тултипе. L* 96.4, 15.77.
  static const d900 = Color(0xFFF2F5FA);

  /// Подложка модалки в тёмной схеме (`scrim` при alpha 0.72). Ниже всей
  /// шкалы: под модалкой фон обязан стать почти чёрным, иначе окно
  /// не читается как всплывший слой.
  static const dScrim = Color(0xFF05070B);

  // ---------------------------------------------------------------------------
  // Хроматическая палитра тёмной схемы (`system.md`, 2.4). Оттенки те же,
  // светлота перевёрнута: текстовые и акцентные — светлые, заливки-подложки —
  // тёмные. Насыщенность светлых ступеней снижена, иначе на тёмном фоне
  // они «звенят».
  // ---------------------------------------------------------------------------

  /// `accentPressed`. Контраст к [d50] 10.71.
  static const blueD300 = Color(0xFFADCEFF);

  /// `accentHover`, текст плашки «в работе». 8.68.
  static const blueD400 = Color(0xFF8CBAFF);

  /// `accent`, `info`, `borderFocus`. 6.99.
  static const blueD500 = Color(0xFF6BA6FF);

  /// `accentBorder`. 2.54.
  static const blueD700 = Color(0xFF3C5C8A);

  /// `surfaceSelectedHover`. 1.38.
  static const blueD750 = Color(0xFF24344F);

  /// Плашка «в работе». 1.34. Намеренно на 2.9 L* светлее [blueD800]:
  /// иначе на выделенной строке списка плашка исчезнет — там это один
  /// и тот же синий тинт.
  static const blueD780 = Color(0xFF1E3252);

  /// `accentSurface`, `surfaceSelected`. 1.23.
  static const blueD800 = Color(0xFF1B2C46);

  /// `success`. 7.87.
  static const greenD500 = Color(0xFF5FC46B);

  /// `successBorder`. 2.96.
  static const greenD700 = Color(0xFF35714A);

  /// `successSurface`, плашка «закрыт». 1.21.
  static const greenD800 = Color(0xFF16301E);

  /// `warningAccent`. 9.67.
  static const amberD400 = Color(0xFFF2B93D);

  /// `warning`, текст плашки «тестирование». 8.20.
  static const amberD500 = Color(0xFFE5A83C);

  /// Шкала приоритета, диапазон «высокий». 6.64.
  static const amberD600 = Color(0xFFD9922B);

  /// `warningSurface`, плашка «тестирование». 1.18.
  static const amberD800 = Color(0xFF33270F);

  /// `dangerHover`. 8.04.
  static const redD400 = Color(0xFFFF938C);

  /// `danger`, `borderDanger`. 6.58.
  static const redD500 = Color(0xFFF87A72);

  /// `dangerBorder`. 2.44.
  static const redD700 = Color(0xFF8E413E);

  /// `dangerSurface`. 1.17.
  static const redD800 = Color(0xFF3E1F20);

  /// Текст плашки «ревью». 8.31.
  static const purpleD400 = Color(0xFFBCA9F5);

  /// Плашка «ревью». 1.19.
  static const purpleD800 = Color(0xFF2A2350);

  /// Тёмные чернила на светлой заливке: `textOnAccent` и `textOnWarning`
  /// тёмной схемы. В тёмной схеме заливки `accent`, `danger`, `success`
  /// светлые, поэтому текст на них тёмный, а не белый.
  static const inkD = Color(0xFF0B111C);

  // ---------------------------------------------------------------------------
  // Цвета аватаров тёмной схемы (`system.md`, 8). Порядок тонов тот же, что
  // в светлой: у человека не меняется «его цвет» при переключении темы,
  // синий остаётся синим, только светлее. Все восемь дают не менее 4.5:1
  // с тёмными инициалами [inkD] и читаются на поверхности [d50].
  // ---------------------------------------------------------------------------

  /// Синий. С [inkD] 9.25, к [d50] 8.44.
  static const avatarBlueD = Color(0xFF8FB8F0);

  /// Бирюзовый. 9.66 / 8.81.
  static const avatarTealD = Color(0xFF6FC7CE);

  /// Зелёный. 10.03 / 9.14.
  static const avatarGreenD = Color(0xFF86CE7E);

  /// Янтарный. 9.68 / 8.82.
  static const avatarAmberD = Color(0xFFE0B357);

  /// Оранжевый. 9.23 / 8.41.
  static const avatarOrangeD = Color(0xFFEFA478);

  /// Красный. 8.33 / 7.60.
  static const avatarRedD = Color(0xFFF49189);

  /// Розовый. 8.43 / 7.69.
  static const avatarPinkD = Color(0xFFE793C4);

  /// Фиолетовый. 7.98 / 7.27.
  static const avatarVioletD = Color(0xFFB49BEE);
}
