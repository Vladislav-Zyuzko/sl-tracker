import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown_style.dart';
import 'package:sl_tracker_web/shared/uikit/markdown/sl_markdown_syntax.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Markdown-содержимое трекера: описание задачи и комментарии
/// (`docs/design/components.md`, 18).
///
/// Безопасность рендера — обязанность этого виджета, а не сервера
/// (D-22, US-43). Три правила, ради которых он написан:
///
/// 1. **Сырой HTML не разметка.** Набор синтаксисов собран вручную и не
///    содержит `InlineHtmlSyntax` — `<b>текст</b>` показывается как текст
///    (`SLMarkdownSyntax`).
/// 2. **Кликабельны только `http`, `https`, `mailto`.** Ссылка рисуется
///    здесь целиком, обработчик пакета не используется: адрес с любой другой
///    схемой становится обычным текстом, а не «ссылкой, которая молчит».
/// 3. **Картинки — только `http` и `https`.** Остальное показывается плашкой
///    «не загрузилось», а не грузится.
///
/// Ключ задачи `DEV-42` внутри текста остаётся обычным текстом: автоссылок
/// в MVP нет (D-38, `components.md`, 18.1.1). Это правильное поведение,
/// а не недоделка.
class SLMarkdown extends StatefulWidget {
  /// @nodoc
  const SLMarkdown({
    required this.data,
    this.mentions = const [],
    this.onOpenLink,
    this.onOpenImage,
    this.collapsedHeight,
    this.selectable = true,
    super.key,
  });

  /// Исходный текст в Markdown, как его отдал сервер.
  final String data;

  /// Упомянутые участники: **актуальные** имена и аватары.
  ///
  /// Токен, которого здесь нет, показывается обычным текстом — это
  /// упоминание постороннего, сервер его проигнорировал (US-74, D-41).
  final List<MentionRef> mentions;

  /// Открыть внешнюю ссылку. Схему виджет проверяет сам — сюда приходят
  /// только разрешённые адреса.
  final ValueChanged<String>? onOpenLink;

  /// Открыть картинку в просмотрщике.
  final ValueChanged<String>? onOpenImage;

  /// Высота, на которой длинный текст сворачивается градиентной маской
  /// (`components.md`, 18.2). `null` — не сворачивать.
  final double? collapsedHeight;

  /// В вебе текст ожидаемо выделяется и копируется.
  final bool selectable;

  /// Высота маски над свёрнутым текстом.
  static const fadeHeight = 48.0;

  @override
  State<SLMarkdown> createState() => _SLMarkdownState();
}

class _SLMarkdownState extends State<SLMarkdown> {
  var _expanded = false;

  @override
  void didUpdateWidget(SLMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Новый текст — снова свёрнут: иначе после правки описание осталось бы
    // раскрытым на всю длину без ведома читателя.
    if (oldWidget.data != widget.data) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final names = {
      for (final mention in widget.mentions) mention.id: mention.displayName,
    };

    final body = MarkdownBody(
      data: widget.data,
      selectable: widget.selectable,
      styleSheet: SLMarkdownStyle.of(context),
      extensionSet: SLMarkdownSyntax.extensionSet,
      // Синтаксисы уже перечислены в наборе; отдельные списки здесь пусты,
      // чтобы пакет не добавил к ним свои.
      builders: {
        'a': _LinkBuilder(onOpen: widget.onOpenLink),
        'code': _InlineCodeBuilder(),
        'pre': _CodeBlockBuilder(),
        SLMarkdownSyntax.mentionTag: _MentionBuilder(names: names),
      },
      imageBuilder: (uri, title, alt) =>
          _MarkdownImage(uri: uri, alt: alt, onOpen: widget.onOpenImage),
      checkboxBuilder: (checked) => _ReadOnlyCheckbox(checked: checked),
      onTapText: () {},
    );

    final collapsedHeight = widget.collapsedHeight;
    if (collapsedHeight == null) return body;

    return _Collapsible(
      collapsedHeight: collapsedHeight,
      expanded: _expanded,
      onExpand: () => setState(() => _expanded = true),
      child: body,
    );
  }
}

/// Сворачивание длинного текста на заданной высоте.
///
/// Меряет содержимое, а не гадает по числу символов: 400 px текста и 400 px
/// таблицы — это разное количество знаков.
class _Collapsible extends StatelessWidget {
  const _Collapsible({
    required this.collapsedHeight,
    required this.expanded,
    required this.onExpand,
    required this.child,
  });

