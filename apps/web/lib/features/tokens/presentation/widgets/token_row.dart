import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_record_state_badge.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка токена доступа (`docs/design/screens/tokens.md`).
///
/// Высота задана числом, а не собирается из отступов: это `itemExtent`
/// виртуализированного списка, и при её «сборке» виртуализация сломается.
///
/// **Строка ничего не открывает**: у токена нет своей страницы, показывать
/// в ней нечего сверх того, что уже видно. Отсюда поведение `Enter` — он
/// переводит фокус на «Отозвать», чтобы нажатие не выглядело поломкой.
class TokenRow extends StatefulWidget {
  /// @nodoc
  const TokenRow({
    required this.token,
    required this.onRevoke,
    this.highlighted = false,
    this.compact = false,
    this.dense = false,
    this.now,
    super.key,
  });

  /// Токен.
  final TokenDto token;

  /// Открыть подтверждение отзыва. `null` — токен уже отозван.
  final VoidCallback? onRevoke;

  /// Строка только что отозвана: подсвечена 1200 мс.
  final bool highlighted;

  /// Телефонная раскладка: карточка вместо строки таблицы.
  final bool compact;

  /// Планшет (`md`): колонка «Создан» скрыта.
  final bool dense;

  /// Момент, относительно которого считаются формулировки. `null` — сейчас.
  /// Задаётся снаружи, чтобы весь список пересчитывался одним таймером
  /// и строки не расходились между собой.
  final DateTime? now;

  /// Высота строки на десктопе и планшете.
  static const height = 44.0;

  /// Высота карточки на телефоне.
  static const compactHeight = 100.0;

  /// Ширина колонки префикса.
  static const prefixColumnWidth = 104.0;

  /// Ширина колонки «Создан».
  static const createdColumnWidth = 88.0;

  /// Ширина колонки «Использован».
  static const lastSeenColumnWidth = 112.0;

  /// Ширина колонки «Истекает».
  static const expiresColumnWidth = 148.0;

  /// Ширина колонки действия.
  static const actionColumnWidth = 104.0;

  /// Минимальная ширина колонки имени.
  static const nameColumnMinWidth = 200.0;

  /// Место под действие в правом верхнем углу карточки на `sm`.
  static const compactActionWidth = 96.0;

  @override
  State<TokenRow> createState() => _TokenRowState();
}

class _TokenRowState extends State<TokenRow> {
  final _revokeFocusNode = FocusNode(debugLabel: 'token-revoke');
  var _hovered = false;
  var _focused = false;

