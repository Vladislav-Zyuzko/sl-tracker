import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Бейдж владельца трекера.
///
/// Владелец — **единственная глобальная роль** (`permissions.md`, 1.2): она
/// даёт право вести список доступа и не даёт никаких прав внутри проектов.
/// Поэтому бейдж контурный и неяркий: это признак, а не звание.
///
/// Живёт в дизайн-системе, а не внутри экрана, потому что мест у него два —
/// строка списка доступа и блок «кто я» в профиле, — и расходиться им нельзя.
class SLOwnerBadge extends StatelessWidget {
  /// @nodoc
  const SLOwnerBadge({this.label = 'Владелец', super.key});

  /// Подпись. В списке доступа — «Владелец», в профиле — «Владелец трекера»:
  /// там рядом нет колонки, которая объясняла бы, чего именно владелец.
  final String label;

  /// Высота бейджа: та же строка, что и у бейджа источника в списке доступа,
  /// — эти два признака стоят рядом и обязаны выравниваться.
  static const height = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
      decoration: BoxDecoration(
        borderRadius: SLRadii.smAll,
        border: Border.all(color: colors.border, width: SLBorders.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.key_rounded,
            size: SLIconSizes.icon12,
            color: colors.iconMuted,
          ),
          const SizedBox(width: SLSpacing.space1),
          Text(
            label,
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
