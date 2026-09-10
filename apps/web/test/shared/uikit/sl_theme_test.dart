import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_priority_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_status_colors.dart';
import 'package:sl_tracker_web/shared/uikit/sl_shadows.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

/// Считает относительную яркость по WCAG 2.1.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Коэффициент контраста двух цветов.
///
/// Проверяем контраст в тестах, а не на глаз: дизайн-система обещает
/// конкретные числа, и подстановка «похожего» цвета в тему обязана падать.
double _contrast(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

/// Кладёт полупрозрачный [top] на непрозрачный [bottom].
///
/// Нужен там, где цвет на экране получается смешиванием, а не берётся
/// из темы: три такие заливки в приложении есть — оверлей перетаскивания
/// файлов и две вспышки строки после смены статуса.
Color _over(Color top, Color bottom) {
  final a = top.a;

  return Color.from(
    alpha: 1,
    red: top.r * a + bottom.r * (1 - a),
    green: top.g * a + bottom.g * (1 - a),
    blue: top.b * a + bottom.b * (1 - a),
  );
}

void main() {
  group('темы приложения', () {
    test('обе темы содержат все расширения дизайн-системы', () {
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        expect(theme.extension<SLColorScheme>(), isNotNull);
        expect(theme.extension<SLTextScheme>(), isNotNull);
        expect(theme.extension<SLStatusColors>(), isNotNull);
        expect(theme.extension<SLPriorityColors>(), isNotNull);
        expect(theme.extension<SLAvatarColors>(), isNotNull);
      }
    });

    test('яркость темы согласована с её материальной схемой', () {
      expect(SLThemeData.light.brightness, Brightness.light);
      expect(SLThemeData.light.colorScheme.brightness, Brightness.light);
      expect(SLThemeData.dark.brightness, Brightness.dark);
      expect(SLThemeData.dark.colorScheme.brightness, Brightness.dark);
    });

    test('ripple выключен, плотность компактная — в обеих темах', () {
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        expect(theme.splashFactory, NoSplash.splashFactory);
        expect(theme.visualDensity, VisualDensity.compact);
      }
    });

    test('оверлей высоты выключен', () {
      // Иначе в тёмной теме Material сам осветлял бы поверхности по
      // elevation, а иерархия в системе задаётся ролями (`system.md`, 12.3).
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        expect(theme.applyElevationOverlayColor, isFalse);
      }
    });

    test('фон приложения берётся из роли surface', () {
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        final colors = theme.extension<SLColorScheme>()!;

        expect(theme.scaffoldBackgroundColor, colors.surface);
        expect(theme.canvasColor, colors.surface);
      }
    });
  });

  // Обе темы проходят одни и те же проверки контраста. Числа берутся
  // из `system.md` 1.3 и пересчитываются здесь, а не сверяются с таблицей:
  // тест обязан ловить цвет, который «выглядит нормально», но AA не проходит.
  for (final entry in {
    'светлая': SLThemeData.light,
    'тёмная': SLThemeData.dark,
  }.entries) {
    group('контраст по WCAG: ${entry.key} тема', () {
      final theme = entry.value;
      final colors = theme.extension<SLColorScheme>()!;

      test('три уровня текста проходят AA на основной поверхности', () {
        expect(_contrast(colors.textPrimary, colors.surface), greaterThan(4.5));
        expect(
          _contrast(colors.textSecondary, colors.surface),
          greaterThan(4.5),
        );
        expect(_contrast(colors.textMuted, colors.surface), greaterThan(4.5));
      });

      test('текст на акценте и на опасной заливке проходит AA', () {
        expect(_contrast(colors.textOnAccent, colors.accent), greaterThan(4.5));
        expect(_contrast(colors.textOnAccent, colors.danger), greaterThan(4.5));
        expect(_contrast(colors.textOnAccent, colors.success), greaterThan(4.5));
        expect(
          _contrast(colors.textOnWarning, colors.warningAccent),
          greaterThan(4.5),
        );
      });

      test('граница интерактивного элемента даёт не менее 3:1', () {
        expect(_contrast(colors.borderStrong, colors.surface), greaterThan(3));
        expect(
          _contrast(colors.borderStrong, colors.surfaceSunken),
          greaterThan(3),
        );
        expect(
          _contrast(colors.borderStrong, colors.surfaceSelected),
          greaterThan(3),
        );
      });

      test('текст тултипа читается на его фоне', () {
        expect(
          _contrast(colors.tooltipText, colors.tooltipSurface),
          greaterThan(4.5),
        );
      });

      test('текст плашки статуса читается на её фоне', () {
        final statuses = theme.extension<SLStatusColors>()!;

        for (final status in IssueStatus.values) {
          expect(
            _contrast(statuses.textOf(status), statuses.surfaceOf(status)),
            greaterThan(4.3),
            reason: 'статус ${status.code}',
          );
        }
      });

      test('цвет статуса читается и без плашки — в фильтрах и меню', () {
        final statuses = theme.extension<SLStatusColors>()!;

        for (final status in IssueStatus.values) {
          expect(
            _contrast(statuses.textOf(status), colors.surface),
            greaterThan(4.5),
            reason: 'статус ${status.code}',
          );
        }
      });

      test('инициалы читаются на всех восьми заливках аватара', () {
        final avatars = theme.extension<SLAvatarColors>()!;

        for (var i = 0; i < avatars.fills.length; i++) {
          expect(
            _contrast(colors.textOnAccent, avatars.fills[i]),
            greaterThan(4.5),
            reason: 'аватар $i',
          );
          // Светлая заливка на светлом фоне и тёмная на тёмном одинаково
          // превращаются в пятно: кружок обязан отделяться от поверхности.
          expect(
            _contrast(avatars.fills[i], colors.surface),
            greaterThan(3),
            reason: 'аватар $i на поверхности',
          );
        }
      });

      test('заливка шкалы приоритета даёт не менее 3:1 к поверхности', () {
        // WCAG 1.4.11: столбик — графический объект, несущий значение.
        final priorities = theme.extension<SLPriorityColors>()!;

        for (final range in PriorityRange.values) {
          expect(
            _contrast(priorities.bars[range]!, colors.surface),
            greaterThan(3),
            reason: 'диапазон ${range.name}, заливка',
          );
          expect(
            _contrast(priorities.numbers[range]!, colors.surface),
            greaterThan(4.5),
            reason: 'диапазон ${range.name}, число',
          );
        }
      });

      test('оверлей перетаскивания файлов читается поверх содержимого', () {
        // Заливка полупрозрачная (0.9), поэтому проверяется смешанный цвет,
        // а не роль: именно он попадает человеку в глаз.
        final overlay = _over(
          colors.accentSurface.withValues(alpha: 0.9),
          colors.surface,
        );

        expect(_contrast(colors.accentPressed, overlay), greaterThan(4.5));
        expect(_contrast(colors.accent, overlay), greaterThan(3));
      });
    });
  }

  group('тёмная схема отличается от светлой по существу', () {
    final light = SLThemeData.light.extension<SLColorScheme>()!;
    final dark = SLThemeData.dark.extension<SLColorScheme>()!;

    test('это не копия светлой', () {
      // До версии 1.3 дизайн-системы тёмная схема была заглушкой,
      // делегирующей светлой. Тест ловит возврат к этому состоянию.
      expect(dark.surface, isNot(light.surface));
      expect(dark.textPrimary, isNot(light.textPrimary));
      expect(dark.accent, isNot(light.accent));
    });

    test('поверхности в тёмной схеме темнее текста, в светлой наоборот', () {
      expect(
        _luminance(light.surface),
        greaterThan(_luminance(light.textPrimary)),
      );
      expect(_luminance(dark.surface), lessThan(_luminance(dark.textPrimary)));
    });

    test('surfaceSunken утоплен относительно surface в обеих схемах', () {
      // Направление роли одно и то же: фон приложения всегда «дальше»
      // от контента, то есть темнее — в светлой схеме и в тёмной.
      expect(
        _luminance(light.surfaceSunken),
        lessThan(_luminance(light.surface)),
      );
      expect(
        _luminance(dark.surfaceSunken),
        lessThan(_luminance(dark.surface)),
      );
    });

    test('наведение и нажатие уводят акцент от фона, а не к нему', () {
      // В светлой схеме состояние затемняет акцент, в тёмной осветляет.
      expect(_luminance(light.accentHover), lessThan(_luminance(light.accent)));
      expect(
        _luminance(light.accentPressed),
        lessThan(_luminance(light.accentHover)),
      );

      expect(
        _luminance(dark.accentHover),
        greaterThan(_luminance(dark.accent)),
      );
      expect(
        _luminance(dark.accentPressed),
        greaterThan(_luminance(dark.accentHover)),
      );
    });

    test('textOnAccent в тёмной схеме — тёмные чернила, а не белый', () {
      // Ровно то место, где ломается предположение «на акценте всегда белое».
      expect(_luminance(dark.textOnAccent), lessThan(_luminance(dark.accent)));
      expect(
        _luminance(light.textOnAccent),
        greaterThan(_luminance(light.accent)),
      );
    });

    test('overlayHover осветляет тёмную схему и затемняет светлую', () {
      expect(
        _luminance(_over(dark.overlayHover, dark.surface)),
        greaterThan(_luminance(dark.surface)),
      );
      expect(
        _luminance(_over(light.overlayHover, light.surface)),
        lessThan(_luminance(light.surface)),
      );
    });

    test('overlayOnAccent не меняется между схемами: плёнка всегда белая', () {
      expect(dark.overlayOnAccentHover, light.overlayOnAccentHover);
      expect(dark.overlayOnAccentPressed, light.overlayOnAccentPressed);
    });

    test('тултип не инвертируется в тёмной схеме', () {
      // Белый прямоугольник в тёмном интерфейсе слепит и читается как
      // ошибка отрисовки. Тултип светлее поверхности, но не белый.
      expect(
        _luminance(dark.tooltipSurface),
        greaterThan(_luminance(dark.surface)),
      );
      expect(_contrast(dark.tooltipSurface, dark.surface), lessThan(3));
    });

    test('вспышка строки в тёмной схеме не хуже, чем в светлой', () {
      // Подсветка кладётся поверх строки целиком, поэтому вуаль тонирует
      // и текст, и фон. Порога дизайнер здесь не задавал — вспышка живёт
      // меньше секунды, — но тёмная схема не имеет права оказаться хуже.
      double flash(SLColorScheme colors, Color veil) {
        final tinted = veil.withValues(alpha: 0.5);

        return _contrast(
          _over(tinted, colors.textPrimary),
          _over(tinted, colors.surface),
        );
      }

      expect(
        flash(dark, dark.accentSurface),
        greaterThan(flash(light, light.accentSurface)),
      );
      expect(
        flash(dark, dark.dangerSurface),
        greaterThan(flash(light, light.dangerSurface)),
      );
    });
  });

  group('тени', () {
    test('обе темы отдают тени расширением', () {
      expect(SLThemeData.light.extension<SLShadows>(), isNotNull);
      expect(SLThemeData.dark.extension<SLShadows>(), isNotNull);
    });

    test('геометрия одна, меняется только цвет', () {
      const light = SLShadows.light();
      const dark = SLShadows.dark();

      for (final pair in [
        (light.sm, dark.sm),
        (light.md, dark.md),
        (light.lg, dark.lg),
      ]) {
        expect(pair.$2.length, pair.$1.length);
        for (var i = 0; i < pair.$1.length; i++) {
          expect(pair.$2[i].offset, pair.$1[i].offset);
          expect(pair.$2[i].blurRadius, pair.$1[i].blurRadius);
        }
      }
    });

    test('в тёмной схеме тень чёрная и втрое плотнее', () {
      const light = SLShadows.light();
      const dark = SLShadows.dark();

      for (final shadows in [dark.sm, dark.md, dark.lg]) {
        for (final shadow in shadows) {
          expect(shadow.color.r, 0);
          expect(shadow.color.g, 0);
          expect(shadow.color.b, 0);
        }
      }

      expect(dark.sm.first.color.a, greaterThan(light.sm.first.color.a * 3));
      expect(dark.lg.first.color.a, greaterThan(light.lg.first.color.a * 3));
    });

    test('базовый цвет тени не светлее поверхности', () {
      // Он уходит в `ColorScheme.shadow`, которым Material рисует тень сам.
      // Светлый базовый цвет дал бы в тёмной схеме ореол вместо тени.
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        final colors = theme.extension<SLColorScheme>()!;
        final shadows = theme.extension<SLShadows>()!;

        expect(theme.colorScheme.shadow, shadows.base);
        expect(_luminance(shadows.base), lessThan(_luminance(colors.surface)));
      }
    });
  });

  group('модальное окно', () {
    test('рисует границу в обеих схемах, безусловно', () {
      // В тёмной схеме `shadowLg` теряет почти половину силы, и без границы
      // модалка на подложке `scrim` остаётся без края. Ветвления по теме
      // внутри компонента быть не должно (`components.md`, 13).
      for (final theme in [SLThemeData.light, SLThemeData.dark]) {
        final colors = theme.extension<SLColorScheme>()!;
        final shape = theme.dialogTheme.shape! as RoundedRectangleBorder;

        expect(shape.side.style, BorderStyle.solid);
        expect(shape.side.color, colors.border);
      }
    });

    test('подложка модалки в тёмной схеме плотнее', () {
      final light = SLThemeData.light.extension<SLColorScheme>()!;
      final dark = SLThemeData.dark.extension<SLColorScheme>()!;

      expect(dark.scrim.a, greaterThan(light.scrim.a));
      expect(_luminance(dark.scrim), lessThan(_luminance(light.scrim)));
    });
  });

  group('SLTextScheme', () {
    test('интерфейсные стили используют табличные цифры', () {
      const scheme = SLTextScheme.base();

      for (final style in [
        scheme.overline,
        scheme.caption,
        scheme.label,
        scheme.labelStrong,
        scheme.bodyS,
        scheme.bodySStrong,
        scheme.body,
        scheme.bodyStrong,
        scheme.title,
        scheme.h2,
        scheme.h1,
      ]) {
        expect(style.fontFeatures, isNotEmpty);
        expect(style.fontFamily, SLTextScheme.interFamily);
      }
    });

    test('моноширинный стиль берёт другое семейство', () {
      expect(
        const SLTextScheme.base().mono.fontFamily,
        SLTextScheme.monoFamily,
      );
    });
  });
}