  @override
  void dispose() {
    _revokeFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        node.focusInDirection(TraversalDirection.down);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        node.focusInDirection(TraversalDirection.up);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        // Открывать нечего: переводим фокус на единственное действие строки.
        _revokeFocusNode.requestFocus();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
        // Подтверждение, а не отзыв: у опасных действий нет хоткея прямого
        // действия.
        widget.onRevoke?.call();

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final state = TokenPresentation.stateOf(widget.token, now: widget.now);

    final background = switch (widget.highlighted) {
      true => colors.accentSurface,
      false when _hovered => colors.surfaceHover,
      false => colors.surface,
    };

    return Semantics(
      label: TokenPresentation.rowSemanticsLabel(widget.token, now: widget.now),
      // Кнопка отзыва объявляется отдельно: у неё своё имя с последствием.
      explicitChildNodes: true,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: SLFocusRing(
            focused: _focused,
            inset: true,
            child: AnimatedContainer(
              duration: SLMotion.durationOf(context, SLMotion.base),
              height: widget.compact ? TokenRow.compactHeight : TokenRow.height,
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  bottom: BorderSide(
                    color: colors.borderSubtle,
                    width: SLBorders.hairline,
                  ),
                ),
              ),
              // На карточке отступы разные сверху и снизу: высота 100
              // складывается из 12 + (18 + 4 + 18 + 4 + 18 + 4 + 16) + 5
              // и разделителя в 1 px, и обязана сойтись точно —
              // это `itemExtent` виртуализированного списка.
              padding: widget.compact
                  ? const EdgeInsets.fromLTRB(
                      SLSpacing.space4,
                      SLSpacing.space3,
                      SLSpacing.space4,
                      5,
                    )
                  : const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
              child: widget.compact ? _buildCard(state) : _buildRow(state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(SLRecordState state) {
    final muted = state != SLRecordState.active;

    return Row(
      children: [
        Expanded(
          child: _NameCell(
            token: widget.token,
            muted: muted,
            // На `md` дата создания уходит из таблицы в тултип имени.
            createdInTooltip: widget.dense,
          ),
        ),
        const SizedBox(width: SLSpacing.space3),
        SizedBox(
          width: TokenRow.prefixColumnWidth,
          child: _PrefixCell(prefix: widget.token.prefix, muted: muted),
        ),
        if (!widget.dense)
          SizedBox(
            width: TokenRow.createdColumnWidth,
            child: _CreatedCell(createdAt: widget.token.createdAt),
          ),
        SizedBox(
          width: TokenRow.lastSeenColumnWidth,
          child: _LastSeenCell(token: widget.token, now: widget.now),
        ),
        SizedBox(
          width: TokenRow.expiresColumnWidth,
          child: _ExpiresCell(token: widget.token, now: widget.now),
        ),
        SizedBox(
          width: TokenRow.actionColumnWidth,
          child: Align(alignment: Alignment.centerRight, child: _buildAction()),
        ),
      ],
    );
  }

  /// Карточка на `sm`: от главного к второстепенному — имя (какой),
  /// префикс (тот ли), срок (живой ли), использование и создание
  /// (нужен ли вообще).
  ///
  /// Действие лежит слоем поверх, а не в первой строке: кнопка на телефоне
  /// высотой 32, и строка под неё растянула бы карточку за пределы
  /// фиксированной высоты 100.
  Widget _buildCard(SLRecordState state) {
    final muted = state != SLRecordState.active;
    final token = widget.token;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                right: TokenRow.compactActionWidth,
              ),
              child: _NameCell(
                token: token,
                muted: muted,
                createdInTooltip: true,
              ),
            ),
            const SizedBox(height: SLSpacing.space1),
            _PrefixCell(prefix: token.prefix, muted: muted),
            const SizedBox(height: SLSpacing.space1),
            _ExpiresCell(token: token, now: widget.now, withPrefixWord: true),
            const SizedBox(height: SLSpacing.space1),
            _CardMetaLine(token: token, now: widget.now),
          ],
        ),
        Positioned(top: 0, right: 0, child: _buildAction()),
      ],
    );
  }

  Widget _buildAction() {
    final revokedAt = widget.token.revokedAt;

    // У отозванного токена кнопки нет вовсе — вместо неё плашка.
    // Не «серая кнопка», а её отсутствие.
    if (revokedAt != null) {
      return SLRecordStateBadge(
        label: 'Отозван',
        state: SLRecordState.revoked,
        tooltip: TokenPresentation.revokedTooltip(revokedAt),
      );
    }

    return Semantics(
      container: true,
      button: true,
      label: TokenPresentation.revokeSemanticsLabel(widget.token),
      excludeSemantics: true,
      child: SLButton(
        label: 'Отозвать',
        variant: SLButtonVariant.dangerGhost,
        size: SLButtonSize.sm,
        focusNode: _revokeFocusNode,
        onPressed: widget.onRevoke,
      ),
    );
  }
}

/// Имя токена. Полное — в тултипе: 64 символа в колонку не помещаются.
class _NameCell extends StatelessWidget {
  const _NameCell({
    required this.token,
    required this.muted,
    required this.createdInTooltip,
  });

  final TokenDto token;
  final bool muted;
  final bool createdInTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Tooltip(
      message: createdInTooltip
          ? '${token.name}\nСоздан ${SLDateFormat.exact(token.createdAt)}'
          : token.name,
      child: Text(
        token.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // Приглушение — ступенью текстовой роли, а не прозрачностью:
        // 60 % альфы на `textPrimary` дают 3.57:1 и провал AA.
        style: text.bodyS.copyWith(
          color: muted ? colors.textSecondary : colors.textPrimary,
        ),
      ),
    );
  }
}