  final double collapsedHeight;
  final bool expanded;
  final VoidCallback onExpand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (expanded) return child;

    return LayoutBuilder(
      builder: (context, constraints) => _MeasuredHeight(
        maxWidth: constraints.maxWidth,
        builder: (context, height) {
          if (height <= collapsedHeight) return child;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: SizedBox(
                  height: collapsedHeight,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: const [Color(0x00000000), Color(0xFF000000)],
                      stops: [
                        0,
                        (SLMarkdown.fadeHeight / collapsedHeight).clamp(
                          0.0,
                          1.0,
                        ),
                      ],
                    ).createShader(bounds),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: height,
                      child: child,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SLSpacing.space2),
              SLButton(
                label: 'Показать полностью',
                variant: SLButtonVariant.ghost,
                size: SLButtonSize.sm,
                onPressed: onExpand,
              ),
            ],
          );
        },
        child: child,
      ),
    );
  }
}

/// Отдаёт высоту, которую содержимое заняло бы целиком.
///
/// Рисует содержимое дважды: один раз невидимо и без ограничений — чтобы
/// узнать высоту, второй раз уже как надо. Дороже, чем прикинуть по числу
/// строк, но честно работает и с таблицами, и с картинками.
class _MeasuredHeight extends StatefulWidget {
  const _MeasuredHeight({
    required this.maxWidth,
    required this.builder,
    required this.child,
  });

  final double maxWidth;
  final Widget Function(BuildContext context, double height) builder;
  final Widget child;

  @override
  State<_MeasuredHeight> createState() => _MeasuredHeightState();
}

class _MeasuredHeightState extends State<_MeasuredHeight> {
  final _key = GlobalKey();
  double? _height;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_MeasuredHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxWidth != widget.maxWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;

    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    if (_height != box.size.height) setState(() => _height = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final height = _height;
    if (height != null) return widget.builder(context, height);

    // До первого замера содержимое показывается целиком: увидеть лишнее
    // на один кадр лучше, чем моргнуть пустотой.
    return SizedBox(key: _key, width: widget.maxWidth, child: widget.child);
  }
}

/// Ссылка. Кликабельна только с разрешённой схемой (US-43).
class _LinkBuilder extends MarkdownElementBuilder {
  _LinkBuilder({required this.onOpen});

  final ValueChanged<String>? onOpen;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final href = element.attributes['href'];
    final label = element.textContent;

    // Схема не из разрешённых — это просто текст. Не «ссылка, которая
    // не работает»: подчёркнутый синий адрес, ведущий в никуда, врёт.
    if (!SLMarkdownSyntax.isSafeLink(href)) {
      return Text(
        label,
        style: parentStyle ?? text.body.copyWith(color: colors.textPrimary),
      );
    }

    final callback = onOpen;

    return _HoverLink(
      label: label,
      href: href!,
      onOpen: callback == null ? null : () => callback(href),
    );
  }
}

/// Ссылка с подчёркиванием при наведении и иконкой внешнего перехода.
class _HoverLink extends StatefulWidget {
  const _HoverLink({
    required this.label,
    required this.href,
    required this.onOpen,
  });

  final String label;
  final String href;
  final VoidCallback? onOpen;

  @override
  State<_HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<_HoverLink> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final isExternal = !widget.href.toLowerCase().startsWith('mailto:');

    return Semantics(
      link: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onOpen,
          child: Tooltip(
            message: widget.href,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.label,
                    style: text.body.copyWith(
                      color: colors.accent,
                      decoration: _hovered ? TextDecoration.underline : null,
                      decorationColor: colors.accent,
                    ),
                  ),
                  if (isExternal)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: SLIconSizes.icon12,
                          color: colors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Упоминание участника.
///
/// Имя берётся из [names] — актуального списка `mentions`, — а не из текста
/// токена: человек мог переименоваться уже после публикации (US-74).
class _MentionBuilder extends MarkdownElementBuilder {
  _MentionBuilder({required this.names});

  final Map<String, String> names;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final id = element.attributes[SLMarkdownSyntax.mentionIdAttribute] ?? '';
    final actual = names[id];

    // Нераспознанный токен — обычный текст: связи нет, уведомления не было,
    // и подсвечивать нечего.
    if (actual == null) {
      final fallbackName =
          element.attributes[SLMarkdownSyntax.mentionNameAttribute] ?? '';

      return Text(
        MentionToken.format(id: id, displayName: fallbackName),
        style: parentStyle ?? text.body.copyWith(color: colors.textPrimary),
      );
    }

    return Semantics(
      label: 'упоминание: $actual',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SLMarkdownStyle.inlineChipPadding,
        ),
        decoration: BoxDecoration(
          color: colors.accentSurface,
          borderRadius: SLRadii.smAll,
        ),
        child: Text(
          '@$actual',
          style: text.body.copyWith(color: colors.accentPressed),
        ),
      ),
    );
  }
}

