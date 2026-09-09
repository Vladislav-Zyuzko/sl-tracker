import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/mention_field.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown.dart';
import 'package:sl_tracker_web/shared/uikit/navigation/sl_tabs.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Разметка, которую вставляет панель форматирования.
enum _Format {
  bold('**', '**', Icons.format_bold_rounded, 'Жирный', 'текст'),
  italic('*', '*', Icons.format_italic_rounded, 'Курсив', 'текст'),
  code('`', '`', Icons.code_rounded, 'Код', 'код'),
  link('[', '](https://)', Icons.link_rounded, 'Ссылка', 'подпись'),
  list('- ', '', Icons.format_list_bulleted_rounded, 'Список', 'пункт'),
  quote('> ', '', Icons.format_quote_rounded, 'Цитата', 'цитата');

  const _Format(
    this.prefix,
    this.suffix,
    this.icon,
    this.tooltip,
    this.placeholder,
  );

  final String prefix;
  final String suffix;
  final IconData icon;
  final String tooltip;

  /// Что подставить, когда ничего не выделено: пустая разметка бесполезна.
  final String placeholder;
}

/// Редактор Markdown: «Написать / Просмотр», панель из шести кнопок, поле
/// с подсказкой упоминаний (`docs/design/components.md`, 18.3 и 19).
///
/// Один виджет и для описания задачи, и для комментария: разница между ними
/// — в размерах и подписи кнопок, а не в механике. WYSIWYG в MVP не делаем.
class SLMarkdownEditor extends StatefulWidget {
  /// @nodoc
  const SLMarkdownEditor({
    required this.controller,
    required this.issueKey,
    required this.actions,
    this.focusNode,
    this.hint,
    this.hintText,
    this.minLines = 8,
    this.maxLines = 20,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmit,
    super.key,
  });

  /// @nodoc
  final TextEditingController controller;

  /// @nodoc
  final String issueKey;

  /// Кнопки в подвале: «Отмена», «Сохранить» либо «Отправить».
  final List<Widget> actions;

  /// @nodoc
  final FocusNode? focusNode;

  /// Плейсхолдер поля.
  final String? hint;

  /// Подсказка в подвале, слева: «Ctrl+Enter — сохранить».
  final String? hintText;

  /// @nodoc
  final int minLines;

  /// @nodoc
  final int maxLines;

  /// @nodoc
  final bool autofocus;

  /// @nodoc
  final bool enabled;

  /// `Ctrl/Cmd + Enter`.
  final VoidCallback? onSubmit;

  @override
  State<SLMarkdownEditor> createState() => _SLMarkdownEditorState();
}

enum _EditorTab { write, preview }

class _SLMarkdownEditorState extends State<SLMarkdownEditor> {
  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'markdown-editor');
  var _tab = _EditorTab.write;

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Оборачивает выделение разметкой.
  ///
  /// Каретка после вставки стоит внутри разметки, а не за ней: человек
  /// нажал «жирный», чтобы писать жирным, а не чтобы любоваться звёздочками.
  void _apply(_Format format) {
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selected = text.substring(start, end);
    final body = selected.isEmpty ? format.placeholder : selected;

    final inserted = '${format.prefix}$body${format.suffix}';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, inserted),
      selection: TextSelection(
        baseOffset: start + format.prefix.length,
        extentOffset: start + format.prefix.length + body.length,
      ),
    );

    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return CallbackShortcuts(
      // На macOS модификатор — `meta`, на остальных — `control`. Проверяем
      // обе комбинации: одна из них всегда лишняя, но ни одна не мешает.
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _apply(_Format.bold),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _apply(_Format.bold),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _apply(_Format.italic),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _apply(_Format.italic),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _apply(_Format.link),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _apply(_Format.link),
        if (widget.onSubmit != null) ...{
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              widget.onSubmit!,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true):
              widget.onSubmit!,
        },
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: SLRadii.mdAll,
          border: Border.all(color: colors.border, width: SLBorders.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SLSpacing.space2,
              ),
              child: SLTabBar<_EditorTab>(
                tabs: const [
                  SLTabItem(value: _EditorTab.write, label: 'Написать'),
                  SLTabItem(value: _EditorTab.preview, label: 'Просмотр'),
                ],
                value: _tab,
                onChanged: (value) => setState(() => _tab = value),
              ),
            ),
            if (_tab == _EditorTab.write) ...[
              _Toolbar(enabled: widget.enabled, onApply: _apply),
              _Field(
                controller: widget.controller,
                focusNode: _focusNode,
                issueKey: widget.issueKey,
                hint: widget.hint,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
              ),
            ] else
              _Preview(
                controller: widget.controller,
                minLines: widget.minLines,
              ),
            _Footer(hint: widget.hintText, actions: widget.actions),
          ],
        ),
      ),
    );
  }
}

/// Шесть кнопок форматирования. Больше — уже панель текстового процессора.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.enabled, required this.onApply});

  final bool enabled;
  final ValueChanged<_Format> onApply;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: SLBorders.hairline,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space1),
      child: Row(
        children: [
          for (final format in _Format.values)
            SLIconButton(
              icon: format.icon,
              tooltip: format.tooltip,
              size: SLButtonSize.sm,
              onPressed: enabled ? () => onApply(format) : null,
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.issueKey,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    required this.autofocus,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String issueKey;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(SLSpacing.space3),
    child: SLMentionField(
      controller: controller,
      focusNode: focusNode,
      issueKey: issueKey,
      hint: hint,
      minLines: minLines,
      maxLines: maxLines,
      autofocus: autofocus,
      enabled: enabled,
    ),
  );
}

/// Вкладка «Просмотр»: то же, что увидят все.
class _Preview extends StatelessWidget {
  const _Preview({required this.controller, required this.minLines});

  final TextEditingController controller;
  final int minLines;

  /// Высота строки в поле ввода — чтобы просмотр не схлопывался в ничто
  /// и переключение вкладок не дёргало раскладку.
  static const lineHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) => Container(
        constraints: BoxConstraints(minHeight: minLines * lineHeight),
        padding: const EdgeInsets.all(SLSpacing.space3),
        alignment: Alignment.topLeft,
        child: value.text.trim().isEmpty
            ? Text(
                'Пока нечего показывать',
                style: text.body.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            // Упоминания в просмотре рисуются по именам из самих токенов:
            // актуального списка `mentions` до отправки ещё не существует.
            : SLMarkdown(
                data: value.text,
                mentions: _mentionsOf(value.text),
                selectable: false,
              ),
      ),
    );
  }

  static List<MentionRef> _mentionsOf(String body) => [
    for (final match in MentionToken.pattern.allMatches(body))
      MentionRef(id: match.group(2)!, displayName: match.group(1)!),
  ];
}

/// Подвал: подсказка о хоткее слева, кнопки справа.
class _Footer extends StatelessWidget {
  const _Footer({required this.hint, required this.actions});

  final String? hint;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: SLBorders.hairline,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SLSpacing.space3,
        vertical: SLSpacing.space1,
      ),
      child: Row(
        children: [
          if (hint != null)
            Flexible(
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.label.copyWith(color: colors.textMuted),
              ),
            ),
          const Spacer(),
          for (final action in actions) ...[
            const SizedBox(width: SLSpacing.space2),
            action,
          ],
        ],
      ),
    );
  }
}
