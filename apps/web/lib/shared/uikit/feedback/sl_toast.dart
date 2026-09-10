import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/sl_shadows.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Тип тоста (`docs/design/components.md`, 14).
enum SLToastVariant {
  /// Действие получилось. Закрывается сам через 4 с.
  success,

  /// Нейтральное сообщение. Закрывается сам через 4 с.
  info,

  /// Предупреждение. Закрывается сам через 6 с.
  warning,

  /// Ошибка. **Сама не закрывается**: результат, о котором надо узнать.
  danger;

  /// Через сколько тост исчезает сам. `null` — не исчезает.
  Duration? get autoDismissAfter => switch (this) {
    SLToastVariant.success || SLToastVariant.info => const Duration(seconds: 4),
    SLToastVariant.warning => const Duration(seconds: 6),
    SLToastVariant.danger => null,
  };
}

/// Одно сообщение в стеке тостов.
@immutable
class SLToast {
  /// @nodoc
  const SLToast({
    required this.id,
    required this.message,
    required this.variant,
    this.actionLabel,
    this.onAction,
    this.count = 1,
    this.dismissing = false,
  });

  /// @nodoc
  final int id;

  /// Текст, прямо называющий результат: «Адрес добавлен», а не «Готово».
  final String message;

  /// @nodoc
  final SLToastVariant variant;

  /// Подпись действия. Действие обязано быть доступно и где-то ещё:
  /// пользователь на клавиатуре может не успеть до него дойти.
  final String? actionLabel;

  /// @nodoc
  final VoidCallback? onAction;

  /// Сколько раз подряд пришло одно и то же сообщение.
  final int count;

  /// Тост уже уезжает: 120 мс на исчезновение, потом удаление из списка.
  final bool dismissing;

  /// @nodoc
  SLToast copyWith({int? count, bool? dismissing}) => SLToast(
    id: id,
    message: message,
    variant: variant,
    actionLabel: actionLabel,
    onAction: onAction,
    count: count ?? this.count,
    dismissing: dismissing ?? this.dismissing,
  );
}

/// Очередь тостов приложения.
final toastControllerProvider =
    NotifierProvider<SLToastController, List<SLToast>>(SLToastController.new);

/// Контроллер очереди тостов.
///
/// `SnackBar` не подходит: он прибит к низу, показывает по одному и не умеет
/// стек (`components.md`, 14).
class SLToastController extends Notifier<List<SLToast>> {
  var _nextId = 0;

  /// Сколько тостов видно одновременно. Четвёртый вытесняет самый старый.
  static const maxVisible = 3;

  /// Время исчезновения.
  static const dismissDuration = SLMotion.fast;

  @override
  List<SLToast> build() => const [];