/// Инлайн-код: моноширинный текст на `surfaceSunken`.
class _InlineCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SLMarkdownStyle.inlineChipPadding,
        vertical: SLMarkdownStyle.inlineCodeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: SLRadii.smAll,
      ),
      child: Text(
        element.textContent,
        style: text.mono.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

/// Блок кода с горизонтальной прокруткой и кнопкой «Копировать».
///
/// Подсветки синтаксиса в MVP нет намеренно: это ещё одна зависимость
/// и заметный вес в бандле ради того, что в трекере читают глазами
/// (`components.md`, 18.1).
class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => _CodeBlock(code: element.textContent.replaceAll(RegExp(r'\n$'), ''));
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  var _hovered = false;
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;

    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _copied = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: SLSpacing.space3),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: SLRadii.smAll,
          border: Border.all(color: colors.border, width: SLBorders.hairline),
        ),
        child: Stack(
          children: [
            // Горизонтальная прокрутка, а не перенос: в коде перенос строки
            // меняет смысл того, что читаешь.
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(SLSpacing.space3),
                child: Text(
                  widget.code,
                  style: text.mono.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
            if (_hovered)
              Positioned(
                top: SLSpacing.space1,
                right: SLSpacing.space1,
                child: SLButton(
                  label: _copied ? 'Скопировано' : 'Копировать',
                  variant: SLButtonVariant.secondary,
                  size: SLButtonSize.sm,
                  onPressed: _copy,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Картинка из текста.
///
/// Схема проверяется до запроса: `javascript:` и `data:` не грузятся вовсе.
class _MarkdownImage extends StatelessWidget {
  const _MarkdownImage({required this.uri, required this.alt, this.onOpen});

  final Uri uri;
  final String? alt;
  final ValueChanged<String>? onOpen;

  /// Габариты плашки «не загрузилось» (`components.md`, 18.2).
  static const brokenSize = Size(160, 90);

  @override
  Widget build(BuildContext context) {
    final source = uri.toString();
    if (!SLMarkdownSyntax.isSafeImage(source)) {
      return _BrokenImage(name: alt ?? source);
    }

    final image = ClipRRect(
      borderRadius: SLRadii.smAll,
      child: Image.network(
        source,
        semanticLabel: alt,
        errorBuilder: (context, error, stackTrace) =>
            _BrokenImage(name: alt ?? source),
      ),
    );

    final callback = onOpen;
    if (callback == null) return image;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => callback(source), child: image),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      width: _MarkdownImage.brokenSize.width,
      height: _MarkdownImage.brokenSize.height,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: SLRadii.smAll,
      ),
      padding: const EdgeInsets.all(SLSpacing.space2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: SLIconSizes.icon24,
            color: colors.iconMuted,
          ),
          const SizedBox(height: SLSpacing.space1),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Чекбокс из списка `- [ ]`. В MVP только чтение (`components.md`, 18.1).
class _ReadOnlyCheckbox extends StatelessWidget {
  const _ReadOnlyCheckbox({required this.checked});

  final bool checked;

  /// Размер по спеке — 14, а не 16 как у настоящего чекбокса формы.
  static const size = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: SLSpacing.space1, top: 3),
      child: Semantics(
        label: checked ? 'отмечено' : 'не отмечено',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: checked ? colors.accent : null,
            borderRadius: SLRadii.smAll,
            border: Border.all(
              color: checked ? colors.accent : colors.borderStrong,
              width: SLBorders.hairline,
            ),
          ),
          child: checked
              ? Icon(
                  Icons.check_rounded,
                  size: size - 2,
                  color: colors.textOnAccent,
                )
              : null,
        ),
      ),
    );
  }
}
