import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Файлы, которым литералы цвета разрешены, и объяснение почему.
///
/// Список закрытый: любое новое исключение проходит через правку этого теста,
/// то есть его видно в ревью. Именно так и задумано (`system.md`, 12.1).
const _allowed = <String, String>{
  // Слой 1 и 2 дизайн-системы: сама палитра и её раскладка по ролям.
  // Больше hex взяться неоткуда.
  'lib/shared/uikit/colors/sl_color_palette.dart': 'палитра',
  'lib/shared/uikit/colors/sl_color_scheme.dart': 'роли цвета',
  'lib/shared/uikit/colors/sl_status_colors.dart': 'шкала статусов',
  'lib/shared/uikit/colors/sl_priority_colors.dart': 'шкала приоритетов',
  'lib/shared/uikit/colors/sl_avatar_colors.dart': 'заливки аватаров',
  // Единственное задокументированное исключение из системы: цвет кнопки
  // задан Яндексом и не меняется ни в одной теме (`system.md`, 3.4.1).
  'lib/shared/uikit/buttons/yandex_id_button.dart': 'бренд Яндекс ID',
  // Тени построены на n800 с альфами из спеки. Тёмная тема их не переопределяет
  // намеренно: иерархия поверхностей задаётся ролями, а не тенью
  // (`system.md`, 12.3).
  'lib/shared/uikit/sl_shadows.dart': 'тени на базе n800',
  // Градиент здесь — маска прозрачности (`BlendMode.dstIn`): используется
  // только альфа, сам цвет на экран не попадает.
  'lib/shared/uikit/markdown/sl_markdown.dart': 'маска прозрачности',
};

/// `Color(0x…)` где угодно, кроме полностью прозрачного.
///
/// Прозрачное разрешено везде: это «цвета нет», а не цвет.
final _hexLiteral = RegExp(r'Color\(0x(?!00)[0-9A-Fa-f]{8}\)');

/// `Colors.что-то` из Material — но не `SLStatusColors.of` и не
/// `Colors.transparent`.
final _materialColor = RegExp(
  r'(?<![A-Za-z0-9_])Colors\.(?!transparent\b)[a-zA-Z]',
);

void main() {
  group('готовность к тёмной теме', () {
    test('в виджетах нет литералов цвета и палитры Material', () {
      final root = Directory('lib');
      expect(
        root.existsSync(),
        isTrue,
        reason: 'тест запускается из apps/web',
      );

      final offenders = <String>[];

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final path = entity.path.replaceAll(r'\', '/');
        // Сгенерированный клиент цветов не содержит и правке не подлежит.
        if (path.contains('/generated/')) continue;
        if (_allowed.containsKey(path)) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (_hexLiteral.hasMatch(line)) {
            offenders.add('$path:${i + 1}: hex-литерал — ${line.trim()}');
          }
          if (_materialColor.hasMatch(line)) {
            offenders.add('$path:${i + 1}: палитра Material — ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Цвет берётся из SLColorScheme.of(context), иначе тёмную тему '
            'придётся не подставить, а переписать (`system.md`, 12.1). '
            'Если литерал действительно обоснован — впишите файл '
            'в _allowed с объяснением.\n${offenders.join('\n')}',
      );
    });

    test('список исключений не разрастается молча', () {
      // Каждое исключение обязано существовать: удалённый файл в списке
      // означает, что список перестали читать.
      for (final path in _allowed.keys) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }

      expect(_allowed.length, 8);
    });
  });
}