/// Префикс: первые 8 символов токена и многоточие.
///
/// Моноширинный и выделяемый: его сверяют посимвольно со строкой в конфиге
/// агента, а пропорциональный шрифт склеивает `l`, `1` и `I`. Кнопки
/// копирования у префикса нет — он никуда не вставляется.
class _PrefixCell extends StatelessWidget {
  const _PrefixCell({required this.prefix, required this.muted});

  final String prefix;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(
        TokenPresentation.prefixLabel(prefix),
        maxLines: 1,
        style: text.mono.copyWith(
          color: muted ? colors.textMuted : colors.textSecondary,
        ),
      ),
    );
  }
}

/// Дата создания. Полная дата и время — в тултипе.
class _CreatedCell extends StatelessWidget {
  const _CreatedCell({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Tooltip(
      message: SLDateFormat.exact(createdAt),
      child: Text(
        SLDateFormat.short(createdAt),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyS.copyWith(color: colors.textMuted),
      ),
    );
  }
}

/// «Использован»: значение означает «не раньше чем», и тултип говорит это
/// прямо. Слова «последний раз» здесь быть не может.
class _LastSeenCell extends StatelessWidget {
  const _LastSeenCell({required this.token, required this.now});

  final TokenDto token;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final never = TokenPresentation.neverUsed(token);

    return Tooltip(
      message: TokenPresentation.lastSeenTooltip(token, now: now),
      child: Text(
        TokenPresentation.lastSeenLabel(token, now: now),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyS.copyWith(
          // `textDisabled` — только для значений, которые не несут действия:
          // «ни разу» и «пока неизвестно».
          color: never ? colors.textDisabled : colors.textMuted,
        ),
      ),
    );
  }
}

/// «Истекает»: срок словом, предупреждение — иконкой и текстом, а не только
/// цветом.
class _ExpiresCell extends StatelessWidget {
  const _ExpiresCell({
    required this.token,
    required this.now,
    this.withPrefixWord = false,
  });

  final TokenDto token;
  final DateTime? now;

  /// На карточке `sm` значение стоит само по себе, без заголовка колонки,
  /// поэтому получает слово «Истекает».
  final bool withPrefixWord;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final revokedAt = token.revokedAt;
    final soon = TokenPresentation.expiresSoon(token, now: now);
    final label = TokenPresentation.expiresLabel(token, now: now);

    final color = switch (TokenPresentation.stateOf(token, now: now)) {
      // У отозванного в колонке прочерк: значение, которое не несёт действия.
      SLRecordState.revoked => colors.textDisabled,
      SLRecordState.expired => colors.textMuted,
      SLRecordState.active when soon => colors.warning,
      SLRecordState.active => colors.textSecondary,
    };

    final value = Text(
      withPrefixWord && revokedAt == null ? 'Истекает $label' : label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodyS.copyWith(color: color),
    );

    return Tooltip(
      message: revokedAt == null
          ? TokenPresentation.expiresTooltip(token, now: now)
          : TokenPresentation.revokedTooltip(revokedAt),
      child: Row(
        children: [
          if (soon) ...[
            Icon(
              Icons.warning_amber_rounded,
              size: SLIconSizes.icon12,
              color: colors.warning,
            ),
            const SizedBox(width: SLSpacing.space1),
          ],
          Flexible(child: value),
        ],
      ),
    );
  }
}

/// Нижняя строка карточки на `sm`: использование и создание одной строкой.
class _CardMetaLine extends StatelessWidget {
  const _CardMetaLine({required this.token, required this.now});

  final TokenDto token;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final lastSeen = TokenPresentation.lastSeenLabel(token, now: now);

    return Tooltip(
      message: TokenPresentation.lastSeenTooltip(token, now: now),
      child: Text(
        'Использован $lastSeen · создан ${SLDateFormat.short(token.createdAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.label.copyWith(color: colors.textMuted),
      ),
    );
  }
}
