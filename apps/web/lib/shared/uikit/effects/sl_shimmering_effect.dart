import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';

/// Шиммер скелетона (`docs/design/components.md`, 15).
///
/// Оборачивает **группу** скелетон-блоков и гонит по ним одну волну.
/// Один контроллер на группу, а не на блок: в списке из 12 строк по 6 колонок
/// это разница между одним тикером и семьюдесятью двумя.
///
/// Градиент `skeletonBase → skeletonHighlight → skeletonBase`, проход
/// 1400 мс, бесконечно, [Curves.linear]. При включённой системной настройке
/// «уменьшить движение» шиммера нет — остаётся статичная заливка
/// `skeletonBase`, и это тоже рабочее состояние, а не пустота.
class SLShimmeringEffect extends StatefulWidget {
  /// @nodoc
  const SLShimmeringEffect({required this.child, super.key});

  /// Группа скелетон-блоков.
  final Widget child;

  @override
  State<SLShimmeringEffect> createState() => _SLShimmeringEffectState();
}

class _SLShimmeringEffectState extends State<SLShimmeringEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Контроллер без границ: значения вне [0, 1] уводят волну за края,
    // поэтому на стыке цикла нет скачка.
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: SLMotion.shimmer);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final colors = SLColorScheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final gradient = LinearGradient(
          colors: [
            colors.skeletonBase,
            colors.skeletonHighlight,
            colors.skeletonBase,
          ],
          stops: const [0.35, 0.5, 0.65],
          // Угол около 100°: волна идёт слева направо с лёгким наклоном.
          begin: const Alignment(-1, -0.35),
          end: const Alignment(1, 0.35),
          transform: _SlidingGradientTransform(slide: _controller.value),
        );

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: gradient.createShader,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Сдвигает градиент по горизонтали на долю ширины области.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slide});

  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}
