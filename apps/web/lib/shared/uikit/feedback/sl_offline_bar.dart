import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Полоса офлайна под шапкой (`docs/design/components.md`, 17.4).
///
/// Появляется, когда живая связь потеряна, и пропадает сама при
/// восстановлении. Данные при этом остаются на экране: то, что уже
/// загружено, никуда не девается, — полоса лишь предупреждает, что новое
/// не приедет.
///
/// Занимает место в раскладке только когда видна: иначе она отъедала бы
/// 28 px у содержимого всё время.
class SLOfflineBar extends StatelessWidget {
  /// @nodoc
  const SLOfflineBar({required this.visible, super.key});

  /// Показывать ли полосу.
  final bool visible;

  /// Высота полосы.
  static const height = 28.0;

  /// Текст. Вынесен константой: его же произносит скринридер.
  static const message = 'Нет соединения. Изменения не сохраняются';

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return AnimatedSize(
      duration: SLMotion.durationOf(context, SLMotion.base),
      curve: SLMotion.baseInCurve,
      alignment: Alignment.topCenter,
      child: visible
          ? Semantics(
              liveRegion: true,
              label: message,
              child: ExcludeSemantics(
                child: Container(
                  width: double.infinity,
                  height: height,
                  alignment: Alignment.center,
                  color: colors.warningSurface,
                  child: Text(
                    message,
                    style: text.label.copyWith(color: colors.warning),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
