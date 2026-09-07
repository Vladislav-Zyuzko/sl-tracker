import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Прямоугольник скелетона (`docs/design/components.md`, 15).
///
/// Скелетон повторяет геометрию реального контента: те же высоты строк,
/// те же ширины колонок. Иначе при загрузке экран прыгает.
///
/// Сам по себе статичен. Волну по группе блоков гонит `SLShimmeringEffect`,
/// которым эту группу оборачивают.
class SLSkeletonBox extends StatelessWidget {
  /// @nodoc
  const SLSkeletonBox({
    this.width,
    this.height,
    this.borderRadius = SLRadii.smAll,
    super.key,
  });

  /// Круг заданного диаметра — аватар-скелетон.
  const SLSkeletonBox.circle({required double diameter, super.key})
    : width = diameter,
      height = diameter,
      borderRadius = SLRadii.fullAll;

  /// @nodoc
  final double? width;

  /// @nodoc
  final double? height;

  /// @nodoc
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SLColorScheme.of(context).skeletonBase,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Полоска-скелетон на месте строки текста.
class SLSkeletonLine extends StatelessWidget {
  /// @nodoc
  const SLSkeletonLine({this.width, this.height = 12, super.key});

  /// Ширина. `null` — занять всё доступное место.
  final double? width;

  /// Высота полоски. По умолчанию 12 — высота полоски метаданных.
  final double height;

  @override
  Widget build(BuildContext context) =>
      SLSkeletonBox(width: width, height: height);
}

/// Показывает скелетон по правилам тайминга из спеки (`components.md`, 15).
///
/// Скелетон появляется **не раньше 200 мс** после начала загрузки: если данные
/// пришли быстрее, пользователь не увидит вспышку. И держится минимум 400 мс,
/// если уже показан, чтобы не мигнуть.
///
/// Правило вынесено в отдельный виджет, потому что иначе его пришлось бы
/// повторять на каждом экране — и рано или поздно где-то забыть.
class SLLoadingGate extends StatefulWidget {
  /// @nodoc
  const SLLoadingGate({
    required this.isLoading,
    required this.skeleton,
    required this.child,
    super.key,
  });

  /// Идёт ли загрузка.
  final bool isLoading;

  /// Что показать вместо контента.
  final Widget skeleton;

  /// Готовый контент.
  final Widget child;

  /// Задержка до появления скелетона.
  static const appearDelay = Duration(milliseconds: 200);

  /// Минимальное время показа уже появившегося скелетона.
  static const minVisibleDuration = Duration(milliseconds: 400);

  @override
  State<SLLoadingGate> createState() => _SLLoadingGateState();
}

class _SLLoadingGateState extends State<SLLoadingGate> {
  var _showSkeleton = false;
  Timer? _appearTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _scheduleAppear();
  }

  @override
  void didUpdateWidget(SLLoadingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;

    if (widget.isLoading) {
      _hideTimer?.cancel();
      _scheduleAppear();
    } else {
      _appearTimer?.cancel();
      if (_showSkeleton) {
        _hideTimer = Timer(
          SLLoadingGate.minVisibleDuration,
          () => setState(() => _showSkeleton = false),
        );
      }
    }
  }

  @override
  void dispose() {
    _appearTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleAppear() {
    _appearTimer = Timer(
      SLLoadingGate.appearDelay,
      () => setState(() => _showSkeleton = true),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _showSkeleton ? widget.skeleton : widget.child;
}