  /// Показывает тост. Одинаковые подряд не дублируются — у существующего
  /// растёт счётчик.
  void show(
    String message, {
    SLToastVariant variant = SLToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final sameIndex = state.indexWhere(
      (toast) =>
          !toast.dismissing &&
          toast.message == message &&
          toast.variant == variant,
    );

    if (sameIndex >= 0) {
      final existing = state[sameIndex];
      state = [...state]
        ..[sameIndex] = existing.copyWith(count: existing.count + 1);

      return;
    }

    final toast = SLToast(
      id: _nextId++,
      message: message,
      variant: variant,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    final next = [...state, toast];
    state = next.length > maxVisible
        ? next.sublist(next.length - maxVisible)
        : next;
  }

  /// Успех.
  void success(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        message,
        variant: SLToastVariant.success,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Ошибка. Сама не закрывается — обычно с действием «Повторить».
  void error(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        message,
        variant: SLToastVariant.danger,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Убирает тост: сначала уезжает, потом исчезает из списка.
  void dismiss(int id) {
    final index = state.indexWhere((toast) => toast.id == id);
    if (index < 0 || state[index].dismissing) return;

    state = [...state]..[index] = state[index].copyWith(dismissing: true);

    Timer(dismissDuration, () {
      state = state.where((toast) => toast.id != id).toList();
    });
  }
}

/// Слой тостов над приложением.
///
/// Ставится один раз в корне: тосты переживают переходы между экранами.
///
/// Внутри — собственный [Overlay], и это не украшательство. Хост живёт
/// в `builder` у `MaterialApp.router`, то есть **над** навигатором, а значит
/// над его оверлеем. Всё, что требует оверлея (тултип у кнопки закрытия,
/// меню), без своего слоя падает с «No Overlay widget found» — ровно так
/// это и выяснилось: виджет-тест поднял приложение так же, как оно собрано
/// на самом деле.
///
/// Оверлей есть всегда, а не только когда есть тосты: его единственная
/// запись подписана на очередь сама и перестраивается без пересоздания слоя.
/// Пустые места слоя события мыши не ловят — `Stack` внутри записи
/// проверяет попадание только по своим детям.
class SLToastHost extends StatelessWidget {
  /// @nodoc
  const SLToastHost({required this.child, super.key});

  /// Приложение под слоем тостов.
  final Widget? child;

  /// Ширина тоста на десктопе.
  static const toastWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        Positioned.fill(
          child: Overlay(
            initialEntries: [
              OverlayEntry(builder: (context) => const _SLToastLayer()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Стек видимых тостов.
class _SLToastLayer extends ConsumerWidget {
  const _SLToastLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastControllerProvider);
    if (toasts.isEmpty) return const SizedBox.shrink();

    final density = SLDensity.ofContext(context);
    final isPhone = SLBreakpoint.of(context).isPhone;

    return Stack(
      children: [
        Positioned(
          // Под шапкой приложения и в стороне от края.
          top: density.appBarHeight + SLSpacing.space4,
          right: SLSpacing.space4,
          left: isPhone ? SLSpacing.space4 : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final toast in toasts)
                Padding(
                  padding: const EdgeInsets.only(bottom: SLSpacing.space2),
                  child: SizedBox(
                    width: isPhone ? null : SLToastHost.toastWidth,
                    child: _SLToastCard(toast: toast),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Карточка одного тоста.
class _SLToastCard extends ConsumerStatefulWidget {
  const _SLToastCard({required this.toast});

  final SLToast toast;

  @override
  ConsumerState<_SLToastCard> createState() => _SLToastCardState();
}

class _SLToastCardState extends ConsumerState<_SLToastCard> {
  Timer? _autoDismissTimer;
  var _visible = false;
  var _held = false;

  @override
  void initState() {
    super.initState();
    // Первый кадр — со смещением и прозрачный, дальше уезжает на место.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _restartAutoDismiss();
  }

  @override
  void didUpdateWidget(_SLToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Повторное такое же сообщение продлевает жизнь тоста.
    if (widget.toast.count != oldWidget.toast.count) _restartAutoDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  /// Таймер останавливается, пока указатель или фокус внутри тоста:
  /// человек читает — значит, ещё не дочитал.
  void _restartAutoDismiss() {
    _autoDismissTimer?.cancel();

    final delay = widget.toast.variant.autoDismissAfter;
    if (delay == null || _held) return;

    _autoDismissTimer = Timer(delay, _dismiss);
  }

  void _hold({required bool held}) {
    if (_held == held) return;
    _held = held;

    if (held) {
      _autoDismissTimer?.cancel();
    } else {
      _restartAutoDismiss();
    }
  }

  void _dismiss() =>
      ref.read(toastControllerProvider.notifier).dismiss(widget.toast.id);

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final toast = widget.toast;

    final (accent, icon) = switch (toast.variant) {
      SLToastVariant.success => (colors.success, Icons.check_circle_rounded),
      SLToastVariant.info => (colors.info, Icons.info_outline_rounded),
      SLToastVariant.warning => (
        colors.warningAccent,
        Icons.warning_amber_rounded,
      ),
      SLToastVariant.danger => (colors.danger, Icons.error_outline_rounded),
    };

    final shown = _visible && !toast.dismissing;
    final message = toast.count > 1
        ? '${toast.message} × ${toast.count}'
        : toast.message;

    return Semantics(
      // Настойчивость объявления (`assertive` против `polite`) Flutter
      // наружу не отдаёт: у `Semantics` есть только `liveRegion`. Разделение
      // из спеки (`components.md`, 14) отложено до появления такой
      // возможности — см. отчёт.
      liveRegion: true,
      child: MouseRegion(
        onEnter: (_) => _hold(held: true),
        onExit: (_) => _hold(held: false),
        child: FocusScope(
          onFocusChange: (focused) => _hold(held: focused),
          child: AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0.05, 0),
            duration: SLMotion.durationOf(
              context,
              toast.dismissing ? SLMotion.fast : SLMotion.base,
            ),
            curve: SLMotion.baseInCurve,
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: SLMotion.durationOf(
                context,
                toast.dismissing ? SLMotion.fast : SLMotion.base,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: SLRadii.mdAll,
                  border: Border.all(
                    color: colors.border,
                    width: SLBorders.hairline,
                  ),
                  boxShadow: SLShadows.of(context).md,
                ),
                // Высота тоста задаётся содержимым, а полоса слева тянется
                // на всю его высоту — без `IntrinsicHeight` растягивать
                // нечему.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(SLRadii.md),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(SLSpacing.space3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                icon,
                                size: SLIconSizes.icon16,
                                color: accent,
                              ),
                              const SizedBox(width: SLSpacing.space2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message,
                                      style: text.bodyS.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (toast.actionLabel != null)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: SLButton(
                                          label: toast.actionLabel!,
                                          variant: SLButtonVariant.ghost,
                                          size: SLButtonSize.sm,
                                          onPressed: () {
                                            _dismiss();
                                            toast.onAction?.call();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: SLSpacing.space2),
                              SLIconButton(
                                icon: Icons.close_rounded,
                                tooltip: 'Закрыть сообщение',
                                size: SLButtonSize.sm,
                                onPressed: _dismiss,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
