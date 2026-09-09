import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Таблица стилей Markdown из токенов дизайн-системы
/// (`docs/design/components.md`, 18.1).
///
/// Отдельный файл, потому что таблица длинная и меняется она вместе со
/// спекой, а не вместе с логикой рендера.
sealed class SLMarkdownStyle {
  /// Стили для текста задачи и комментариев.
  static MarkdownStyleSheet of(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final body = text.body.copyWith(color: colors.textPrimary);

    return MarkdownStyleSheet(
      p: body,
      pPadding: const EdgeInsets.only(bottom: SLSpacing.space3),
      a: text.body.copyWith(color: colors.accent),
      em: body.copyWith(fontStyle: FontStyle.italic),
      strong: body.copyWith(fontWeight: FontWeight.w600),
      del: body.copyWith(
        color: colors.textMuted,
        decoration: TextDecoration.lineThrough,
      ),
      // H1 в теле задачи намеренно скромнее заголовка страницы: иначе
      // описание начинает конкурировать с названием задачи.
      h1: text.title.copyWith(color: colors.textPrimary),
      h1Padding: const EdgeInsets.only(
        top: SLSpacing.space6,
        bottom: SLSpacing.space2,
      ),
      h2: text.bodyStrong.copyWith(color: colors.textPrimary),
      h2Padding: const EdgeInsets.only(
        top: SLSpacing.space4,
        bottom: SLSpacing.space2,
      ),
      h3: text.bodyStrong.copyWith(color: colors.textSecondary),
      h3Padding: const EdgeInsets.only(
        top: SLSpacing.space3,
        bottom: SLSpacing.space1,
      ),
      // Глубже третьего уровня спека не поддерживает — заголовки 4–6
      // рисуются как третий, а не исчезают.
      h4: text.bodyStrong.copyWith(color: colors.textSecondary),
      h5: text.bodyStrong.copyWith(color: colors.textSecondary),
      h6: text.bodyStrong.copyWith(color: colors.textSecondary),
      code: text.mono.copyWith(color: colors.textPrimary),
      codeblockPadding: const EdgeInsets.all(SLSpacing.space3),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: SLRadii.smAll,
        border: Border.all(color: colors.border, width: SLBorders.hairline),
      ),
      blockquote: text.body.copyWith(color: colors.textSecondary),
      blockquotePadding: const EdgeInsets.only(left: SLSpacing.space3),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.border, width: _quoteStripe),
        ),
      ),
      listBullet: text.body.copyWith(color: colors.textMuted),
      listIndent: SLSpacing.space4,
      listBulletPadding: const EdgeInsets.only(right: SLSpacing.space1),
      checkbox: text.body.copyWith(color: colors.textMuted),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      tableHead: text.bodySStrong.copyWith(color: colors.textPrimary),
      tableBody: text.bodyS.copyWith(color: colors.textPrimary),
      tableBorder: TableBorder.all(
        color: colors.borderSubtle,
        width: SLBorders.hairline,
      ),
      tableCellsPadding: const EdgeInsets.all(SLSpacing.space2),
      tableHeadCellsPadding: const EdgeInsets.all(SLSpacing.space2),
      tableHeadCellsDecoration: BoxDecoration(color: colors.surfaceSunken),
      tableColumnWidth: const IntrinsicColumnWidth(),
      blockSpacing: SLSpacing.space3,
      // Ширину блока держит вызывающий: и описание, и комментарий ограничены
      // 720 px читаемой колонки.
      textAlign: WrapAlignment.start,
    );
  }

  /// Полоса слева у цитаты.
  static const _quoteStripe = 3.0;

  /// Вертикальный padding инлайн-кода. Значение вшито в компонент и наружу
  /// не торчит (`system.md`, 10.1).
  static const inlineCodeVerticalPadding = 2.0;

  /// Горизонтальный padding инлайн-кода и упоминания.
  static const inlineChipPadding = 4.0;
}
