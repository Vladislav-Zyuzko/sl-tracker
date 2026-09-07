import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_priority_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_status_colors.dart';
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

void main() {
  group('SLThemeData.light', () {
    test('содержит все расширения дизайн-системы', () {
      final theme = SLThemeData.light;

      expect(theme.extension<SLColorScheme>(), isNotNull);
      expect(theme.extension<SLTextScheme>(), isNotNull);
      expect(theme.extension<SLStatusColors>(), isNotNull);
      expect(theme.extension<SLPriorityColors>(), isNotNull);
      expect(theme.extension<SLAvatarColors>(), isNotNull);
    });

    test('ripple выключен глобально', () {
      expect(SLThemeData.light.splashFactory, NoSplash.splashFactory);
    });

    test('плотность интерфейса компактная', () {
      expect(SLThemeData.light.visualDensity, VisualDensity.compact);
    });
  });

  group('контраст по WCAG', () {
    final colors = SLThemeData.light.extension<SLColorScheme>()!;

    test('три уровня текста проходят AA на основной поверхности', () {
      expect(_contrast(colors.textPrimary, colors.surface), greaterThan(4.5));
      expect(_contrast(colors.textSecondary, colors.surface), greaterThan(4.5));
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

    test('текст плашки статуса читается на её фоне', () {
      final statuses = SLThemeData.light.extension<SLStatusColors>()!;

      for (final status in IssueStatus.values) {
        expect(
          _contrast(statuses.textOf(status), statuses.surfaceOf(status)),
          greaterThan(4.3),
          reason: 'статус ${status.code}',
        );
      }
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
