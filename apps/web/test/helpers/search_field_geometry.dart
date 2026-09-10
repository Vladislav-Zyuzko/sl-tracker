import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';

/// Видимая рамка поля поиска — прямоугольник, в котором `InputDecorator`
/// рисует заливку и контур.
///
/// Меряется именно она, а не `SLSearchField`: коробку поля держит
/// `SizedBox(height)`, и коробка была 36 во всех состояниях даже тогда,
/// когда рамка внутри неё была 18 без текста и 24 с текстом, — поэтому
/// проверки размера коробки этого дефекта не видели.
///
/// `_BorderContainer` — приватный класс Flutter. Если его переименуют,
/// поиск ничего не найдёт, и тест упадёт громко, а не пройдёт молча.
Rect searchFieldFrame(WidgetTester tester) {
  final frame = find.descendant(
    of: find.byType(SLSearchField),
    matching: find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_BorderContainer',
    ),
  );
  expect(frame, findsOneWidget, reason: 'рамка InputDecorator не найдена');

  return tester.getRect(frame);
}

/// Проводит поле поиска через состояния, в которые его приводит человек, —
/// пустое без фокуса, пустое в фокусе, с текстом — и возвращает рамку
/// в каждом.
///
/// Загрузку (`isLoading`) задаёт родитель, а не человек, поэтому её тест
/// выставляет сам.
Future<Map<String, Rect>> searchFieldFramesByState(WidgetTester tester) async {
  final input = find.descendant(
    of: find.byType(SLSearchField),
    matching: find.byType(TextField),
  );
  final frames = <String, Rect>{'пустое без фокуса': searchFieldFrame(tester)};

  await tester.tap(input);
  await tester.pump();
  frames['пустое в фокусе'] = searchFieldFrame(tester);

  await tester.enterText(input, 'csv');
  await tester.pump();
  // Состояние действительно сменилось: справа кнопка очистки 24 × 24 —
  // самый высокий из того, что там бывает.
  expect(
    find.descendant(
      of: find.byType(SLSearchField),
      matching: find.byIcon(Icons.close_rounded),
    ),
    findsOneWidget,
  );
  frames['с текстом'] = searchFieldFrame(tester);

  // Дебаунс не должен пережить тест.
  await tester.pump(const Duration(seconds: 1));

  return frames;
}

/// Рамка в каждом состоянии совпадает с коробкой поля: та же высота,
/// та же ширина, то же место.
void expectFrameFillsField(WidgetTester tester, Map<String, Rect> frames) {
  final box = tester.getRect(find.byType(SLSearchField));

  for (final MapEntry(key: state, value: frame) in frames.entries) {
    expect(
      frame,
      box,
      reason: 'рамка в состоянии «$state» — $frame, коробка поля — $box',
    );
  }
}
