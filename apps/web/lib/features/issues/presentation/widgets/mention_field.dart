import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/mention_token.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_shadows.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Что человек набрал после `@`.
@immutable
class _MentionTrigger {
  const _MentionTrigger({required this.start, required this.query});

  /// Позиция самого символа `@` в тексте.
  final int start;

  /// Строка после `@` — то, по чему ищет подсказка.
  final String query;
}

/// Поле ввода с подсказкой упоминаний по `@` (US-74).
///
/// Самый дорогой элемент экрана задачи. Механика:
///
/// * подсказка открывается на `@`, стоящем в начале слова, и закрывается,
///   как только в набранном появляется пробел — «e@mail.ru» подсказкой
///   не считается;
/// * запрос уходит **на сервер**, к участникам проекта задачи. Своим поиском
///   выдача не дополняется: маршрут специально сделан узким, чтобы составом
///   трекера нельзя было поинтересоваться перебором (ADR-0006, п. 6);
/// * выбор вставляет токен `@[Имя](user:<uuid>)` — идентификатор из ответа,
///   а не из головы;
/// * `Esc` закрывает подсказку, **`@` при этом остаётся символом**: человек
///   вполне мог иметь в виду просто «собаку».
///
/// Подсказка выводится под полем, а не у самой каретки. Каретка в Flutter
/// живёт внутри `RenderEditable`, и вытащить её экранные координаты можно
/// только через приватный API рендер-объекта; список под полем работает
/// одинаково во всех состояниях поля и не прыгает при переносе строк.
class SLMentionField extends ConsumerStatefulWidget {
  /// @nodoc
  const SLMentionField({
    required this.controller,
    required this.issueKey,
    this.focusNode,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofocus = false,
    this.enabled = true,
    this.textStyle,
    this.onChanged,
    super.key,
  });

  /// @nodoc
  final TextEditingController controller;

  /// Ключ задачи: подсказка ищет среди участников её проекта.
  final String issueKey;

  /// @nodoc
  final FocusNode? focusNode;

  /// @nodoc
  final String? hint;

  /// @nodoc
  final int minLines;

  /// @nodoc
  final int maxLines;

  /// @nodoc
  final bool autofocus;

  /// @nodoc
  final bool enabled;

  /// Стиль текста. По умолчанию — `body`.
  final TextStyle? textStyle;

  /// @nodoc
  final ValueChanged<String>? onChanged;

  /// Пауза перед запросом подсказки.
  ///
  /// Маршрут ограничен по частоте — это поиск, — и слать запрос на каждую
  /// букву значит собирать 429 вместо подсказки.
  static const debounce = Duration(milliseconds: 220);

  /// Высота строки подсказки.
  static const suggestionHeight = 32.0;

  /// Высота строки с email второй строкой.
  static const suggestionHeightWithEmail = 44.0;

  /// Максимальная высота списка подсказки.
  static const suggestionsMaxHeight = 240.0;

  /// Ширина списка подсказки.
  static const suggestionsWidth = 280.0;

  @override
  ConsumerState<SLMentionField> createState() => _SLMentionFieldState();
}

class _SLMentionFieldState extends ConsumerState<SLMentionField> {
  final _link = LayerLink();
  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(debugLabel: 'mention-field');

  OverlayEntry? _overlay;
  Timer? _debounce;

