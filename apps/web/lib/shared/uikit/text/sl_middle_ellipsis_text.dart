import 'package:flutter/material.dart';

/// Текст, который при нехватке места обрезается **посередине**.
///
/// Нужен там, где значимы оба конца строки: у адреса это имя ящика и домен
/// (`ivan…@очень-длинный-домен.ru`). Обычный `TextOverflow.ellipsis` съедает
/// домен целиком, и строка перестаёт что-либо значить
/// (`docs/design/screens/access-list.md`, `profile.md`).
///
/// Полное значение остаётся доступным в тултипе.
class SLMiddleEllipsisText extends StatelessWidget {
  /// @nodoc
  const SLMiddleEllipsisText({
    required this.value,
    this.style,
    this.semanticsLabel,
    super.key,
  });

  /// Полное значение. В тултипе показывается именно оно.
  final String value;

  /// @nodoc
  final TextStyle? style;

  /// Что читает скринридер. По умолчанию — полное значение, а не обрезок.
  final String? semanticsLabel;

  /// Символ-многоточие. Один символ, а не три точки: три точки шире
  /// и в плотной строке заметно съедают место.
  static const ellipsis = '…';

  /// Доля, которая остаётся от начала строки.
  ///
  /// Начало важнее: по нему человек узнаёт запись в списке.
  static const headRatio = 0.6;

  /// Подбирает строку, помещающуюся в [maxWidth].
  ///
  /// Вынесено отдельно и открыто для теста: это единственная нетривиальная
  /// часть компонента.
  static String fit(
    String value,
    TextStyle style,
    double maxWidth, {
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (maxWidth <= 0 || value.isEmpty) return value;

    double widthOf(String candidate) {
      final painter = TextPainter(
        text: TextSpan(text: candidate, style: style),
        maxLines: 1,
        textScaler: textScaler,
        textDirection: textDirection,
      )..layout();
      final width = painter.width;
      painter.dispose();

      return width;
    }

    if (widthOf(value) <= maxWidth) return value;

    final runes = value.characters.toList();

    String candidateOf(int kept) {
      final head = (kept * headRatio).round().clamp(1, kept);
      final tail = kept - head;

      return runes.take(head).join() +
          ellipsis +
          (tail == 0 ? '' : runes.skip(runes.length - tail).join());
    }

    // Двоичный поиск по числу сохранённых символов: линейный проход по
    // длинному адресу — это десятки замеров текста на каждый кадр.
    var low = 1;
    var high = runes.length - 1;
    var best = candidateOf(1);

    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final candidate = candidateOf(middle);

      if (widthOf(candidate) <= maxWidth) {
        best = candidate;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }

    return best;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final text = constraints.maxWidth.isFinite
            ? fit(
                value,
                effectiveStyle,
                constraints.maxWidth,
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
              )
            : value;

        final label = Text(
          text,
          style: effectiveStyle,
          maxLines: 1,
          softWrap: false,
          semanticsLabel: semanticsLabel ?? value,
        );

        // Тултип нужен только там, где что-то действительно спрятано.
        return text == value ? label : Tooltip(message: value, child: label);
      },
    );
  }
}
