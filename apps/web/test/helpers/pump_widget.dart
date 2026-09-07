import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

/// Задаёт логический размер окна на время теста.
///
/// Размер важен: половина дизайн-системы зависит от брейкпоинта, и тест,
/// который молча идёт на дефолтных 800 × 600 при `devicePixelRatio` 3.0,
/// проверяет не ту раскладку, что задумана.
void useWindowSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;

  addTearDown(tester.view.reset);
}

/// Оборачивает компонент в тему приложения.
///
/// Все компоненты дизайн-системы читают цвета и типографику из
/// [ThemeExtension] и без темы падают намеренно — значит, в тестах тема нужна
/// настоящая, а не `MaterialApp` по умолчанию.
Future<void> pumpInTheme(
  WidgetTester tester,
  Widget child, {
  Size windowSize = const Size(1280, 800),
}) async {
  useWindowSize(tester, windowSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: SLThemeData.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