  _MentionTrigger? _trigger;
  AsyncValue<List<MentionSuggestionDto>> _items = const AsyncLoading();
  var _highlighted = 0;
  var _dismissed = false;
  var _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _closeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _close();
  }

  /// Ищет `@` перед кареткой.
  ///
  /// Требования к триггеру: `@` стоит в начале слова, после него нет пробелов
  /// и перевода строки, и длина запроса разумна — иначе подсказка открывалась
  /// бы посреди адреса почты и после каждого абзаца.
  static _MentionTrigger? _triggerAt(String text, int caret) {
    if (caret <= 0 || caret > text.length) return null;

    for (var i = caret - 1; i >= 0 && caret - i <= 64; i--) {
      final code = text.codeUnitAt(i);

      if (code == 0x40) {
        final before = i == 0 ? null : text.codeUnitAt(i - 1);
        final startsWord =
            before == null ||
            before == 0x20 ||
            before == 0x0A ||
            before == 0x09 ||
            before == 0x28;

        return startsWord
            ? _MentionTrigger(start: i, query: text.substring(i + 1, caret))
            : null;
      }

      // Пробел, перевод строки и скобка обрывают слово: подсказке здесь
      // делать нечего.
      if (code == 0x20 || code == 0x0A || code == 0x09 || code == 0x5D) {
        return null;
      }
    }

    return null;
  }

  void _onTextChanged() {
    if (!widget.enabled) return;

    final selection = widget.controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _close();

      return;
    }

    final trigger = _triggerAt(widget.controller.text, selection.baseOffset);
    if (trigger == null) {
      _close();

      return;
    }

    // `Esc` закрыл подсказку — не открываем её снова, пока человек не уйдёт
    // от этого `@` и не начнёт новое упоминание.
    if (_dismissed && _trigger?.start == trigger.start) {
      _trigger = trigger;

      return;
    }

    _dismissed = false;
    _trigger = trigger;
    _highlighted = 0;

    _debounce?.cancel();
    _debounce = Timer(SLMentionField.debounce, () => _load(trigger.query));
  }

  /// Запрашивает подсказку.
  ///
  /// Провайдер-семейство держит ответ 30 секунд, поэтому возврат к уже
  /// набранному префиксу не стоит ещё одного запроса. Ответ, пришедший
  /// на устаревший запрос, отбрасывается по [_requestId]: подсказка обязана
  /// показывать то, что человек набрал сейчас, а не то, что он набирал
  /// две буквы назад.
  Future<void> _load(String query) async {
    if (!mounted) return;

    final id = ++_requestId;
    setState(() => _items = const AsyncLoading());
    _openOverlay();

    try {
      final items = await ref.read(
        issueMembersProvider(
          IssueMemberQuery(issueKey: widget.issueKey, query: query),
        ).future,
      );

      if (!mounted || id != _requestId) return;
      setState(() => _items = AsyncData(items));
    } on Object catch (error, stackTrace) {
      if (!mounted || id != _requestId) return;
      setState(() => _items = AsyncError(error, stackTrace));
    }

    _overlay?.markNeedsBuild();
  }

  void _close() {
    _debounce?.cancel();
    _trigger = null;
    _closeOverlay();
  }

  void _openOverlay() {
    if (_overlay != null) {
      _overlay!.markNeedsBuild();

      return;
    }

    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  List<MentionSuggestionDto> get _suggestions =>
      _trigger == null ? const [] : _items.value ?? const [];

  /// Вставляет токен вместо набранного `@запрос`.
  void _select(MentionSuggestionDto suggestion) {
    final trigger = _trigger;
    if (trigger == null) return;

    final text = widget.controller.text;
    final caret = widget.controller.selection.baseOffset;
    final token = MentionToken.format(
      id: suggestion.id,
      displayName: suggestion.displayName,
    );
    final replaced =
        '${text.substring(0, trigger.start)}$token '
        '${text.substring(caret)}';

    widget.controller.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(
        offset: trigger.start + token.length + 1,
      ),
    );

    _close();
    widget.onChanged?.call(replaced);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_overlay == null || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final items = _suggestions;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        // `@` остаётся символом — человек мог написать его намеренно.
        setState(() => _dismissed = true);
        _closeOverlay();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (items.isEmpty) return KeyEventResult.ignored;
        setState(() => _highlighted = (_highlighted + 1) % items.length);
        _overlay?.markNeedsBuild();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (items.isEmpty) return KeyEventResult.ignored;
        setState(
          () => _highlighted = (_highlighted - 1 + items.length) % items.length,
        );
        _overlay?.markNeedsBuild();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        if (items.isEmpty) return KeyEventResult.ignored;
        _select(items[_highlighted.clamp(0, items.length - 1)]);

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return CompositedTransformTarget(
      link: _link,
      child: Focus(
        onKeyEvent: _onKey,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style:
              widget.textStyle ?? text.body.copyWith(color: colors.textPrimary),
          cursorColor: colors.accent,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: text.body.copyWith(color: colors.textMuted),
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Positioned(
      width: SLMentionField.suggestionsWidth,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, SLSpacing.space1),
        child: Material(
          color: colors.surface,
          elevation: 0,
          borderRadius: SLRadii.mdAll,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: SLRadii.mdAll,
              border: Border.all(
                color: colors.border,
                width: SLBorders.hairline,
              ),
              boxShadow: SLShadows.md,
            ),
            padding: const EdgeInsets.symmetric(vertical: SLSpacing.space1),
            child: switch (_items) {
              AsyncData(:final value) => _SuggestionList(
                items: value,
                highlighted: _highlighted,
                onSelect: _select,
              ),
              AsyncError() => const _SuggestionMessage(
                text: 'Не удалось загрузить подсказку',
              ),
              _ => const _SuggestionSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.items,
    required this.highlighted,
    required this.onSelect,
  });

  final List<MentionSuggestionDto> items;
  final int highlighted;
  final ValueChanged<MentionSuggestionDto> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SuggestionMessage(
        text: 'Никого не нашли среди участников проекта',
      );
    }

    // Email показывается второй строкой только при совпадении имён (US-74):
    // иначе строка вырастает вдвое ради сведений, которые и так есть
    // на вкладке «Участники».
    final ambiguous = ambiguousNames(items);
    final rowHeight = ambiguous.isEmpty
        ? SLMentionField.suggestionHeight
        : SLMentionField.suggestionHeightWithEmail;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: SLMentionField.suggestionsMaxHeight,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemExtent: rowHeight,
        itemCount: items.length,
        itemBuilder: (context, index) => _SuggestionRow(
          item: items[index],
          selected: index == highlighted,
          showEmail: ambiguous.contains(items[index].displayName.toLowerCase()),
          onTap: () => onSelect(items[index]),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.item,
    required this.selected,
    required this.showEmail,
    required this.onTap,
  });

  final MentionSuggestionDto item;
  final bool selected;
  final bool showEmail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: selected ? colors.surfaceSelected : colors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
          child: Row(
            children: [
              SLAvatar(
                userId: item.id,
                fullName: item.displayName,
                photoUrl: item.avatarUrl,
                decorative: true,
              ),
              const SizedBox(width: SLSpacing.space2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyS.copyWith(color: colors.textPrimary),
                    ),
                    if (showEmail)
                      Text(
                        item.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.label.copyWith(color: colors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionMessage extends StatelessWidget {
  const _SuggestionMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final scheme = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SLSpacing.space3,
        vertical: SLSpacing.space2,
      ),
      child: Text(text, style: scheme.bodyS.copyWith(color: colors.textMuted)),
    );
  }
}

class _SuggestionSkeleton extends StatelessWidget {
  const _SuggestionSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: SLSpacing.space3,
      vertical: SLSpacing.space1,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonRow(),
        SizedBox(height: SLSpacing.space2),
        _SkeletonRow(),
        SizedBox(height: SLSpacing.space2),
        _SkeletonRow(),
      ],
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SLSkeletonBox.circle(diameter: 20),
      SizedBox(width: SLSpacing.space2),
      SLSkeletonLine(width: 120),
    ],
  );
}
